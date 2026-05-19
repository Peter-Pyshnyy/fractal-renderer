class_name FractalData
extends Resource

@export var iterations: int = 15

func get_shader_params() -> PackedFloat32Array:
	var arr := PackedFloat32Array()
	arr.resize(8)
	arr.fill(0.0)
	return arr
