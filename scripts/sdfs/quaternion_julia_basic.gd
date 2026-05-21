class_name QuaternionJuliaSetBasic
extends FractalData

var c_x: float = -0.2
var c_y: float = 0.7
var c_z: float = 0.0
var c_w: float = 0.0

func _init():
	iterations = 24

func get_param_definitions() -> Array[Dictionary]:
	return [
		{"name": "C X", "min": -1.5, "max": 1.5, "step": 0.01, "default": -0.2},
		{"name": "C Y", "min": -1.5, "max": 1.5, "step": 0.01, "default": 0.7},
		{"name": "C Z", "min": -1.5, "max": 1.5, "step": 0.01, "default": 0.0},
		{"name": "C W", "min": -1.5, "max": 1.5, "step": 0.01, "default": 0.0},
	]

func get_param_value(index: int) -> float:
	match index:
		0: return c_x
		1: return c_y
		2: return c_z
		3: return c_w
		_: return 0.0

func set_param_value(index: int, value: float) -> void:
	match index:
		0: c_x = value
		1: c_y = value
		2: c_z = value
		3: c_w = value

func get_shader_params() -> PackedFloat32Array:
	var arr = super.get_shader_params()
	arr[0] = c_x; arr[1] = c_y; arr[2] = c_z; arr[3] = c_w
	return arr

func _qsqr(a: Vector4) -> Vector4:
	return Vector4(a.x*a.x - a.y*a.y - a.z*a.z - a.w*a.w, 2.0*a.x*a.y, 2.0*a.x*a.z, 2.0*a.x*a.w)

func sdf(pos: Vector3) -> float:
	var c := Vector4(c_x, c_y, c_z, c_w)
	var z := Vector4(pos.x, pos.y, pos.z, 0.0)
	var md2 := 1.0
	var mz2 := z.dot(z)
	for i in range(iterations):
		md2 *= 4.0 * mz2
		z = _qsqr(z) + c
		mz2 = z.dot(z)
		if mz2 > 4.0: break
	return 0.25 * sqrt(mz2 / md2) * log(mz2)
