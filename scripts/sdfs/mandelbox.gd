class_name Mandelbox
extends FractalData

var scale: float = 2.0
var fixed_radius: float = 1.0
var min_radius: float = 0.5

func _init():
	iterations = 30

func get_param_definitions() -> Array[Dictionary]:
	return [
		{"name": "Scale", "min": -2.75, "max": -1.75, "step": 0.01, "default": -2.0},
		{"name": "Fixed Radius", "min": 0.5, "max": 1.75, "step": 0.01, "default": 0.9},
		{"name": "Min Radius", "min": 0.01, "max": 1.0, "step": 0.01, "default": 0.5},
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
	var limit := 0.4
	
	for i in range(iterations):
		# Parameterized Box Fold
		if z.x > limit: z.x = 2.0 * limit - z.x
		elif z.x < -limit: z.x = -2.0 * limit - z.x
		
		if z.y > limit: z.y = 2.0 * limit - z.y
		elif z.y < -limit: z.y = -2.0 * limit - z.y
		
		if z.z > limit: z.z = 2.0 * limit - z.z
		elif z.z < -limit: z.z = -2.0 * limit - z.z
		
		# Sphere Fold
		var r2 := z.dot(z)
		if r2 < m_r2:
			var s := f_r2 / m_r2
			z *= s
			de_factor *= s
		elif r2 < f_r2:
			var s2 := f_r2 / r2
			z *= s2
			de_factor *= s2
			
		# Scale and Shift
		z = z * scale + c
		de_factor *= scale
		
	return z.length() / abs(de_factor)
