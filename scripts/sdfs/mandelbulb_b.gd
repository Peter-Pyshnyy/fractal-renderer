class_name MandelbulbB
extends FractalData

var power: float = 8.0
var warp_time: float = 1.0
var warp_phase: float = 1.0

func _init():
	iterations = 15

func get_param_definitions() -> Array[Dictionary]:
	return [
		{"name": "Power", "min": 1.0, "max": 16.0, "step": 0.1, "default": 2.0},
	]

func get_param_value(index: int) -> float:
	match index:
		0: return power
		_: return 0.0

func set_param_value(index: int, value: float) -> void:
	match index:
		0: power = value

func get_shader_params() -> PackedFloat32Array:
	var arr = super.get_shader_params()
	arr[0] = power
	return arr

func sdf(pos: Vector3) -> float:
	var z: Vector3 = pos
	var r: float = 0.0
	var dr: float = 1.0
	var power_minus_1: float = power - 1.0

	for i in range(iterations):
		r = z.length()
		if r > 2.0:
			break
		var inv_r: float = 1.0 / max(r, 1e-6)
		var theta: float = asin(z.z * inv_r)
		var phi: float = atan2(z.y, z.x)
		var r_pow: float = pow(r, power_minus_1)
		dr = r_pow * power * dr + 1.0
		var zr: float = r_pow * r
		theta *= power
		phi *= power
		z = zr * Vector3(cos(theta) * cos(phi), cos(theta) * sin(phi), sin(theta)) + pos

	return 0.5 * log(r) * r / dr
