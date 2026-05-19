class_name FractalData
extends Resource

@export var iterations: int = 15

func get_shader_params() -> PackedFloat32Array:
	var arr := PackedFloat32Array()
	arr.resize(8)
	arr.fill(0.0)
	return arr

func get_param_definitions() -> Array[Dictionary]:
	return []

func get_param_value(_index: int) -> float:
	return 0.0

func set_param_value(_index: int, _value: float) -> void:
	pass
