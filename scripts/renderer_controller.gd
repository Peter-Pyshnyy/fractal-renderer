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
var shader_rid_32: RID
var shader_rid_64: RID
var pipeline_32_rid: RID
var pipeline_64_rid: RID
var camera_buffer_32_rid: RID
var camera_buffer_64_rid: RID

var texture_rids: Array[RID]
var tex_rd_resources: Array[Texture2DRD]
var uniform_sets_32: Array[RID]
var uniform_sets_64: Array[RID]
var frame_index := 0
var accumulation_samples := 0

var cam_data_32 := PackedFloat32Array()
var cam_data_64_origin := PackedFloat64Array()
var cam_data_64_vectors := PackedFloat32Array()
var cam_data_64_bytes := PackedByteArray()
var last_cam_transform: Transform3D
var current_res_scale: int = 1
var taa_jitter := Vector2.ZERO
var taa_history_weight := 0.0
var last_motion_version := -1
var is_photo_mode := false

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
	var shader_32_file := load("res://shaders/fragment/mandelbulb.glsl") as RDShaderFile
	shader_rid_32 = rd.shader_create_from_spirv(shader_32_file.get_spirv())

	var shader_64_file := load("res://shaders/fragment/mandelbulb_64.glsl") as RDShaderFile
	shader_rid_64 = rd.shader_create_from_spirv(shader_64_file.get_spirv())


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
	cam_data_32.resize(20)
	cam_data_32.fill(0.0)

	var bytes_32 := cam_data_32.to_byte_array()
	camera_buffer_32_rid = rd.storage_buffer_create(bytes_32.size(), bytes_32)

	# std430 layout for mixed precision camera buffer (96 bytes):
	# dvec4 position64 @ 0
	# vec4  forward    @ 32
	# vec4  right      @ 48
	# vec4  up         @ 64
	# vec4  res/fov    @ 80
	cam_data_64_origin.resize(4)
	cam_data_64_origin.fill(0.0)
	cam_data_64_vectors.resize(16)
	cam_data_64_vectors.fill(0.0)
	cam_data_64_bytes.resize(96)
	camera_buffer_64_rid = rd.storage_buffer_create(cam_data_64_bytes.size(), cam_data_64_bytes)


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
		cam_uniform.add_id(camera_buffer_32_rid)

		var set_32 = rd.uniform_set_create([img_uniform, cam_uniform, history_uniform], shader_rid_32, 0)
		uniform_sets_32.append(set_32)

		var cam_uniform_64 := RDUniform.new()
		cam_uniform_64.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		cam_uniform_64.binding = 1
		cam_uniform_64.add_id(camera_buffer_64_rid)

		var set_64 = rd.uniform_set_create([img_uniform, cam_uniform_64, history_uniform], shader_rid_64, 0)
		uniform_sets_64.append(set_64)

	pipeline_32_rid = rd.compute_pipeline_create(shader_rid_32)
	pipeline_64_rid = rd.compute_pipeline_create(shader_rid_64)


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


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_P:
		is_photo_mode = not is_photo_mode
		accumulation_samples = 0
		taa_jitter = Vector2.ZERO
		taa_history_weight = 0.0


