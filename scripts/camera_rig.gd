extends Node3D

enum CameraMode { FPS, ORBIT }

@export var current_mode: CameraMode = CameraMode.ORBIT
@export var mouse_sensitivity := 0.03
@export var move_speed := 0.05
@export var orbit_radius := 1.5

@export var zoom_speed := 0.1
@export var min_orbit_radius := 0.8 # prevent clipping into center
@export var max_orbit_radius := 4.0

@onready var camera: Camera3D = $VirtualCamera
@onready var anchor: Node3D = $Anchor

var yaw := 0.0
var pitch := 0.0

# dynamic orbit tuning
var orbit_zoom_speed := 0.1
var orbit_zoom_factor := 0.2
var orbit_sensitivity := 0.003
var max_zoom_speed := 0.1

var fps_zoom_speed := 0.1
var fps_zoom_factor := 0.333

var dist_to_sdf := 1.0
var is_moving := false


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
		# move rig to camera
		global_position = camera.global_position
		anchor.position = Vector3.ZERO
		camera.position = Vector3.ZERO
	else:
		current_mode = CameraMode.ORBIT

		# reset orbit center
		camera.fov = 75.0
		#anchor.global_position = global_position
		#camera.global_position = global_position
		position = Vector3.ZERO


# --- Input handling ---

func _handle_mouse_buttons(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_RIGHT and current_mode == CameraMode.FPS:
		_set_mouse_capture(event.is_pressed())
	elif event.button_index == MOUSE_BUTTON_LEFT and current_mode == CameraMode.ORBIT:
		_set_mouse_capture(event.is_pressed())

	# update sensitivity once after interaction
	if event.button_index == MOUSE_BUTTON_LEFT and event.is_released() and current_mode == CameraMode.ORBIT:
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
	# expensive → keep centralized
	dist_to_sdf = SDF.sdf(anchor.global_position)
	orbit_sensitivity = (dist_to_sdf * orbit_zoom_factor) * mouse_sensitivity


# --- Zoom ---

func _zoom(direction: int) -> void:
	is_moving = true
	_update_sdf_metrics()

	if current_mode != CameraMode.ORBIT:
		#camera.fov = clamp(camera.fov + direction, 10.0, 120.0)
		if dist_to_sdf < 0.0: return
		if direction > 0:
			fps_zoom_speed = dist_to_sdf * fps_zoom_factor
			position += camera.global_basis.z * fps_zoom_speed
		else:
			position -= camera.global_basis.z * fps_zoom_speed
		return

	if direction > 0:
		# zoom out (accelerates)
		orbit_radius += orbit_zoom_speed
		var reverse_speed = _get_reverse_scalar(orbit_zoom_factor)
		orbit_zoom_speed = min(orbit_zoom_speed * reverse_speed, max_zoom_speed)
		orbit_radius = min(orbit_radius, max_orbit_radius)

	else:
		# zoom in (adaptive)
		if dist_to_sdf > 0.0:
			orbit_zoom_speed = dist_to_sdf * orbit_zoom_factor
			orbit_radius -= orbit_zoom_speed
		else:
			# escape if inside sdf
			orbit_zoom_speed *= 4.0

	# refresh after movement
	_update_sdf_metrics()


# --- Rotation ---

func _handle_rotation(event: InputEventMouseMotion) -> void:
	var rotating := (
		(current_mode == CameraMode.FPS and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)) or
		(current_mode == CameraMode.ORBIT and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
	)

	if not rotating:
		return

	is_moving = true

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

		position += (dir + Vector3.UP * vertical) * move_speed * delta

	# keep camera centered
	camera.position = camera.position.lerp(Vector3.ZERO, delta * 10.0)


# --- Orbit mode ---

func _process_orbit(delta: float) -> void:
	# target offset from pivot
	var target := Vector3(0, 0, orbit_radius)

	anchor.position = target
	camera.position = camera.position.lerp(target, delta * 15.0)

func _get_reverse_scalar(x: float) -> float:
	if x == 1.0: return 1.0
	return 1.0 / (1.0 - x)
