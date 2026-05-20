class_name CameraInputState extends Resource

@export_range(0.001, 0.1, 0.001) var mouse_sensitivity: float = 0.03:
	set(v): mouse_sensitivity = v; emit_changed()
@export var mode: int = 1:  # 0 FPS, 1 Orbit
	set(v): mode = v; emit_changed()
