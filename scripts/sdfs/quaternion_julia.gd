class_name QuaternionJuliaSet
extends FractalData

var c_real_x: float = -0.2
var c_real_y: float = 0.7
var c_real_z: float = 0.0
var c_real_w: float = 0.0
var c_dual_x: float = 0.2
var c_dual_y: float = 0.0
var c_dual_z: float = 0.0
var c_dual_w: float = 0.0

func _init():
	iterations = 24

func get_param_definitions() -> Array[Dictionary]:
	return [
		{"name": "cReal X", "min": -1.5, "max": 1.5, "step": 0.01, "default": -0.2},
		{"name": "cReal Y", "min": -1.5, "max": 1.5, "step": 0.01, "default": 0.53},
		{"name": "cReal Z", "min": -1.5, "max": 1.5, "step": 0.01, "default": -0.39},
		{"name": "cReal W", "min": -1.5, "max": 1.5, "step": 0.01, "default": -0.57},
		{"name": "cDual X", "min": -1.5, "max": 1.5, "step": 0.01, "default": 0.35},
		{"name": "cDual Y", "min": -1.5, "max": 1.5, "step": 0.01, "default": -0.1},
		{"name": "cDual Z", "min": -1.5, "max": 1.5, "step": 0.01, "default": 0.0},
		{"name": "cDual W", "min": -1.5, "max": 1.5, "step": 0.01, "default": 0.0},
	]

func get_param_value(index: int) -> float:
	match index:
		0: return c_real_x
		1: return c_real_y
		2: return c_real_z
		3: return c_real_w
		4: return c_dual_x
		5: return c_dual_y
		6: return c_dual_z
		7: return c_dual_w
		_: return 0.0

func set_param_value(index: int, value: float) -> void:
	match index:
		0: c_real_x = value
		1: c_real_y = value
		2: c_real_z = value
		3: c_real_w = value
		4: c_dual_x = value
		5: c_dual_y = value
		6: c_dual_z = value
		7: c_dual_w = value

func get_shader_params() -> PackedFloat32Array:
	var arr = super.get_shader_params()
	arr[0] = c_real_x
	arr[1] = c_real_y
	arr[2] = c_real_z
	arr[3] = c_real_w
	arr[4] = c_dual_x
	arr[5] = c_dual_y
	arr[6] = c_dual_z
	arr[7] = c_dual_w
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
	# 1. Initialization Mismatches Fixed:
	# GLSL uses: za = vec4(pos, 0.0) -> (pos.x, pos.y, pos.z, 0.0)
	#            zb = vec4(0.0) -> (0.0, 0.0, 0.0, 0.0)
	var za := Vector4(pos.x, pos.y, pos.z, 0.0)
	var zb := Vector4(0.0, 0.0, 0.0, 0.0)
	
	# GLSL uses: dza = (1.0, 0.0, 0.0, 0.0), dzb = (0.0, 0.0, 0.0, 0.0)
	var dza := Vector4(1.0, 0.0, 0.0, 0.0)
	var dzb := Vector4(0.0, 0.0, 0.0, 0.0)
	
	var c_real := Vector4(c_real_x, c_real_y, c_real_z, c_real_w)
	var c_dual := Vector4(c_dual_x, c_dual_y, c_dual_z, c_dual_w)

	var m2: float = za.dot(za) + zb.dot(zb)
	
	for i in range(iterations):
		var dza_new := 2.0 * _qmul(za, dza)
		var dzb_new := 2.0 * (_qmul(za, dzb) + _qmul(zb, dza))
		
		var za_new := _qsqr(za) + c_real
		var zb_new := _qmul(za, zb) + _qmul(zb, za) + c_dual
		
		dza = dza_new
		dzb = dzb_new
		za = za_new
		zb = zb_new
		
		m2 = za.dot(za) + zb.dot(zb)
		if m2 > 10000.0:
			break

	var m: float = sqrt(m2)
	var dm: float = sqrt(dza.dot(dza) + dzb.dot(dzb))
	return 0.5 * log(m) * m / max(dm, 1e-8)
