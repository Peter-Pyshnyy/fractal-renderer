class_name MengerKoleidoscope
extends FractalData

var scale: float = 3.0
var alpha: float = 0.0
var beta: float = 0.0
var c: float = 1.0

func _init():
	iterations = 30

func get_param_definitions() -> Array[Dictionary]:
	return [
		{"name": "Scale", "min": 1.1, "max": 4.0, "step": 0.01, "default": 2.5},
		{"name": "Alpha", "min": 0.0, "max": 1.5, "step": 0.01, "default": 0.0},
		{"name": "Beta", "min": -1.0, "max": 1.0, "step": 0.01, "default": -0.75},
	]

func get_param_value(index: int) -> float:
	match index:
		0: return scale
		1: return alpha
		2: return beta
		_: return 0.0

func set_param_value(index: int, value: float) -> void:
	match index:
		0: scale = value
		1: alpha = value
		2: beta = value

func get_shader_params() -> PackedFloat32Array:
	var arr = super.get_shader_params()
	arr[0] = scale
	arr[1] = alpha
	arr[2] = beta
	return arr

func sdf(pos: Vector3) -> float:
	var z := pos
	var ca := cos(alpha)
	var sa := sin(alpha)
	var cb := cos(beta)
	var sb := sin(beta)
	var c := 0.8
	var bailout := 100.0
	var r2 := 0.0
	var n := 0
	for i in range(iterations):
		z = Vector3(ca * z.x - sa * z.z, z.y, sa * z.x + ca * z.z)
		z = z.abs()
		if z.x - z.y < 0.0: z = Vector3(z.y, z.x, z.z)
		if z.x - z.z < 0.0: z = Vector3(z.z, z.y, z.x)
		if z.y - z.z < 0.0: z = Vector3(z.x, z.z, z.y)
		z = Vector3(cb * z.x - sb * z.z, z.y, sb * z.x + cb * z.z)
		z.x = scale * (z.x - c) + c
		z.y = scale * (z.y - c) + c
		z.z = scale * z.z
		if z.z > c * (scale - 1.0) * 0.5: z.z -= c * (scale - 1.0)
		n += 1
		r2 = z.dot(z)
		if r2 > bailout: break
	return (sqrt(r2) - 2.0) * pow(scale, -float(n))
