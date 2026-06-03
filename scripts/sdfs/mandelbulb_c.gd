class_name MandelbulbC
extends FractalData

var power: float = 8.0
var t: float = 0.75
var phase_angle: float = 0.8
var polar_angle: float = 0.0
const Q_PI = 0.78539816339

func _init():
	iterations = 20

func get_param_definitions() -> Array[Dictionary]:
	return [
		{"name": "Power", "min": 1.0, "max": 16.0, "step": 0.1, "default": 8.0},
		{"name": "Polar Angle", "min": 0.0, "max": Q_PI, "step": 0.01, "default": 0.0},
		{"name": "Offset", "min": 0.0, "max": 20.0, "step": 0.01, "default": 0.75},
		{"name": "Phase", "min": -3.14, "max": 3.14, "step": 0.01, "default": 0.8},
	]

func get_param_value(index: int) -> float:
	match index:
		0: return power
		1: return polar_angle
		2: return t
		3: return phase_angle
		_: return 0.0

func set_param_value(index: int, value: float) -> void:
	match index:
		0: power = value
		1: polar_angle = value
		2: t = value
		3: phase_angle = value

func get_shader_params() -> PackedFloat32Array:
	var arr = super.get_shader_params()
	arr[0] = power
	arr[1] = polar_angle
	arr[2] = t
	arr[3] = phase_angle
	return arr

func sdf(pos: Vector3) -> float:
	var z: Vector3 = pos
	var r: float = 0.0
	var dr: float = 1.0
	var power_minus_1: float = power - 1.0
	var cos_a: float = cos(phase_angle)
	var sin_a: float = sin(phase_angle)
	for i in range(iterations):
		r = z.length()
		if r > 2.0:
			break
		var inv_r: float = 1.0 / max(r, 1e-8)
		var theta: float = (acos(clamp(z.z * inv_r, -1.0, 1.0)) + polar_angle) * power
		var phi: float = atan2(z.y, z.x) * power
		var r_pow: float = pow(r, power_minus_1)
		dr = r_pow * power * dr + 1.0
		var zr: float = r_pow * r
		var sin_theta: float = sin(theta)
		z = zr * Vector3(sin_theta * cos(phi), sin_theta * sin(phi), cos(theta))
		var fi: float = float(i)
		z += 0.2 * Vector3(
			sin(0.5 * t + 0.1 * fi),
			cos(0.3 * t + 0.2 * fi),
			sin(0.4 * t + 0.15 * fi)
		)
		var old_x: float = z.x
		z.x = cos_a * old_x - sin_a * z.y
		z.y = sin_a * old_x + cos_a * z.y
		z += pos
	return 0.5 * log(r) * r / dr
