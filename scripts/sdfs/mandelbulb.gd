class_name Mandelbulb 
extends FractalData

@export var power: float = 8.0

func get_shader_params() -> Array[float]:
	# На перше місце ставимо power, далі базові параметри
	return [float(iterations), power, 0.0, 0.0]
	
func sdf(pos: Vector3) -> float:
	var z: Vector3 = pos
	var r: float = 0.0
	var dr: float = 1.0

	var power_minus_1: float = power - 1.0

	for i in range(iterations):
		r = z.length()
		if r > 2.0:
			break  # escape radius

		# avoid division instability near zero
		var inv_r: float = 1.0 / max(r, 1e-6)

		# spherical coordinates
		var theta: float = acos(z.z * inv_r)
		var phi: float = atan2(z.y, z.x)

		# derivative update
		var r_pow: float = pow(r, power_minus_1)
		dr = r_pow * power * dr + 1.0

		# scale + rotate
		var zr: float = r_pow * r  # == pow(r, power)
		theta *= power
		phi *= power

		# back to cartesian
		var sin_theta: float = sin(theta)
		z = zr * Vector3(
			sin_theta * cos(phi),
			sin_theta * sin(phi),
			cos(theta)
		) + pos

	# distance estimation
	return 0.5 * log(r) * r / dr
