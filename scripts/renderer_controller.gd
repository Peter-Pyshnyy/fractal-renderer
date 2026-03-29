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

var macro_scales: Array[float] = [8.0, 4.0, 2.0]
var macro_texture_rids: Array[RID] = []
var macro_uniform_sets: Array[RID] = []

var dummy_texture_rid: RID # Порожня текстура-заглушка
var sampler_rid: RID
var macro_shader_rid: RID
var macro_pipeline_rid: RID


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
	
	for scale in macro_scales:
		var m_fmt := RDTextureFormat.new()
		m_fmt.width = int(ceil(render_resolution.x / scale))
		m_fmt.height = int(ceil(render_resolution.y / scale))
		m_fmt.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
		m_fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
		var tex_rid = rd.texture_create(m_fmt, RDTextureView.new(), [])
		macro_texture_rids.append(tex_rid)

	# Створюємо Dummy-текстуру (заглушку 1х1) для найпершого проходу
	var d_fmt := RDTextureFormat.new()
	d_fmt.width = 1; d_fmt.height = 1; d_fmt.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
	d_fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
	dummy_texture_rid = rd.texture_create(d_fmt, RDTextureView.new(), [])
	rd.texture_update(dummy_texture_rid, 0, PackedFloat32Array([0.0]).to_byte_array())

	# Семплер
	var sampler_state := RDSamplerState.new()
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

	macro_pipeline_rid = rd.compute_pipeline_create(macro_shader_rid)
	
	# Створюємо сети для макро-проходів
	for i in range(macro_scales.size()):
		var out_img = RDUniform.new()
		out_img.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		out_img.binding = 0
		out_img.add_id(macro_texture_rids[i])
		
		var in_depth = RDUniform.new()
		in_depth.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
		in_depth.binding = 2
		in_depth.add_id(sampler_rid)
		# Якщо це перший прохід, читаємо заглушку. Інакше - читаємо попередній буфер.
		in_depth.add_id(dummy_texture_rid if i == 0 else macro_texture_rids[i - 1])
		
		var set = rd.uniform_set_create([out_img, cam_uniform, in_depth], macro_shader_rid, 0)
		macro_uniform_sets.append(set)

	# Сети для фінального проходу (читають останній макро-буфер)
	var final_depth = RDUniform.new()
	final_depth.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	final_depth.binding = 2
	final_depth.add_id(sampler_rid)
	final_depth.add_id(macro_texture_rids[-1]) # Останній елемент масиву (1/2)

	for i in 2:
		var img_out = RDUniform.new()
		img_out.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		img_out.binding = 0
		img_out.add_id(texture_rids[i])
		
		var set = rd.uniform_set_create([img_out, cam_uniform, final_depth], shader_rid, 0)
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

	# --- ФАЗА 1: КАСКАД МАКРО-ПРОХОДІВ ---
	rd.compute_list_bind_compute_pipeline(list, macro_pipeline_rid)
	
	for i in range(macro_scales.size()):
		var scale = macro_scales[i]
		var mac_x := int(ceil((render_resolution.x / scale) / 16.0))
		var mac_y := int(ceil((render_resolution.y / scale) / 16.0))
		
		rd.compute_list_bind_uniform_set(list, macro_uniform_sets[i], 0)
		
		var pc_macro := PackedFloat32Array([
			fractal_power, float(fractal_iterations), fractal_bailout, step_scale,
			omega_max, omega_beta,
			scale, 
			float(i) # pass_index (0.0 для першого, 1.0, 2.0...)
		])
		var bytes_macro := pc_macro.to_byte_array()
		rd.compute_list_set_push_constant(list, bytes_macro, bytes_macro.size())
		
		rd.compute_list_dispatch(list, mac_x, mac_y, 1)
		#rd.compute_list_add_barrier(list)

	# --- ФАЗА 2: ФІНАЛЬНИЙ ПРОХІД ---
	#rd.compute_list_add_barrier(list)
	rd.compute_list_bind_compute_pipeline(list, pipeline_rid)
	rd.compute_list_bind_uniform_set(list, uniform_sets[write_i], 0)

	var pc_final := PackedFloat32Array([
		fractal_power, float(fractal_iterations), fractal_bailout, step_scale,
		omega_max, omega_beta,
		1.0, 
		float(macro_scales.size()) # Фінальний індекс
	])
	var bytes_final := pc_final.to_byte_array()
	rd.compute_list_set_push_constant(list, bytes_final, bytes_final.size())

	var final_x := int(ceil(render_resolution.x / 16.0))
	var final_y := int(ceil(render_resolution.y / 16.0))
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
