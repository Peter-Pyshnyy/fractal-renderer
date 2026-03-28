extends Node

@export var texture_rect: TextureRect
@export var target_camera: Camera3D
@export var render_resolution := Vector2(1920, 1080)

@export_category("Fractal Settings")
@export_range(1.0, 20.0, 0.1) var fractal_power: float = 8.0
@export_range(1, 100, 1) var fractal_iterations: int = 15
@export_range(1.0, 5.0, 0.1) var fractal_bailout: float = 2.0

@export_category("Raymarching Tuning")
@export_range(0.1, 1.0, 0.05) var step_scale: float = 0.4
@export_range(1.0, 2.0, 0.05) var omega_max: float = 1.5
@export_range(0.0, 0.95, 0.05) var omega_beta: float = 0.3

var rd: RenderingDevice
var shader_rid: RID
var pipeline_rid: RID
var camera_buffer_rid: RID

var texture_rids: Array[RID]
var tex_rd_resources: Array[Texture2DRD]
var uniform_sets: Array[RID]
var frame_index := 0

var macro_shader_rid: RID
var macro_pipeline_rid: RID
var macro_uniform_set: RID

var macro_scale: float = 4.0 # Зменшуємо роздільну здатність макро-проходу в 4 рази
var macro_texture_rid: RID
var sampler_rid: RID # Семплер для читання текстури


# reuse buffer (avoid per-frame allocations)
var cam_data := PackedFloat32Array()

func _ready() -> void: 
	if not target_camera: 
		push_error("Camera3D not assigned") 
		return 
		
	rd = RenderingServer.get_rendering_device() 
	_create_shader() 
	_create_texture() 
	_create_camera_buffer() 
	_create_pipeline()


# --- Setup ---

func _create_shader() -> void:
	var shader_file := load("res://shaders/fragment/mandelbulb.glsl") as RDShaderFile
	shader_rid = rd.shader_create_from_spirv(shader_file.get_spirv())
	
	# Завантажуємо макро шейдер (вкажіть ваш правильний шлях)
	var macro_file := load("res://shaders/includes/macro_pass.glsl") as RDShaderFile
	macro_shader_rid = rd.shader_create_from_spirv(macro_file.get_spirv())


func _create_texture() -> void:
	var fmt := RDTextureFormat.new()
	fmt.width = int(render_resolution.x)
	fmt.height = int(render_resolution.y)
	fmt.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT

	for i in 2:
		var tex_rid = rd.texture_create(fmt, RDTextureView.new())
		texture_rids.append(tex_rid)

		var tex_res := Texture2DRD.new()
		tex_res.texture_rd_rid = tex_rid
		tex_rd_resources.append(tex_res)

	# initialize display
	texture_rect.texture = tex_rd_resources[0]
	
	# --- СТВОРЕННЯ МАКРО-БУФЕРА ---
	var m_fmt := RDTextureFormat.new()
	m_fmt.width = int(ceil(render_resolution.x / macro_scale))
	m_fmt.height = int(ceil(render_resolution.y / macro_scale))
	m_fmt.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
	m_fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
	macro_texture_rid = rd.texture_create(m_fmt, RDTextureView.new(), [])

	# --- СТВОРЕННЯ СЕМПЛЕРА (Щоб фінальний шейдер міг читати макро-буфер) ---
	var sampler_state := RDSamplerState.new()
	# Використовуємо NEAREST, щоб не "розмивати" глибину між пікселями
	sampler_state.mag_filter = RenderingDevice.SAMPLER_FILTER_NEAREST 
	sampler_state.min_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
	sampler_rid = rd.sampler_create(sampler_state)

func _create_camera_buffer() -> void:
	# 5 vec4 = 20 floats
	cam_data.resize(20)
	cam_data.fill(0.0)

	var bytes := cam_data.to_byte_array()
	camera_buffer_rid = rd.storage_buffer_create(bytes.size(), bytes)


func _create_pipeline() -> void:
	var cam_uniform := RDUniform.new()
	cam_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	cam_uniform.binding = 1
	cam_uniform.add_id(camera_buffer_rid)

	# --- 1. ПАЙПЛАЙН ДЛЯ МАКРО ПРОХОДУ ---
	var mac_img_uniform := RDUniform.new()
	mac_img_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	mac_img_uniform.binding = 0
	mac_img_uniform.add_id(macro_texture_rid)

	macro_uniform_set = rd.uniform_set_create([mac_img_uniform, cam_uniform], macro_shader_rid, 0)
	macro_pipeline_rid = rd.compute_pipeline_create(macro_shader_rid)

	# --- 2. ПАЙПЛАЙН ДЛЯ ФІНАЛЬНОГО ПРОХОДУ ---
	# Створюємо uniform для читання макро-текстури
	var depth_uniform := RDUniform.new()
	depth_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	depth_uniform.binding = 2
	depth_uniform.add_id(sampler_rid)
	depth_uniform.add_id(macro_texture_rid)

	for i in 2:
		var img_uniform := RDUniform.new()
		img_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		img_uniform.binding = 0
		img_uniform.add_id(texture_rids[i])

		# Фінальний шейдер отримує 3 бінди: Output Image(0), Camera(1), Macro Depth(2)
		var set = rd.uniform_set_create([img_uniform, cam_uniform, depth_uniform], shader_rid, 0)
		uniform_sets.append(set)

	pipeline_rid = rd.compute_pipeline_create(shader_rid)


