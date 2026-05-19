class_name SierpinskiTetrahedron
extends FractalData

var scale: float
var alpha: float
var beta: float

func _ready():
	iterations = 40
	scale = 2.0
	alpha = 0.0
	beta = 0.0

func get_shader_params() -> PackedFloat32Array:
	var arr = super.get_shader_params() 
	arr[0] = scale
	arr[1] = alpha
	arr[2] = beta
	return arr

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
