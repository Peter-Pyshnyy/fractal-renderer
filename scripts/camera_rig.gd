extends Node3D

enum CameraMode { FPS, ORBIT }

const FPS_ZOOM_MIN := 0.000005
const FPS_ZOOM_MAX := 2.0

var current_mode: CameraMode = CameraMode.ORBIT
var mouse_sensitivity := 0.0015
var orbit_radius := 2.0

var max_orbit_radius := 3.0
var smooth_orbit := true

@onready var camera: Camera3D = $VirtualCamera
@onready var anchor: Node3D = $Anchor

var yaw := 0.0
var pitch := 0.0

var orbit_zoom_speed := 0.1
var orbit_zoom_factor := 0.2
var orbit_sensitivity := 0.003
var max_zoom_speed := 0.05

var fps_zoom_speed := 0.1
var fps_transition_factor := 1.35
var fps_scroll_factor := 0.175

var dist_to_sdf := 1.0
var is_moving := false
var motion_version := 0
signal camera_mode_changed(mode: int)

var _last_fractal_index := -1

# float64 position accumulators
var precise_x: float = 0.0
var precise_y: float = 0.0
var precise_z: float = 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	is_moving = true
	StateBus.render.changed.connect(_on_render_state_changed)
	StateBus.camera.changed.connect(_on_camera_state_changed)
	StateBus.scene.changed.connect(_on_scene_changed_fractal_check)
	_last_fractal_index = StateBus.scene.fractal_index
	_on_render_state_changed()
	_on_camera_state_changed()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_camera"):
		_switch_mode()

	if event.is_action_pressed("Screenshot"):
		var img = get_viewport().get_texture().get_image()
		img.save_png("user://screenshot.png")

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

func _switch_mode() -> void:
	is_moving = true
	if current_mode == CameraMode.ORBIT:
		current_mode = CameraMode.FPS
		global_position = camera.global_position
		anchor.position = Vector3.ZERO
		camera.position = Vector3.ZERO
		_sync_precise()
		_update_sdf_metrics()
		fps_zoom_speed = clamp(dist_to_sdf * fps_transition_factor, FPS_ZOOM_MIN, FPS_ZOOM_MAX)
	else:
		current_mode = CameraMode.ORBIT
		camera.fov = StateBus.camera.fov
		orbit_radius = 2.0
		position = Vector3.ZERO
		_sync_precise()
	camera_mode_changed.emit(current_mode)
	if StateBus.camera.mode != int(current_mode):
		StateBus.camera.mode = int(current_mode)

func _reset_position() -> void:
	yaw = 0.0
	pitch = 0.0
	rotation = Vector3.ZERO
	orbit_radius = 2.0
	orbit_zoom_speed = 0.1

	precise_x = 0.0
	precise_y = 0.0
	precise_z = orbit_radius if current_mode == CameraMode.FPS else 0.0
	position = Vector3(precise_x, precise_y, precise_z)

	_update_sdf_metrics()
	fps_zoom_speed = clamp(dist_to_sdf * fps_transition_factor, FPS_ZOOM_MIN, FPS_ZOOM_MAX)
	_mark_motion()

func _on_scene_changed_fractal_check() -> void:
	if StateBus.scene.fractal_index != _last_fractal_index:
		_last_fractal_index = StateBus.scene.fractal_index
		_reset_position()

func _sync_precise() -> void:
	precise_x = position.x
	precise_y = position.y
	precise_z = position.z

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

func _on_render_state_changed() -> void:
	smooth_orbit = not StateBus.render.vrs_enabled

func _on_camera_state_changed() -> void:
	mouse_sensitivity = StateBus.camera.mouse_sensitivity
	camera.fov = StateBus.camera.fov
	if StateBus.camera.mode != int(current_mode):
		_switch_mode()

func _update_sdf_metrics() -> void:
	if StateBus.scene.fractal_data == null: return
	dist_to_sdf = StateBus.scene.fractal_data.sdf(anchor.global_position)
	orbit_sensitivity = (dist_to_sdf * orbit_zoom_factor) * mouse_sensitivity

func _zoom(direction: int) -> void:
	if Input.is_action_pressed("fov_zoom"):
		camera.fov += direction * 2
		_mark_motion()
		return

	if current_mode == CameraMode.ORBIT:
		_update_sdf_metrics()
		_zoom_orbit(direction)
		_update_sdf_metrics()
		_mark_motion()
	else:
		_zoom_fps(direction)


func _zoom_fps(direction: int) -> void:
	if direction > 0:
		fps_zoom_speed = max(fps_zoom_speed * (1.0 - fps_scroll_factor), FPS_ZOOM_MIN)
	else:
		fps_zoom_speed = min(fps_zoom_speed * _get_reverse_scalar(fps_scroll_factor), FPS_ZOOM_MAX)

func _zoom_orbit(direction: int) -> void:
	if direction > 0:
		orbit_radius += orbit_zoom_speed

		var reverse_speed := _get_reverse_scalar(orbit_zoom_factor)
		orbit_zoom_speed = min(orbit_zoom_speed * reverse_speed, max_zoom_speed)

		orbit_radius = min(orbit_radius, max_orbit_radius)
	else:
		if dist_to_sdf < 0.0:
			orbit_zoom_speed *= 4.0
			return
		if dist_to_sdf < 0.000005:
			return
		else:
			orbit_zoom_speed = dist_to_sdf * orbit_zoom_factor
			orbit_radius -= orbit_zoom_speed


func _handle_rotation(event: InputEventMouseMotion) -> void:
	var rotating := (
		(current_mode == CameraMode.FPS and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)) or
		(current_mode == CameraMode.ORBIT and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
	)

	if not rotating:
		return

	_mark_motion()

	var sens = orbit_sensitivity if current_mode == CameraMode.ORBIT else mouse_sensitivity * 0.075

	yaw -= event.relative.x * sens
	pitch -= event.relative.y * sens
	pitch = clamp(pitch, -PI / 2.1, PI / 2.1)

	rotation = Vector3(pitch, yaw, 0)


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
			var step := fps_zoom_speed * delta
			precise_x += dir.x * step
			precise_y += dir.y * step
			precise_z += dir.z * step
			_mark_motion()

	position = Vector3(precise_x, precise_y, precise_z)
	camera.position = camera.position.lerp(Vector3.ZERO, delta * 10.0)

func _process_orbit(delta: float) -> void:
	var target := Vector3(0, 0, orbit_radius)

	anchor.position = target

	if smooth_orbit:
		camera.position = camera.position.lerp(target, delta * 15.0)
	else:
		camera.position = target


func _get_reverse_scalar(x: float) -> float:
	if x == 1.0: return 1.0
	return 1.0 / (1.0 - x)


func _mark_motion() -> void:
	is_moving = true
	motion_version += 1
