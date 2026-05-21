class_name QuaternionJuliaSet
extends FractalData

var power: float = 2.0
var c_real_x: float = -0.2
var c_real_y: float = 0.7
var c_real_z: float = 0.0
var c_real_w: float = 0.0
var c_dual_x: float = 0.2
var c_dual_y: float = 0.0
var c_dual_z: float = 0.0

func _init():
	iterations = 24

func get_param_definitions() -> Array[Dictionary]:
	return [
		{"name": "Power", "min": 2.0, "max": 2.0, "step": 1.0, "default": 2.0},
		{"name": "cReal X", "min": -1.5, "max": 1.5, "step": 0.01, "default": -0.2},
		{"name": "cReal Y", "min": -1.5, "max": 1.5, "step": 0.01, "default": 0.7},
		{"name": "cReal Z", "min": -1.5, "max": 1.5, "step": 0.01, "default": 0.0},
		{"name": "cReal W", "min": -1.5, "max": 1.5, "step": 0.01, "default": 0.0},
		{"name": "cDual X", "min": -1.5, "max": 1.5, "step": 0.01, "default": 0.2},
		{"name": "cDual Y", "min": -1.5, "max": 1.5, "step": 0.01, "default": 0.0},
		{"name": "cDual Z", "min": -1.5, "max": 1.5, "step": 0.01, "default": 0.0},
	]

func get_param_value(index: int) -> float:
	match index:
		0: return power
		1: return c_real_x
		2: return c_real_y
		3: return c_real_z
		4: return c_real_w
		5: return c_dual_x
		6: return c_dual_y
		7: return c_dual_z
		_: return 0.0

func set_param_value(index: int, value: float) -> void:
	match index:
		0: power = value
		1: c_real_x = value
		2: c_real_y = value
		3: c_real_z = value
		4: c_real_w = value
		5: c_dual_x = value
		6: c_dual_y = value
		7: c_dual_z = value

func get_shader_params() -> PackedFloat32Array:
	var arr = super.get_shader_params()
	arr[0] = power
	arr[1] = c_real_x
	arr[2] = c_real_y
	arr[3] = c_real_z
	arr[4] = c_real_w
	arr[5] = c_dual_x
	arr[6] = c_dual_y
	arr[7] = c_dual_z
	return arr

func _qsqr(q: Vector4) -> Vector4:
	return Vector4(
		q.x * q.x - q.y * q.y - q.z * q.z - q.w * q.w,
		2.0 * q.x * q.y,
		2.0 * q.x * q.z,
		2.0 * q.x * q.w
	)

func _qmul(a: Vector4, b: Vector4) -> Vector4:
	return Vector4(
		a.x * b.x - a.y * b.y - a.z * b.z - a.w * b.w,
		a.x * b.y + a.y * b.x + a.z * b.w - a.w * b.z,
		a.x * b.z - a.y * b.w + a.z * b.x + a.w * b.y,
		a.x * b.w + a.y * b.z - a.z * b.y + a.w * b.x
	)

func sdf(pos: Vector3) -> float:
	var za := Vector4(pos.x, pos.y, 0.0, 0.0)
	var zb := Vector4(pos.z, 0.0, 0.0, 0.0)
	var dza := Vector4(1.0, 0.0, 0.0, 0.0)
	var dzb := Vector4(1.0, 0.0, 0.0, 0.0)
	var c_real := Vector4(c_real_x, c_real_y, c_real_z, c_real_w)
	var c_dual := Vector4(c_dual_x, c_dual_y, c_dual_z, 0.0)

	var m2: float = za.dot(za) + zb.dot(zb)
	for i in range(iterations):
		dza = 2.0 * _qmul(za, dza)
		dzb = 2.0 * _qmul(zb, dzb)
		za = _qsqr(za) + c_real
		zb = _qsqr(zb) + c_dual
		m2 = za.dot(za) + zb.dot(zb)
		if m2 > 4.0:
			break

	var m: float = sqrt(m2)
	var dm: float = sqrt(dza.dot(dza) + dzb.dot(dzb))
	return 0.5 * log(m) * m / max(dm, 1e-8)