# --- Per-frame update ---

func _process(_delta: float) -> void:
	_update_camera_buffer()
	_dispatch()


func _update_camera_buffer() -> void:
	var t := target_camera.global_transform
	var basis := t.basis

	# precompute once
	var fov_scale := tan(deg_to_rad(target_camera.fov * 0.5))

	# fill buffer directly (no push_back, no resize)
	# cameraPos
	cam_data[0] = t.origin.x
	cam_data[1] = t.origin.y
	cam_data[2] = t.origin.z
	cam_data[3] = 0.0

	# forward (-Z)
	var f := -basis.z
	cam_data[4] = f.x
	cam_data[5] = f.y
	cam_data[6] = f.z
	cam_data[7] = 0.0

	# right (X)
	var r := basis.x
	cam_data[8] = r.x
	cam_data[9] = r.y
	cam_data[10] = r.z
	cam_data[11] = 0.0

	# up (Y)
	var u := basis.y
	cam_data[12] = u.x
	cam_data[13] = u.y
	cam_data[14] = u.z
	cam_data[15] = 0.0

	# resolution + fovScale
	cam_data[16] = render_resolution.x
	cam_data[17] = render_resolution.y
	cam_data[18] = fov_scale
	cam_data[19] = 0.0 # padding

	rd.buffer_update(camera_buffer_rid, 0, cam_data.size() * 4, cam_data.to_byte_array())


func _dispatch() -> void:
	var write_i := frame_index & 1
	var read_i := 1 - write_i
	texture_rect.texture = tex_rd_resources[read_i]

	var list := rd.compute_list_begin()

	# ==========================================
	# ФАЗА 1: МАКРО-ПРОХІД (Cone Marching)
	# ==========================================
	var mac_x := int(ceil((render_resolution.x / macro_scale) / 16.0))
	var mac_y := int(ceil((render_resolution.y / macro_scale) / 16.0))

	rd.compute_list_bind_compute_pipeline(list, macro_pipeline_rid)
	rd.compute_list_bind_uniform_set(list, macro_uniform_set, 0)

	var pc_macro := PackedFloat32Array([
		fractal_power, float(fractal_iterations), fractal_bailout, step_scale,
		omega_max, omega_beta,
		macro_scale, # ТУТ ПЕРЕДАЄМО 4.0!
		0.0
	])
	var bytes_macro := pc_macro.to_byte_array()
	rd.compute_list_set_push_constant(list, bytes_macro, bytes_macro.size())
	
	rd.compute_list_dispatch(list, mac_x, mac_y, 1)

	# Godot автоматично ставить Бар'єр Пам'яті (Memory Barrier) тут, 
	# бо бачить, що наступний пайплайн хоче читати macro_texture_rid

	# ==========================================
	# ФАЗА 2: ФІНАЛЬНИЙ ПРОХІД (Algorithm 4)
	# ==========================================
	var final_x := int(ceil(render_resolution.x / 16.0))
	var final_y := int(ceil(render_resolution.y / 16.0))

	rd.compute_list_bind_compute_pipeline(list, pipeline_rid)
	rd.compute_list_bind_uniform_set(list, uniform_sets[write_i], 0)

	var pc_final := PackedFloat32Array([
		fractal_power, float(fractal_iterations), fractal_bailout, step_scale,
		omega_max, omega_beta,
		1.0, # ТУТ ПЕРЕДАЄМО 1.0
		0.0
	])
	var bytes_final := pc_final.to_byte_array()
	rd.compute_list_set_push_constant(list, bytes_final, bytes_final.size())

	rd.compute_list_dispatch(list, final_x, final_y, 1)

	rd.compute_list_end()
	frame_index += 1


# --- Cleanup ---

func _exit_tree() -> void:
	if not rd:
		return

	for u in uniform_sets:
		if u.is_valid(): rd.free_rid(u)

	for t in texture_rids:
		if t.is_valid(): rd.free_rid(t)

	if pipeline_rid.is_valid(): rd.free_rid(pipeline_rid)
	if shader_rid.is_valid(): rd.free_rid(shader_rid)
	if camera_buffer_rid.is_valid(): rd.free_rid(camera_buffer_rid)
