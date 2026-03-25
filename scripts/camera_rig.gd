extends Node3D

enum CameraMode { FPS, ORBIT }

@export var current_mode: CameraMode = CameraMode.ORBIT
@export var mouse_sensitivity := 0.003
@export var move_speed := 0.05
@export var orbit_radius := 1.5

@export var zoom_speed := 0.1
@export var min_orbit_radius := 0.8 # prevent camera clipping into center
@export var max_orbit_radius := 50.0

@onready var camera: Camera3D = $VirtualCamera

var yaw := 0.0
var pitch := 0.0


func _ready() -> void:
	# start with free cursor (UI interaction)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _input(event: InputEvent) -> void:
	# toggle between FPS and Orbit modes
	if event.is_action_pressed("switch_camera"):
		_switch_mode()

	# handle mouse clicks (capture + zoom)
	if event is InputEventMouseButton:
		_handle_mouse_buttons(event)

	# handle camera rotation
	if event is InputEventMouseMotion:
		_handle_rotation(event)


func _process(delta: float) -> void:
	# update based on active mode
	match current_mode:
		CameraMode.FPS:
			_process_fps(delta)
		CameraMode.ORBIT:
			_process_orbit(delta)


# --- Mode switching ---

func _switch_mode() -> void:
	if current_mode == CameraMode.ORBIT:
		current_mode = CameraMode.FPS
		
		# move rig to current camera world position
		global_position = camera.global_position
		
		# reset local offset to avoid jump
		camera.position = Vector3.ZERO
	else:
		current_mode = CameraMode.ORBIT
		
		# reset orbit center and FOV
		camera.fov = 75.0
		position = Vector3.ZERO


# --- Input handling ---

func _handle_mouse_buttons(event: InputEventMouseButton) -> void:
	# capture mouse only while rotating
	if event.button_index == MOUSE_BUTTON_RIGHT and current_mode == CameraMode.FPS:
		_set_mouse_capture(event.is_pressed())
	elif event.button_index == MOUSE_BUTTON_LEFT and current_mode == CameraMode.ORBIT:
		_set_mouse_capture(event.is_pressed())

	# scroll controls zoom (mode-dependent)
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_zoom(-1)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_zoom(1)


func _set_mouse_capture(active: bool) -> void:
	# lock/unlock cursor for continuous rotation
	Input.set_mouse_mode(
		Input.MOUSE_MODE_CAPTURED if active else Input.MOUSE_MODE_VISIBLE
	)


func _zoom(direction: int) -> void:
	if current_mode == CameraMode.ORBIT:
		# change physical distance from center
		orbit_radius = clamp(
			orbit_radius + direction * zoom_speed,
			min_orbit_radius,
			max_orbit_radius
		)
	else:
		# adjust camera FOV (optical zoom)
		camera.fov = clamp(camera.fov + direction, 10.0, 120.0)


func _handle_rotation(event: InputEventMouseMotion) -> void:
	# rotate only while correct mouse button is held
	var rotating := (
		(current_mode == CameraMode.FPS and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)) or
		(current_mode == CameraMode.ORBIT and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
	)

	if not rotating:
		return

	# update angles from mouse movement
	yaw -= event.relative.x * mouse_sensitivity
	pitch -= event.relative.y * mouse_sensitivity
	
	# limit vertical rotation to avoid flipping
	pitch = clamp(pitch, -PI / 2.1, PI / 2.1)

	# apply rotation to rig
	rotation = Vector3(pitch, yaw, 0)


# --- FPS mode ---

func _process_fps(delta: float) -> void:
	# move only while RMB is held (intentional control)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		
		# convert input into world direction
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

		# vertical movement (up/down)
		var vertical := 0.0
		if Input.is_action_pressed("move_up"): vertical += 1.0
		if Input.is_action_pressed("move_down"): vertical -= 1.0

		# apply movement
		position += (direction + Vector3.UP * vertical) * move_speed * delta

	# smoothly center camera on rig (removes drift)
	camera.position = camera.position.lerp(Vector3.ZERO, delta * 10.0)


# --- Orbit mode ---

func _process_orbit(delta: float) -> void:
	# keep camera at orbit radius behind rig
	var target := Vector3(0, 0, orbit_radius)
	camera.position = camera.position.lerp(target, delta * 10.0)
