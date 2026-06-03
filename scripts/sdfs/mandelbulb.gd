class_name MandelbulbA
extends FractalData

var power: float = 8.0
var polar_angle: float = 0.0

const Q_PI = 0.78539816339

func _init():
	iterations = 15

func get_param_definitions() -> Array[Dictionary]:
	return [
		{"name": "Power", "min": 1.0, "max": 16.0, "step": 0.1, "default": 8.0},
		{"name": "Polar Angle", "min": 0.0, "max": Q_PI, "step": 0.01, "default": 0.0},
	]

func get_param_value(index: int) -> float:
	match index:
		0: return power
		1: return polar_angle
		_: return 0.0

func set_param_value(index: int, value: float) -> void:
	match index:
		0: power = value
		1: polar_angle = value

func get_shader_params() -> PackedFloat32Array:
	var arr = super.get_shader_params()
	arr[0] = power   # scene.params.param0
	arr[1] = polar_angle
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
		var theta: float = (acos(clamp(z.z * inv_r, -1.0, 1.0)) + polar_angle) * power
		var phi: float = atan2(z.y, z.x) * power
		var r_pow: float = pow(r, power_minus_1)
		dr = r_pow * power * dr + 1.0
		var zr: float = r_pow * r
		var sin_theta: float = sin(theta)
		z = zr * Vector3(
			sin_theta * cos(phi),
			sin_theta * sin(phi),
			cos(theta)
		) + pos
	return 0.5 * log(r) * r / dr
