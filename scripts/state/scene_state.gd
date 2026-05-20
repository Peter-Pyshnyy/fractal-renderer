class_name SceneStateR extends Resource

@export var fractal_data: FractalData:
	set(v): fractal_data = v; emit_changed()
@export var material: FractalMaterial:
	set(v): material = v; emit_changed()
@export var fractal_index: int = 0:
	set(v): fractal_index = v; emit_changed()
@export var light_dir: Vector3 = Vector3(1, 1, 1):
	set(v): light_dir = v; emit_changed()
@export_range(0.0, 1.0, 0.01) var metallic: float = 0.75:
	set(v): metallic = v; emit_changed()
@export_range(0.0, 1.0, 0.01) var roughness: float = 0.5:
	set(v): roughness = v; emit_changed()
@export var use_pbr: bool = true:
	set(v): use_pbr = v; emit_changed()

func set_iterations(v: int) -> void:
	if fractal_data: fractal_data.iterations = v; emit_changed()

func set_param(i: int, v: float) -> void:
	if fractal_data: fractal_data.set_param_value(i, v); emit_changed()

func switch_fractal(idx: int, data: FractalData) -> void:
	fractal_index = idx
	fractal_data = data
