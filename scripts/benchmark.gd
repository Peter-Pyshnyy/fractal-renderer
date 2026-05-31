extends Node

enum BenchmarkMode { SHORT_10S, LONG_60S }

@export var camera_rig: Node3D
@export var benchmark_mode: BenchmarkMode = BenchmarkMode.SHORT_10S
@export var benchmark_radius: float = 3.0
@onready var vrs_timer: Timer = $"../RendererController/VRSTimer"
@onready var virtual_camera: Camera3D = $"../CameraRig/VirtualCamera"


var is_profiling := false
var time_accum := 0.0
var frame_count := 0
var de_accum := 0.0

const BENCHMARK_YAW := 0.0
const BENCHMARK_PITCH := 0.3
const BENCHMARK_RADIUS := 3.0
const ZOOM_LEVEL := 2.0

var user_yaw := 0.0
var user_pitch := 0.0
var user_radius := 0.0
var user_fractal_index := 0

var is_frame_time_testing := false
var frame_test_duration := 5.0

var radii_MB: Array[float] = [1.425]
var radii_MBC: Array[float] = [1.425]
var radii_QJ: Array[float] = [1.4]
var radii_DQJ: Array[float] = [1.375]
var radii_KS: Array[float] = [0.97]
var radii_KM: Array[float] = [1.3]
var radii_MBX: Array[float] = [1.4]

#var radii_MB: Array[float] = [1.1, 1.425, 2.13]
#var radii_MBC: Array[float] = [1.15, 1.425, 2.13]
#var radii_QJ: Array[float] = [0.97, 1.4, 2.15]
#var radii_DQJ: Array[float] = [0.975, 1.375, 2.15]
#var radii_KS: Array[float] = [0.58, 1.0, 1.6]
#var radii_KM: Array[float] = [0.55, 1.3, 1.95]
#var radii_MBX: Array[float] = [0.975, 1.4, 2.05]

# Each entry: [fractal_index_in_g_data_arr, display_name, radii_array]
var benchmark_sequence: Array = []
var seq_idx := 0  # which entry in benchmark_sequence
var run := 0      # which radius within the current entry

func _ready() -> void:
	benchmark_sequence = [
		[0, "Mandelbulb A",              radii_MB, 3],
		[1, "Mandelbulb B",              radii_MB, 3],
		[2, "Mandelbulb C",              radii_MBC, 3],
		[3, "Quaternion Julia (Standard)", radii_QJ, 6],
		[4, "Dual Quaternion Julia",     radii_DQJ, 6],
		[5, "Sierpinski Tetrahedron",    radii_KS, 8],
		[6, "Menger Koleidoscope",       radii_KM, 8],
		[7, "Mandelbox",                 radii_MBX, 5],
	]

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("benchmark") and not is_profiling and not is_frame_time_testing:
		seq_idx = 0
		run = 0
		StateBus.scene.fractal_data.iterations = 1.0
		start_profiling()
	
	
	
	if event.is_action_pressed("frame_time_test") and not is_profiling and not is_frame_time_testing:
		start_frame_time_test()
	
	if event.is_action_pressed("check_dist") and not is_profiling and not is_frame_time_testing:
		print(StateBus.scene.fractal_data.sdf(virtual_camera.global_position))


func start_profiling() -> void:
	var entry = benchmark_sequence[seq_idx]
	var fractal_idx: int = entry[0]
	var radii: Array = entry[2]
	benchmark_radius = radii[run]

	if not camera_rig:
		push_error("Profiler: CameraRig not assigned")
		return

	if camera_rig.current_mode != camera_rig.CameraMode.ORBIT:
		camera_rig._switch_mode()

	vrs_timer.paused = true
	camera_rig.is_moving = true
	_save_user_state()

	StateBus.scene.switch_fractal(fractal_idx, Global.g_data_arr[fractal_idx])

	_set_benchmark_state()

	var fractal_name: String = entry[1]
	print("\nWarming up GPU... [%s | orbit %d]" % [fractal_name, run + 1])

	await _warmup_frames(50)

	var duration := _get_duration()
	print("=== BENCHMARK START: %s | Orbit %d/%d | %.0fs ===" % [fractal_name, run + 1, benchmark_sequence[seq_idx][2].size(), duration])

	is_profiling = true
	time_accum = 0.0
	frame_count = 0
	de_accum = 0.0


