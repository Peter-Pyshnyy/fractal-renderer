extends Node

@export var texture_rect: TextureRect
@export var target_camera: Camera3D
@export var render_resolution = Vector2(1920, 1080)

var rd: RenderingDevice
var shader_rid: RID
var pipeline_rid: RID
var texture_rid: RID
var camera_buffer_rid: RID
var uniform_set_rid: RID
var tex_rd_resource: Texture2DRD

func _ready() -> void:
	if not target_camera:
		push_error("Не призначено вузол Camera3D!")
		return

	# ВАЖЛИВО: Для використання Texture2DRD ми повинні взяти головний пристрій рендерингу,
	# а не створювати локальний.
	# use global rendering device
	rd = RenderingServer.get_rendering_device()

	# 1. Завантаження шейдера
	var shader_file := load("res://shaders/fragment/mandelbulb.glsl") as RDShaderFile
	shader_rid = rd.shader_create_from_spirv(shader_file.get_spirv())

	# 2. Створення текстури для рендерингу
	var fmt := RDTextureFormat.new()
	fmt.width = int(render_resolution.x)
	fmt.height = int(render_resolution.y)
	fmt.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	# TEXTURE_USAGE_SAMPLING_BIT є критичним для можливості відображення через Texture2DRD
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
	
	var view := RDTextureView.new()
	texture_rid = rd.texture_create(fmt, view,)

	# Підключення текстури напряму до вузла TextureRect
	tex_rd_resource = Texture2DRD.new()
	tex_rd_resource.texture_rd_rid = texture_rid
	texture_rect.texture = tex_rd_resource

	# 3. Ініціалізація Storage Buffer для даних камери (заповнення нулями)
	var initial_cam_data := PackedFloat32Array()
	initial_cam_data.resize(20) # 5 векторів vec4 = 20 float (80 байт)
	initial_cam_data.fill(0.0)
	var bytes := initial_cam_data.to_byte_array()
	camera_buffer_rid = rd.storage_buffer_create(bytes.size(), bytes)

	# 4. Формування дескрипторного набору (Uniform Set)
	var img_uniform := RDUniform.new()
	img_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	img_uniform.binding = 0
	img_uniform.add_id(texture_rid)

	var cam_uniform := RDUniform.new()
	cam_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	cam_uniform.binding = 1
	cam_uniform.add_id(camera_buffer_rid)

	uniform_set_rid = rd.uniform_set_create([img_uniform, cam_uniform], shader_rid, 0)
	pipeline_rid = rd.compute_pipeline_create(shader_rid)

# Функція _process викликається кожен кадр (60+ разів на секунду)
func _physics_process(_delta: float) -> void:
	# Етап 1: Оновлення даних камери та пакування їх у байтовий масив
	var cam_transform = target_camera.global_transform
	var fov = target_camera.fov
	# Формула розрахунку масштабу для поля зору (FOV)
	var fov_scale = tan(deg_to_rad(fov * 0.5)) 
	
	var cam_data := PackedFloat32Array()
	
	# vec4 cameraPos (додаємо 0.0 для w-компоненти, забезпечуючи вирівнювання std430)
	cam_data.push_back(cam_transform.origin.x)
	cam_data.push_back(cam_transform.origin.y)
	cam_data.push_back(cam_transform.origin.z)
	cam_data.push_back(0.0) 
	
	# vec4 forward (В Godot камера дивиться вздовж негативної осі Z)
	var forward = -cam_transform.basis.z
	cam_data.push_back(forward.x)
	cam_data.push_back(forward.y)
	cam_data.push_back(forward.z)
	cam_data.push_back(0.0)
	
	# vec4 right (Позитивна вісь X)
	var right = cam_transform.basis.x
	cam_data.push_back(right.x)
	cam_data.push_back(right.y)
	cam_data.push_back(right.z)
	cam_data.push_back(0.0)
	
	# vec4 up (Позитивна вісь Y)
	var up = cam_transform.basis.y
	cam_data.push_back(up.x)
	cam_data.push_back(up.y)
	cam_data.push_back(up.z)
	cam_data.push_back(0.0)
	
	# Останні параметри: vec2 resolution, float fovScale, float padding
	cam_data.push_back(render_resolution.x)
	cam_data.push_back(render_resolution.y)
	cam_data.push_back(fov_scale)
	cam_data.push_back(0.0) # Padding для завершення останнього vec4
	
	# Конвертуємо у масив байтів та оновлюємо існуючий буфер на GPU
	var bytes := cam_data.to_byte_array()
	rd.buffer_update(camera_buffer_rid, 0, bytes.size(), bytes)

	# Етап 2: Розрахунок Dispatch та запуск конвеєра
	var x_groups = ceil(render_resolution.x / 16.0)
	var y_groups = ceil(render_resolution.y / 16.0)

	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline_rid)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set_rid, 0)
	rd.compute_list_dispatch(compute_list, x_groups, y_groups, 1)
	rd.compute_list_end()

	# Оскільки ми використовуємо головний RenderingDevice, ми НЕ викликаємо rd.sync()
	# Це дозволяє CPU одразу перейти до обробки наступного кадру (логіки гри, фізики),
	# поки GPU паралельно відмальовує Ray Marching сцену у фоновому режимі.
