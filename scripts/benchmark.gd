extends Node

enum BenchmarkMode { SHORT_10S, LONG_60S }

@export var camera_rig: Node3D
@export var benchmark_mode: BenchmarkMode = BenchmarkMode.SHORT_10S

var is_profiling := false
var time_accum := 0.0
var frame_count := 0

# fixed benchmark start state
const BENCHMARK_YAW := 0.0
const BENCHMARK_PITCH := 0.3
const BENCHMARK_RADIUS := 3.0
const ZOOM_LEVEL := 2.0

# saved user state
var user_yaw := 0.0
var user_pitch := 0.0
var user_radius := 0.0


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("benchmark") and not is_profiling:
		start_profiling()


func start_profiling() -> void:
	if not camera_rig:
		push_error("Profiler: CameraRig not assigned")
		return

	# ensure orbit mode
	if camera_rig.current_mode != camera_rig.CameraMode.ORBIT:
		camera_rig._switch_mode()

	_save_user_state()
	_set_benchmark_state()

	print("\nWarming up GPU...")

	await _warmup_frames(3)

	var duration := _get_duration()
	print("=== BENCHMARK START: ", duration, "s ===")

	is_profiling = true
	time_accum = 0.0
	frame_count = 0


func _process(delta: float) -> void:
	if not is_profiling:
		return

	time_accum += delta
	frame_count += 1

	var duration := _get_duration()
	var progress := time_accum / duration

	if progress <= 1.0:
		_update_camera(progress)
	else:
		_finish_profiling()


# --- Setup / Restore ---

func _save_user_state() -> void:
	user_yaw = camera_rig.yaw
	user_pitch = camera_rig.pitch
	user_radius = camera_rig.orbit_radius


func _restore_user_state() -> void:
	camera_rig.yaw = user_yaw
	camera_rig.pitch = user_pitch
	camera_rig.orbit_radius = user_radius
	_apply_rotation(user_pitch, user_yaw)


func _set_benchmark_state() -> void:
	# instant teleport to start pose
	camera_rig.yaw = BENCHMARK_YAW
	camera_rig.pitch = BENCHMARK_PITCH
	camera_rig.orbit_radius = BENCHMARK_RADIUS
	_apply_rotation(BENCHMARK_PITCH, BENCHMARK_YAW)


func _apply_rotation(pitch: float, yaw: float) -> void:
	camera_rig.rotation = Vector3(pitch, yaw, 0)


func _warmup_frames(count: int) -> void:
	# let GPU settle (pipeline + clocks)
	for i in count:
		await get_tree().process_frame


# --- Benchmark update ---

func _update_camera(progress: float) -> void:
	var cycles := _get_cycles()

	# full rotation(s)
	var yaw = BENCHMARK_YAW + progress * TAU * cycles

	# vertical oscillation
	var pitch = BENCHMARK_PITCH + sin(progress * TAU * cycles) * 0.4

	# zoom in/out (use abs() to ensure it only zooms inward across multiple cycles)
	var radius = BENCHMARK_RADIUS - abs(sin(progress * PI * cycles)) * ZOOM_LEVEL

	camera_rig.yaw = yaw
	camera_rig.pitch = pitch
	camera_rig.orbit_radius = radius

	_apply_rotation(pitch, yaw)


# --- Helpers ---

func _get_duration() -> float:
	return 10.0 if benchmark_mode == BenchmarkMode.SHORT_10S else 60.0


func _get_cycles() -> float:
	return 1.0 if benchmark_mode == BenchmarkMode.SHORT_10S else 3.0


# --- Finish ---

func _finish_profiling() -> void:
	is_profiling = false

	_restore_user_state()

	var avg_frame_time_ms = (time_accum / frame_count) * 1000.0
	var avg_fps = frame_count / time_accum

	print("=== BENCHMARK DONE ===")
	print("Frames: ", frame_count)
	print("Avg FPS: ", avg_fps)
	print("Avg frame (ms): ", avg_frame_time_ms)
	print("======================\n")
