class_name Mandelbox
extends FractalData

var scale: float = 2.0
var fixed_radius: float = 1.0
var min_radius: float = 0.5

func _init():
	iterations = 20

func get_param_definitions() -> Array[Dictionary]:
	return [
		{"name": "Scale", "min": -4.0, "max": 4.0, "step": 0.01, "default": 2.0},
		{"name": "Fixed Radius", "min": 0.1, "max": 4.0, "step": 0.01, "default": 1.0},
		{"name": "Min Radius", "min": 0.01, "max": 2.0, "step": 0.01, "default": 0.5},
	]

func get_param_value(index: int) -> float:
	match index:
		0: return scale
		1: return fixed_radius
		2: return min_radius
		_: return 0.0

func set_param_value(index: int, value: float) -> void:
	match index:
		0: scale = value
		1: fixed_radius = value
		2: min_radius = value

func get_shader_params() -> PackedFloat32Array:
	var arr = super.get_shader_params()
	arr[0] = scale
	arr[1] = fixed_radius
	arr[2] = min_radius
	return arr

func sdf(pos: Vector3) -> float:
	var z := pos
	var c := pos
	var f_r2 := fixed_radius * fixed_radius
	var m_r2 := min_radius * min_radius
	var de_factor := scale
	for i in range(iterations):
		if z.x > 1.0: z.x = 2.0 - z.x
		elif z.x < -1.0: z.x = -2.0 - z.x
		if z.y > 1.0: z.y = 2.0 - z.y
		elif z.y < -1.0: z.y = -2.0 - z.y
		if z.z > 1.0: z.z = 2.0 - z.z
		elif z.z < -1.0: z.z = -2.0 - z.z
		var r2 := z.dot(z)
		if r2 < m_r2:
			var s := f_r2 / m_r2
			z *= s
			de_factor *= s
		elif r2 < f_r2:
			var s2 := f_r2 / r2
			z *= s2
			de_factor *= s2
		z = z * scale + c
		de_factor *= scale
	return z.length() / abs(de_factor)
