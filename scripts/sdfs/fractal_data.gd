class_name FractalData
extends Resource

@export var iterations: int = 10

func get_shader_params() -> Array[float]:
	return [float(iterations), 0.0, 0.0]