func _process(delta: float) -> void:
	if is_frame_time_testing:
		time_accum += delta
		frame_count += 1
		if time_accum >= frame_test_duration:
			_finish_frame_time_test()
		return
	
	if not is_profiling:
		return

	time_accum += delta
	frame_count += 1

	var fd := StateBus.scene.fractal_data
	if fd != null:
		de_accum += StateBus.scene.fractal_data.sdf(virtual_camera.global_position)

	var duration := _get_duration()
	var progress := time_accum / duration

	if progress <= 1.0:
		_update_camera(progress)
	else:
		_finish_profiling()

func _save_user_state() -> void:
	user_yaw = camera_rig.yaw
	user_pitch = camera_rig.pitch
	user_radius = camera_rig.orbit_radius
	user_fractal_index = StateBus.scene.fractal_index


func _restore_user_state() -> void:
	camera_rig.yaw = user_yaw
	camera_rig.pitch = user_pitch
	camera_rig.orbit_radius = user_radius
	camera_rig.is_moving = false
	vrs_timer.paused = false
	_apply_rotation(user_pitch, user_yaw)
	StateBus.scene.switch_fractal(user_fractal_index, Global.g_data_arr[user_fractal_index])


func _set_benchmark_state() -> void:
	camera_rig.yaw = BENCHMARK_YAW
	camera_rig.pitch = BENCHMARK_PITCH
	camera_rig.orbit_radius = benchmark_radius
	_apply_rotation(BENCHMARK_PITCH, BENCHMARK_YAW)


func _apply_rotation(pitch: float, yaw: float) -> void:
	camera_rig.rotation = Vector3(pitch, yaw, 0)


func _warmup_frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame

func _update_camera(progress: float) -> void:
	var cycles := _get_cycles()

	var yaw = BENCHMARK_YAW + progress * TAU * cycles

	var pitch = BENCHMARK_PITCH + sin(progress * TAU * cycles) * 0.4

	camera_rig.yaw = yaw
	camera_rig.pitch = pitch
	camera_rig.orbit_radius = benchmark_radius

	_apply_rotation(pitch, yaw)

func _get_duration() -> float:
	return 10.0 if benchmark_mode == BenchmarkMode.SHORT_10S else 60.0


func _get_cycles() -> float:
	return 1.0 if benchmark_mode == BenchmarkMode.SHORT_10S else 1.0

func _finish_profiling() -> void:
	is_profiling = false

	var entry = benchmark_sequence[seq_idx]
	var fractal_name: String = entry[1]
	var radii_count: int = entry[2].size()

	var avg_frame_time_ms = (time_accum / frame_count) * 1000.0
	var avg_fps = frame_count / time_accum
	var avg_de = de_accum / frame_count if frame_count > 0 else 0.0

	print("=== BENCHMARK DONE: %s | Orbit %d/%d ===" % [fractal_name, run + 1, radii_count])
	print("Frames: ", frame_count)
	print("Avg FPS: ", avg_fps)
	print("Avg DE value: ", avg_de)
	print("Avg frame (ms): ", avg_frame_time_ms)
	print("======================\n")

	run += 1
	if run == 1:
		StateBus.scene.fractal_data.iterations = entry[3]
		start_profiling()
	else:
		StateBus.scene.fractal_data.iterations += entry[3]
		if run > 4:
			seq_idx += 1
		if seq_idx < benchmark_sequence.size():
			start_profiling()
		else:
			seq_idx = 0
			run = 0
			_restore_user_state()
			print("=== FULL BENCHMARK COMPLETE ===\n")

	#run += 1
	#if run < radii_count:
		#start_profiling()
	#else:
		#run = 0
		#seq_idx += 1
		#if seq_idx < benchmark_sequence.size():
			#start_profiling()
		#else:
			#seq_idx = 0
			#_restore_user_state()
			#print("=== FULL BENCHMARK COMPLETE ===\n")
	
func start_frame_time_test() -> void:
	if not camera_rig:
		push_error("FrameTimeTest: CameraRig not assigned")
		return
	vrs_timer.paused = true
	camera_rig.is_moving = true
	print("\nWarming up GPU for frame time test...")
	await _warmup_frames(30)
	print("=== FRAME TIME TEST START | %.0fs ===" % frame_test_duration)
	is_frame_time_testing = true
	time_accum = 0.0
	frame_count = 0


func _finish_frame_time_test() -> void:
	vrs_timer.paused = false
	camera_rig.is_moving = false
	is_frame_time_testing = false
	var avg_frame_time_ms := (time_accum / frame_count) * 1000.0
	var avg_fps := frame_count / time_accum
	print("=== FRAME TIME TEST DONE ===")
	print("Frames: ", frame_count)
	print("Avg FPS: %.2f" % avg_fps)
	print("Avg frame time (ms): %.3f" % avg_frame_time_ms)
	print("============================\n")
