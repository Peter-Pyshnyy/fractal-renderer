extends Node

@export var texture_rect: TextureRect
@export var target_camera: Camera3D
@export var VRSTimer: Timer
@export var render_resolution := Vector2(1920, 1080)

@export_category("Initial Scene State")
@export var initial_fractal: FractalData
@export var initial_material: FractalMaterial

@onready var file_dialog: FileDialog = $"../UI_Root/MainSplit/FileDialog"


var camera_rig: Node3D
var rd: RenderingDevice
var camera_buffer_rid: RID
var scene_buffer_rid: RID

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

var pipelines: Dictionary = {}
var current_pipeline: RID
var shader_layout_rid: RID
var _custom_shader_rid: RID

var _last_fractal_index := -1
var _scene_dirty := true


func _ready() -> void:
	if not target_camera:
		push_error("Camera3D not assigned"); return

	StateBus.scene.fractal_data = initial_fractal
	StateBus.scene.material = initial_material
	camera_rig = target_camera.get_parent()
	rd = RenderingServer.get_rendering_device()

	render_resolution = texture_rect.size.max(Vector2.ONE)

	_create_texture()
	_create_camera_buffer()
	_create_scene_buffer()
	_create_pipeline()
	compile_custom_shader(Global.custom_fractal_data.glsl_source)

	texture_rect.resized.connect(_on_texture_rect_resized)
	StateBus.scene.changed.connect(_on_scene_changed)
	StateBus.render.changed.connect(_mark_motion)
	StateBus.camera.changed.connect(_mark_motion)
	
	StateBus.renderer_controller = self
	_last_fractal_index = StateBus.scene.fractal_index
	current_pipeline = pipelines[_last_fractal_index]
	
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.png ; PNG Image"])

	file_dialog.file_selected.connect(save_texture)

func _create_texture() -> void:
	var fmt := RDTextureFormat.new()
	fmt.width = int(render_resolution.x)
	fmt.height = int(render_resolution.y)
	fmt.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT \
				   | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
	fmt.usage_bits |= RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	for i in 2:
		var tex_rid := rd.texture_create(fmt, RDTextureView.new())
		texture_rids.append(tex_rid)
		var tex_res := Texture2DRD.new()
		tex_res.texture_rd_rid = tex_rid
		tex_rd_resources.append(tex_res)
	texture_rect.texture = tex_rd_resources[0]


func _on_texture_rect_resized() -> void:
	var new_size := texture_rect.size.floor()
	if new_size.x < 1 or new_size.y < 1: return
	if new_size == render_resolution: return

	render_resolution = new_size

	for u in uniform_sets:
		if u.is_valid(): rd.free_rid(u)
	uniform_sets.clear()

	for t in texture_rids:
		if t.is_valid(): rd.free_rid(t)
	texture_rids.clear()
	tex_rd_resources.clear()

	_create_texture()
	_rebuild_uniform_sets()

	accumulation_samples = 0
	taa_history_weight = 0.0
	_mark_motion()


func _create_camera_buffer() -> void:
	cam_data.resize(20); cam_data.fill(0.0)
	var bytes := cam_data.to_byte_array()
	camera_buffer_rid = rd.storage_buffer_create(bytes.size(), bytes)


func _create_scene_buffer() -> void:
	var bytes := GPULayout.pack_scene(StateBus.scene)
	scene_buffer_rid = rd.storage_buffer_create(bytes.size(), bytes)


