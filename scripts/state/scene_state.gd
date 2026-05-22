class_name SceneStateR extends Resource

@export var fractal_data: FractalData:
	set(v): fractal_data = v; emit_changed()
@export var material: FractalMaterial:
	set(v): material = v; emit_changed()
@export var fractal_index: int = 0:
	set(v): fractal_index = v; emit_changed()
@export var light_dir: Vector3 = Vector3(1, 1, 1):
	set(v): light_dir = v; emit_changed()
@export_range(0.0, 1.0, 0.01) var metallic: float = 0.4:
	set(v): metallic = v; emit_changed()
@export_range(0.0, 1.0, 0.01) var roughness: float = 0.8:
	set(v): roughness = v; emit_changed()
@export var use_pbr: bool = true:
	set(v): use_pbr = v; emit_changed()
@export_range(0.1, 10.0, 0.01) var exposure: float = 3.0:
	set(v): exposure = v; emit_changed()
@export_range(0.1, 1.0, 0.01) var sdf_scalar: float = 0.75:
	set(v): sdf_scalar = v; emit_changed()
@export_range(0.1, 2.0, 0.01) var lod_scalar: float = 0.75:
	set(v): lod_scalar = v; emit_changed()
@export_range(1, 1000, 1) var max_steps: int = 250:
	set(v): max_steps = v; emit_changed()
@export var background_color: Color = Color(0.75, 0.75, 0.75, 1.0):
	set(v): background_color = v; emit_changed()

@export var color_mode: int = 2:
	set(v): color_mode = v; emit_changed()
@export var palette_type: int = 2:
	set(v): palette_type = v; emit_changed()
@export var iter_norm_a: float = 2.0:
	set(v): iter_norm_a = v; emit_changed()
@export var iter_norm_b: float = 5.0:
	set(v): iter_norm_b = v; emit_changed()
@export var iter_bw_preview: bool = false:
	set(v): iter_bw_preview = v; emit_changed()
@export var uniform_color: Color = Color(1.0, 1.0, 1.0, 1.0):
	set(v): uniform_color = v; emit_changed()
@export var trap_shape: int = 0:
	set(v): trap_shape = v; emit_changed()
@export var trap_position: Vector3 = Vector3.ZERO:
	set(v): trap_position = v; emit_changed()
@export var trap_size: float = 1.0:
	set(v): trap_size = v; emit_changed()
@export var trap_norm_a: float = 8.0:
	set(v): trap_norm_a = v; emit_changed()
@export var trap_norm_b: float = 0.22:
	set(v): trap_norm_b = v; emit_changed()
@export var trap_lp_power: float = 2.0:
	set(v): trap_lp_power = v; emit_changed()
@export var trap_bw_preview: bool = false:
	set(v): trap_bw_preview = v; emit_changed()
@export var sinmask_phase: float = 0.15:
	set(v): sinmask_phase = v; emit_changed()
@export var sinmask_amp: float = 3.5:
	set(v): sinmask_amp = v; emit_changed()
@export var sinmask_offset: float = 0.0:
	set(v): sinmask_offset = v; emit_changed()
@export var sinmask_blend: float = 1.0:
	set(v): sinmask_blend = v; emit_changed()
@export var hsv_cycles: float = 3.0:
	set(v): hsv_cycles = v; emit_changed()
@export var hsv_hue_offset: float = 8.5:
	set(v): hsv_hue_offset = v; emit_changed()
@export var hsv_blend: float = 0.5:
	set(v): hsv_blend = v; emit_changed()

func set_iterations(v: int) -> void:
	if fractal_data: fractal_data.iterations = v; emit_changed()

func set_param(i: int, v: float) -> void:
	if fractal_data: fractal_data.set_param_value(i, v); emit_changed()

func switch_fractal(idx: int, data: FractalData) -> void:
	fractal_index = idx
	fractal_data = data

func set_color_a(c: Color) -> void:
	material.color0 = c; emit_changed()

func set_color_b(c: Color) -> void:
	material.color1 = c; emit_changed()
