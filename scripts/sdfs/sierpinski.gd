class_name SierpinskiTetrahedron
extends FractalData

@export var scale: float = 2.0
@export var alpha: float = 0.0
@export var beta: float = 0.0

func get_shader_params() -> Array[float]:
	return [float(iterations), scale, alpha, beta]

func sdf(pos: Vector3) -> float:
	var z: Vector3 = pos
	var offset: float = 1.0
	var ca: float = cos(alpha)
	var sa: float = sin(alpha)
	var cb: float = cos(beta)
	var sb: float = sin(beta)

	for i in range(iterations):
		if z.x + z.y < 0.0:
			var t1: float = -z.y
			z.y = -z.x
			z.x = t1
		if z.x + z.z < 0.0:
			var t2: float = -z.z
			z.z = -z.x
			z.x = t2
		if z.y + z.z < 0.0:
			var t3: float = -z.z
			z.z = -z.y
			z.y = t3

		z = z * scale - Vector3.ONE * (offset * (scale - 1.0))

		var rx: float = ca * z.x - sa * z.z
		var rz: float = sa * z.x + ca * z.z
		z.x = rx
		z.z = rz

		var ry: float = cb * z.y - sb * z.z
		var rz2: float = sb * z.y + cb * z.z
		z.y = ry
		z.z = rz2

	return z.length() * pow(scale, -float(iterations))