func _create_pipeline() -> void:
	var mandelbulb_a := load("res://shaders/fragment/mandelbulb.glsl") as RDShaderFile
	var mb_a_rid := rd.shader_create_from_spirv(mandelbulb_a.get_spirv())
	pipelines[0] = rd.compute_pipeline_create(mb_a_rid)

	var mandelbulb_b := load("res://shaders/fragment/mandelbulb_b.glsl") as RDShaderFile
	var mb_b_rid := rd.shader_create_from_spirv(mandelbulb_b.get_spirv())
	pipelines[1] = rd.compute_pipeline_create(mb_b_rid)

	var mandelbulb_c := load("res://shaders/fragment/mandelbulb_c.glsl") as RDShaderFile
	var mb_c_rid := rd.shader_create_from_spirv(mandelbulb_c.get_spirv())
	pipelines[2] = rd.compute_pipeline_create(mb_c_rid)

	var quaternion_julia_basic := load("res://shaders/fragment/quaternion_julia_basic.glsl") as RDShaderFile
	var qjb_rid := rd.shader_create_from_spirv(quaternion_julia_basic.get_spirv())
	pipelines[3] = rd.compute_pipeline_create(qjb_rid)
	
	var quaternion_julia := load("res://shaders/fragment/quaternion_julia.glsl") as RDShaderFile
	var qj_rid := rd.shader_create_from_spirv(quaternion_julia.get_spirv())
	pipelines[4] = rd.compute_pipeline_create(qj_rid)

	var sierpinski := load("res://shaders/fragment/sierpinski.glsl") as RDShaderFile
	var sp_rid := rd.shader_create_from_spirv(sierpinski.get_spirv())
	pipelines[5] = rd.compute_pipeline_create(sp_rid)

	var menger := load("res://shaders/fragment/menger_koleidoscope.glsl") as RDShaderFile
	var mk_rid := rd.shader_create_from_spirv(menger.get_spirv())
	pipelines[6] = rd.compute_pipeline_create(mk_rid)
	
	var mandelbox := load("res://shaders/fragment/mandelbox.glsl") as RDShaderFile
	var mbx_rid := rd.shader_create_from_spirv(mandelbox.get_spirv())
	pipelines[7] = rd.compute_pipeline_create(mbx_rid)


	shader_layout_rid = mb_a_rid
	_rebuild_uniform_sets()


func _rebuild_uniform_sets() -> void:
	for u in uniform_sets:
		if u.is_valid(): rd.free_rid(u)
	uniform_sets.clear()

	for i in 2:
		var read_i := 1 - i

		var img_u := RDUniform.new()
		img_u.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		img_u.binding = 0
		img_u.add_id(texture_rids[i])

		var cam_u := RDUniform.new()
		cam_u.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		cam_u.binding = 1
		cam_u.add_id(camera_buffer_rid)

		var hist_u := RDUniform.new()
		hist_u.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		hist_u.binding = 2
		hist_u.add_id(texture_rids[read_i])

		var scene_u := RDUniform.new()
		scene_u.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		scene_u.binding = 3
		scene_u.add_id(scene_buffer_rid)

		uniform_sets.append(
			rd.uniform_set_create([img_u, cam_u, hist_u, scene_u], shader_layout_rid, 0)
		)


func _on_scene_changed() -> void:
	_scene_dirty = true
	if StateBus.scene.fractal_index != _last_fractal_index:
		_last_fractal_index = StateBus.scene.fractal_index
		if pipelines.has(_last_fractal_index):
			current_pipeline = pipelines[_last_fractal_index]
	_mark_motion()

func _process(_delta: float) -> void:
	var is_moving : bool = camera_rig.is_moving
	last_cam_transform = target_camera.global_transform

	if is_moving:
		accumulation_samples = 0
		taa_jitter = Vector2.ZERO
		taa_history_weight = 0.0
		current_res_scale = StateBus.render.vrs_scale if StateBus.render.vrs_enabled else 1
		if camera_rig.motion_version != last_motion_version:
			last_motion_version = camera_rig.motion_version
			VRSTimer.start()
	else:
		accumulation_samples += 1
		if accumulation_samples <= 1:
			taa_jitter = Vector2.ZERO
			taa_history_weight = 0.0
		else:
			var s_idx := accumulation_samples - 1
			taa_jitter = Vector2(_halton(s_idx, 2) - 0.5, _halton(s_idx, 3) - 0.5)
			taa_history_weight = float(accumulation_samples - 1) / float(accumulation_samples)

	_update_camera_buffer()

	if _scene_dirty:
		var scene_bytes := GPULayout.pack_scene(StateBus.scene)
		rd.buffer_update(scene_buffer_rid, 0, scene_bytes.size(), scene_bytes)
		_scene_dirty = false

	_dispatch()


