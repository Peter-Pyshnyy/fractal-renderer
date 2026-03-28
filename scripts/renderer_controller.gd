extends Node

@export var texture_rect: TextureRect
@export var target_camera: Camera3D
@export var render_resolution := Vector2(1920, 1080)

var rd: RenderingDevice
var shader_rid: RID
var pipeline_rid: RID
#var texture_rid: RID
var camera_buffer_rid: RID
#var uniform_set_rid: RID
#var tex_rd_resource: Texture2DRD

var texture_rids: Array[RID]
var tex_rd_resources: Array[Texture2DRD]
var uniform_sets: Array[RID]
var frame_index := 0

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
		var img_uniform := RDUniform.new()
		img_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		img_uniform.binding = 0
		img_uniform.add_id(texture_rids[i])

		var cam_uniform := RDUniform.new()
		cam_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		cam_uniform.binding = 1
		cam_uniform.add_id(camera_buffer_rid)

		var set = rd.uniform_set_create([img_uniform, cam_uniform], shader_rid, 0)
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

	# display previous frame
	texture_rect.texture = tex_rd_resources[read_i]

	var x_groups := int(ceil(render_resolution.x / 16.0))
	var y_groups := int(ceil(render_resolution.y / 16.0))

	var list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(list, pipeline_rid)
	rd.compute_list_bind_uniform_set(list, uniform_sets[write_i], 0)
	rd.compute_list_dispatch(list, x_groups, y_groups, 1)
	rd.compute_list_end()
	rd.submit()

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
