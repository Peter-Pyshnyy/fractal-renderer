class_name RenderState extends Resource

@export var vrs_enabled: bool = true:
	set(v): vrs_enabled = v; emit_changed()
@export_range(1, 8, 1) var vrs_scale: int = 2:
	set(v): vrs_scale = v; emit_changed()
