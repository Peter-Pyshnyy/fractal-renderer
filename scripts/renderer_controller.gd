extends Node

@export var texture_rect: TextureRect
@export var target_camera: Camera3D
var camera_rig: Node3D
@export var render_resolution := Vector2(1920, 1080)
@export var VRSTimer : Timer

@export var test: float = 0.1
@export var VRS: bool = true
@export var VRSScale: int = 2

@export_category("Fractal Settings")
@export_range(1.0, 20.0, 0.1) var fractal_power: float = 8.0
@export_range(1, 100, 1) var fractal_iterations: int = 15

@export_category("Raymarching Tuning")
@export var step_scale: float = 0.4
@export var fractal_data: FractalData
@export var material: FractalMaterial

@export_category("PBR Settings")
@export_range(0.0, 1.0, 0.01) var u_metallic: float = 0.75
@export_range(0.0, 1.0, 0.01) var u_roughness: float = 0.5
@export var u_lightDir: Vector3 = Vector3(1.0, 1.0, 1.0)

var rd: RenderingDevice
var shader_rid: RID
var pipeline_rid: RID
var camera_buffer_rid: RID

var texture_rids: Array[RID]
var tex_rd_resources: Array[Texture2DRD]
var uniform_sets: Array[RID]
var frame_index := 0
var accumulation_samples := 0

var cam_data := PackedFloat32Array()
var last_cam_transform: Transform3D
var current_res_scale: int = 1
var taa_jitter := Vector2.ZERO
var taa_history_weight := 0.0
var last_motion_version := -1

func _ready() -> void: 
	if not target_camera: 
		push_error("Camera3D not assigned") 
		return 
	
	Global.g_fractal = fractal_data
	Global.g_active_material = material
	camera_rig = target_camera.get_parent()
	rd = RenderingServer.get_rendering_device() 
	_create_shader() 
	_create_texture() 
	_create_camera_buffer() 
	_create_pipeline() 


# --- Setup ---

func _create_shader() -> void:
	var shader_file := load("res://shaders/fragment/mandelbulb.glsl") as RDShaderFile
	shader_rid = rd.shader_create_from_spirv(shader_file.get_spirv())


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

func _create_camera_buffer() -> void:
	# 5 vec4 = 20 floats
	cam_data.resize(20)
	cam_data.fill(0.0)

	var bytes := cam_data.to_byte_array()
	camera_buffer_rid = rd.storage_buffer_create(bytes.size(), bytes)


func _create_pipeline() -> void:
	for i in 2:
		var read_i := 1 - i

		var img_uniform := RDUniform.new()
		img_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		img_uniform.binding = 0
		img_uniform.add_id(texture_rids[i])

		var history_uniform := RDUniform.new()
		history_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		history_uniform.binding = 2
		history_uniform.add_id(texture_rids[read_i])

		var cam_uniform := RDUniform.new()
		cam_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		cam_uniform.binding = 1
		cam_uniform.add_id(camera_buffer_rid)

		var set = rd.uniform_set_create([img_uniform, cam_uniform, history_uniform], shader_rid, 0)
		uniform_sets.append(set)

	pipeline_rid = rd.compute_pipeline_create(shader_rid)


# --- Per-frame update ---

func _process(_delta: float) -> void:
	var is_moving = camera_rig.is_moving
	last_cam_transform = target_camera.global_transform
	
	if is_moving:
		accumulation_samples = 0
		taa_jitter = Vector2.ZERO
		taa_history_weight = 0.0
		current_res_scale = VRSScale if VRS else 1
		if camera_rig.motion_version != last_motion_version:
			last_motion_version = camera_rig.motion_version
			VRSTimer.start()
	else:
		accumulation_samples += 1
		if accumulation_samples <= 1:
			taa_jitter = Vector2.ZERO
			taa_history_weight = 0.0
		else:
			var sample_index := accumulation_samples - 1
			taa_jitter = Vector2(
				_halton(sample_index, 2) - 0.5,
				_halton(sample_index, 3) - 0.5
			)
			taa_history_weight = float(accumulation_samples - 1) / float(accumulation_samples)
	
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

	# display current output texture
	texture_rect.texture = tex_rd_resources[write_i]

	var scaled_width := int(ceil(render_resolution.x / float(current_res_scale)))
	var scaled_height := int(ceil(render_resolution.y / float(current_res_scale)))
	var x_groups := int(ceil(scaled_width / 16.0))
	var y_groups := int(ceil(scaled_height / 16.0))

	var list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(list, pipeline_rid)
	rd.compute_list_bind_uniform_set(list, uniform_sets[write_i], 0)

	var params = Global.g_fractal.get_shader_params()
	var col0 = Global.g_active_material.color0
	var col1 = Global.g_active_material.color1
	var pc_bytes := PackedByteArray()

	pc_bytes.append_array(PackedFloat32Array([
		params[0], 
		params[1],
		params[2],
		params[3],

		col0.r, col0.g, col0.b, 1.0,
		col1.r, col1.g, col1.b, 1.0,
		u_metallic,
		u_roughness,
		0.0, 0.0,
		u_lightDir.x, u_lightDir.y, u_lightDir.z, 0.0,
	]).to_byte_array())

	pc_bytes.append_array(PackedInt32Array([
		current_res_scale
	]).to_byte_array())

	pc_bytes.append_array(PackedFloat32Array([
		taa_jitter.x,
		taa_jitter.y,
		taa_history_weight,
	]).to_byte_array())

	rd.compute_list_set_push_constant(list, pc_bytes, pc_bytes.size())
	# --------------------------------------------

	rd.compute_list_dispatch(list, x_groups, y_groups, 1)
	rd.compute_list_end()

	frame_index += 1


func _halton(index: int, base: int) -> float:
	var f := 1.0
	var r := 0.0
	var i := index

	while i > 0:
		f /= float(base)
		r += f * float(i % base)
		i = int(i / base)

	return r


# --- Cleanup ---

func _exit_tree() -> void:
	if not rd:
		return

	# Release texture from UI
	texture_rect.texture = null

	# Clear resource references
	tex_rd_resources.clear()
	texture_rids.clear()
	uniform_sets.clear()

	for u in uniform_sets:
		if u.is_valid(): rd.free_rid(u)

	for t in texture_rids:
		if t.is_valid(): rd.free_rid(t)

	if pipeline_rid.is_valid(): rd.free_rid(pipeline_rid)
	if shader_rid.is_valid(): rd.free_rid(shader_rid)
	if camera_buffer_rid.is_valid(): rd.free_rid(camera_buffer_rid)


func _on_vrs_timer_timeout() -> void:
	current_res_scale = 1
	camera_rig.is_moving = false