func _update_camera_buffer() -> void:
	var t := target_camera.global_transform
	var basis := t.basis
	var fov_scale := tan(deg_to_rad(target_camera.fov * 0.5))

	cam_data[0] = t.origin.x; cam_data[1] = t.origin.y; cam_data[2] = t.origin.z; cam_data[3] = 0.0
	var f := -basis.z
	cam_data[4] = f.x; cam_data[5] = f.y; cam_data[6] = f.z; cam_data[7] = 0.0
	var r := basis.x
	cam_data[8] = r.x; cam_data[9] = r.y; cam_data[10] = r.z; cam_data[11] = 0.0
	var u := basis.y
	cam_data[12] = u.x; cam_data[13] = u.y; cam_data[14] = u.z; cam_data[15] = 0.0
	cam_data[16] = render_resolution.x
	cam_data[17] = render_resolution.y
	cam_data[18] = fov_scale
	cam_data[19] = 0.0

	rd.buffer_update(camera_buffer_rid, 0, cam_data.size() * 4, cam_data.to_byte_array())


func _dispatch() -> void:
	var write_i := frame_index & 1
	texture_rect.texture = tex_rd_resources[write_i]

	var sw := int(ceil(render_resolution.x / float(current_res_scale)))
	var sh := int(ceil(render_resolution.y / float(current_res_scale)))
	var gx := int(ceil(sw / 16.0))
	var gy := int(ceil(sh / 16.0))

	var list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(list, current_pipeline)
	rd.compute_list_bind_uniform_set(list, uniform_sets[write_i], 0)

	var pc := GPULayout.pack_frame(taa_jitter, taa_history_weight, current_res_scale, frame_index)
	rd.compute_list_set_push_constant(list, pc, pc.size())

	rd.compute_list_dispatch(list, gx, gy, 1)
	rd.compute_list_end()

	frame_index += 1


func _halton(index: int, base: int) -> float:
	var f := 1.0; var r := 0.0; var i := index
	while i > 0:
		f /= float(base); r += f * float(i % base); i = int(i / base)
	return r

func compile_custom_shader(sdf_source: String) -> String:
	var src := ShaderAssembler.build(sdf_source)
	var rd_src := RDShaderSource.new()
	rd_src.source_compute = src
	var spirv: RDShaderSPIRV = rd.shader_compile_spirv_from_source(rd_src)
	if spirv.compile_error_compute != "":
		return spirv.compile_error_compute

	var new_shader_rid := rd.shader_create_from_spirv(spirv)
	var new_pipeline := rd.compute_pipeline_create(new_shader_rid)

	if pipelines.has(8) and pipelines[8].is_valid():
		rd.free_rid(pipelines[8])
	if _custom_shader_rid.is_valid():
		rd.free_rid(_custom_shader_rid)

	_custom_shader_rid = new_shader_rid
	pipelines[8] = new_pipeline

	if StateBus.scene.fractal_index == 8:
		current_pipeline = pipelines[8]
		_mark_motion()

	return ""

func _exit_tree() -> void:
	if not rd: return
	StateBus.renderer_controller = null
	texture_rect.texture = null
	for u in uniform_sets: if u.is_valid(): rd.free_rid(u)
	for t in texture_rids: if t.is_valid(): rd.free_rid(t)
	for p in pipelines.values(): if p.is_valid(): rd.free_rid(p)
	if _custom_shader_rid.is_valid(): rd.free_rid(_custom_shader_rid)
	if camera_buffer_rid.is_valid(): rd.free_rid(camera_buffer_rid)
	if scene_buffer_rid.is_valid():  rd.free_rid(scene_buffer_rid)
	uniform_sets.clear(); texture_rids.clear()
	tex_rd_resources.clear(); pipelines.clear()


func _on_vrs_timer_timeout() -> void:
	current_res_scale = 1
	camera_rig.is_moving = false


func _mark_motion() -> void:
	accumulation_samples = 0
	taa_history_weight = 0.0
	if camera_rig and camera_rig.has_method("_mark_motion"):
		camera_rig._mark_motion()

func save_texture(path: String) -> void:
	var tex: Texture2DRD = texture_rect.texture

	rd.submit()
	rd.sync()

	var rid := tex.texture_rd_rid
	var data: PackedByteArray = rd.texture_get_data(rid, 0)

	print("Data size: ", data.size())

	if data.is_empty():
		push_error("Texture readback failed")
		return

	var image := Image.create_from_data(
		tex.get_width(),
		tex.get_height(),
		false,
		Image.FORMAT_RGBAF,
		data
	)

	image.convert(Image.FORMAT_RGBA8)

	var err := image.save_png(path)

	print("Save result: ", err)


func _on_screenshot_btn_pressed() -> void:
	file_dialog.popup_centered()
