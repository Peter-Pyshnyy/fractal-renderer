extends Node3D

enum CameraMode { FPS, ORBIT }

@export var current_mode: CameraMode = CameraMode.ORBIT
@export var mouse_sensitivity := 0.03
@export var orbit_radius := 1.5

@export var zoom_speed := 0.1
@export var min_orbit_radius := 0.8
@export var max_orbit_radius := 4.0

@onready var camera: Camera3D = $VirtualCamera
@onready var anchor: Node3D = $Anchor

var yaw := 0.0
var pitch := 0.0

# dynamic orbit tuning
var orbit_zoom_speed := 0.1
var orbit_zoom_factor := 0.2
var orbit_sensitivity := 0.003
var max_zoom_speed := 0.05

var fps_zoom_speed := 0.1
var fps_zoom_factor := 0.33
var fps_move_speed := 0.05
var fps_zoom_lock := false

var dist_to_sdf := 1.0
var is_moving := false
var motion_version := 0

# float64 position accumulators
var precise_x: float = 0.0
var precise_y: float = 0.0
var precise_z: float = 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_camera"):
		_switch_mode()

	if event is InputEventMouseButton:
		_handle_mouse_buttons(event)

	if event is InputEventMouseMotion:
		_handle_rotation(event)


func _process(delta: float) -> void:
	match current_mode:
		CameraMode.FPS:
			_process_fps(delta)
		CameraMode.ORBIT:
			_process_orbit(delta)


# --- Mode switching ---

func _switch_mode() -> void:
	if current_mode == CameraMode.ORBIT:
		current_mode = CameraMode.FPS
		global_position = camera.global_position
		anchor.position = Vector3.ZERO
		camera.position = Vector3.ZERO
		_sync_precise()
	else:
		current_mode = CameraMode.ORBIT
		camera.fov = 75.0
		position = Vector3.ZERO
		_sync_precise()


# --- Precise position sync ---

func _sync_precise() -> void:
	precise_x = position.x
	precise_y = position.y
	precise_z = position.z


# --- Input handling ---

func _handle_mouse_buttons(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_RIGHT and current_mode == CameraMode.FPS:
		_set_mouse_capture(event.is_pressed())
	elif event.button_index == MOUSE_BUTTON_LEFT and current_mode == CameraMode.ORBIT:
		_set_mouse_capture(event.is_pressed())

	if event.button_index == MOUSE_BUTTON_LEFT and current_mode == CameraMode.ORBIT:
		_update_sdf_metrics()

	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_zoom(-1)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_zoom(1)


func _set_mouse_capture(active: bool) -> void:
	Input.set_mouse_mode(
		Input.MOUSE_MODE_CAPTURED if active else Input.MOUSE_MODE_VISIBLE
	)


# --- SDF helpers ---

func _update_sdf_metrics() -> void:
	dist_to_sdf = Global.g_fractal.sdf(anchor.global_position)
	orbit_sensitivity = (dist_to_sdf * orbit_zoom_factor) * mouse_sensitivity
	fps_move_speed = dist_to_sdf * fps_zoom_factor * 10.0

	if fps_move_speed < 0.000045:
		fps_move_speed = 0.000045
		fps_zoom_lock = true
	else:
		fps_zoom_lock = false


# --- Zoom ---

func _zoom(direction: int) -> void:
	_mark_motion()
	_update_sdf_metrics()

	if current_mode != CameraMode.ORBIT:
		_zoom_fps(direction)
	else:
		_zoom_orbit(direction)

	_update_sdf_metrics()


# --- FPS zoom ---

func _zoom_fps(direction: int) -> void:
	if dist_to_sdf < 0.0:
		return

	var forward := -camera.global_basis.z

	if direction < 0:
		if fps_zoom_lock: return
		fps_zoom_speed = min(dist_to_sdf * fps_zoom_factor, max_zoom_speed)
		precise_x += forward.x * fps_zoom_speed
		precise_y += forward.y * fps_zoom_speed
		precise_z += forward.z * fps_zoom_speed
	else:
		var reverse_speed := _get_reverse_scalar(fps_zoom_factor)
		fps_zoom_speed = min(fps_zoom_speed * reverse_speed, max_zoom_speed)
		precise_x -= forward.x * fps_zoom_speed
		precise_y -= forward.y * fps_zoom_speed
		precise_z -= forward.z * fps_zoom_speed

	position = Vector3(precise_x, precise_y, precise_z)


# --- Orbit zoom ---

func _zoom_orbit(direction: int) -> void:
	if direction > 0:
		orbit_radius += orbit_zoom_speed

		var reverse_speed := _get_reverse_scalar(orbit_zoom_factor)
		orbit_zoom_speed = min(orbit_zoom_speed * reverse_speed, max_zoom_speed)

		orbit_radius = min(orbit_radius, max_orbit_radius)
	else:
		if dist_to_sdf > 0.0:
			orbit_zoom_speed = dist_to_sdf * orbit_zoom_factor
			orbit_radius -= orbit_zoom_speed
			orbit_radius = max(orbit_radius, min_orbit_radius)
		else:
			orbit_zoom_speed *= 4.0


# --- Rotation ---

func _handle_rotation(event: InputEventMouseMotion) -> void:
	var rotating := (
		(current_mode == CameraMode.FPS and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)) or
		(current_mode == CameraMode.ORBIT and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
	)

	if not rotating:
		return

	_mark_motion()

	var sens = orbit_sensitivity if current_mode == CameraMode.ORBIT else mouse_sensitivity * 0.05

	yaw -= event.relative.x * sens
	pitch -= event.relative.y * sens
	pitch = clamp(pitch, -PI / 2.1, PI / 2.1)

	rotation = Vector3(pitch, yaw, 0)


# --- FPS mode ---

func _process_fps(delta: float) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		var dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

		var vertical := 0.0
		if Input.is_action_pressed("move_up"): vertical += 1.0
		if Input.is_action_pressed("move_down"): vertical -= 1.0
		dir += Vector3.UP * vertical
		dir = dir.normalized()

		if not dir.is_equal_approx(Vector3.ZERO):
			#if fps_zoom_lock: return

			var step := fps_move_speed * delta
			precise_x += dir.x * step
			precise_y += dir.y * step
			precise_z += dir.z * step
			_mark_motion()

	# single float32 write per frame
	position = Vector3(precise_x, precise_y, precise_z)
	camera.position = camera.position.lerp(Vector3.ZERO, delta * 10.0)


# --- Orbit mode ---

func _process_orbit(delta: float) -> void:
	var target := Vector3(0, 0, orbit_radius)

	anchor.position = target
	camera.position = camera.position.lerp(target, delta * 15.0)


func _get_reverse_scalar(x: float) -> float:
	if x == 1.0: return 1.0
	return 1.0 / (1.0 - x)


func _mark_motion() -> void:
	is_moving = true
	motion_version += 1