func _update_camera_buffer() -> void:
	var t := target_camera.global_transform
	var basis := t.basis

	# precompute once
	var fov_scale := tan(deg_to_rad(target_camera.fov * 0.5))

	# fill float32 pipeline camera data
	cam_data_32[0] = t.origin.x
	cam_data_32[1] = t.origin.y
	cam_data_32[2] = t.origin.z
	cam_data_32[3] = 0.0

	# forward (-Z)
	var f := -basis.z
	cam_data_32[4] = f.x
	cam_data_32[5] = f.y
	cam_data_32[6] = f.z
	cam_data_32[7] = 0.0

	# right (X)
	var r := basis.x
	cam_data_32[8] = r.x
	cam_data_32[9] = r.y
	cam_data_32[10] = r.z
	cam_data_32[11] = 0.0

	# up (Y)
	var u := basis.y
	cam_data_32[12] = u.x
	cam_data_32[13] = u.y
	cam_data_32[14] = u.z
	cam_data_32[15] = 0.0

	# resolution + fovScale
	cam_data_32[16] = render_resolution.x
	cam_data_32[17] = render_resolution.y
	cam_data_32[18] = fov_scale
	cam_data_32[19] = 0.0 # padding
	rd.buffer_update(camera_buffer_32_rid, 0, cam_data_32.size() * 4, cam_data_32.to_byte_array())

	# fill mixed precision photo mode camera data (std430 aligned)
	var rig := camera_rig as Node
	if rig:
		cam_data_64_origin[0] = float(rig.get("precise_x"))
		cam_data_64_origin[1] = float(rig.get("precise_y"))
		cam_data_64_origin[2] = float(rig.get("precise_z"))
	else:
		cam_data_64_origin[0] = float(t.origin.x)
		cam_data_64_origin[1] = float(t.origin.y)
		cam_data_64_origin[2] = float(t.origin.z)
	cam_data_64_origin[3] = 0.0

	cam_data_64_vectors[0] = f.x
	cam_data_64_vectors[1] = f.y
	cam_data_64_vectors[2] = f.z
	cam_data_64_vectors[3] = 0.0
	cam_data_64_vectors[4] = r.x
	cam_data_64_vectors[5] = r.y
	cam_data_64_vectors[6] = r.z
	cam_data_64_vectors[7] = 0.0
	cam_data_64_vectors[8] = u.x
	cam_data_64_vectors[9] = u.y
	cam_data_64_vectors[10] = u.z
	cam_data_64_vectors[11] = 0.0
	cam_data_64_vectors[12] = render_resolution.x
	cam_data_64_vectors[13] = render_resolution.y
	cam_data_64_vectors[14] = fov_scale
	cam_data_64_vectors[15] = 0.0

	cam_data_64_bytes = PackedByteArray()
	cam_data_64_bytes.append_array(cam_data_64_origin.to_byte_array())
	cam_data_64_bytes.append_array(cam_data_64_vectors.to_byte_array())
	rd.buffer_update(camera_buffer_64_rid, 0, cam_data_64_bytes.size(), cam_data_64_bytes)


func _dispatch() -> void:
	var write_i := frame_index & 1

	# display current output texture
	texture_rect.texture = tex_rd_resources[write_i]

	var scaled_width := int(ceil(render_resolution.x / float(current_res_scale)))
	var scaled_height := int(ceil(render_resolution.y / float(current_res_scale)))
	var x_groups := int(ceil(scaled_width / 16.0))
	var y_groups := int(ceil(scaled_height / 16.0))

	var list := rd.compute_list_begin()
	var active_pipeline := pipeline_64_rid if is_photo_mode else pipeline_32_rid
	var active_uniform_sets := uniform_sets_64 if is_photo_mode else uniform_sets_32
	rd.compute_list_bind_compute_pipeline(list, active_pipeline)
	rd.compute_list_bind_uniform_set(list, active_uniform_sets[write_i], 0)

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

	texture_rect.texture = null
	tex_rd_resources.clear()

	for rid in uniform_sets_32:
		rd.free_rid(rid)
	for rid in uniform_sets_64:
		rd.free_rid(rid)

	for rid in texture_rids:
		rd.free_rid(rid)

	if camera_buffer_32_rid.is_valid():
		rd.free_rid(camera_buffer_32_rid)
	if camera_buffer_64_rid.is_valid():
		rd.free_rid(camera_buffer_64_rid)
	if pipeline_32_rid.is_valid():
		rd.free_rid(pipeline_32_rid)
	if pipeline_64_rid.is_valid():
		rd.free_rid(pipeline_64_rid)
	if shader_rid_32.is_valid():
		rd.free_rid(shader_rid_32)
	if shader_rid_64.is_valid():
		rd.free_rid(shader_rid_64)


func _on_vrs_timer_timeout() -> void:
	current_res_scale = 1
	camera_rig.is_moving = false
