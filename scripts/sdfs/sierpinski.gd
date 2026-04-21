class_name Sierpinski
extends FractalData

@export var scale: float = 2.0
@export var offset: float = 1.0
@export var angle_x: float = 0.0
@export var angle_y: float = 0.0

func get_shader_params() -> Array[float]:
	# iterations first, then scale, offset, and the two fold-rotation angles
	return [float(iterations), scale, offset, angle_x]

func sdf(pos: Vector3) -> float:
	var z: Vector3 = pos
	var cx: float = cos(angle_x)
	var sx: float = sin(angle_x)
	var cy: float = cos(angle_y)
	var sy: float = sin(angle_y)

	for i in range(iterations):
		# rotation around X (y, z plane)
		var ry: float = cx * z.y - sx * z.z
		var rz: float = sx * z.y + cx * z.z
		z.y = ry
		z.z = rz

		# Sierpinski tetrahedral folds
		if z.x + z.y < 0.0:
			var tx: float = -z.y
			z.y = -z.x
			z.x = tx
		if z.x + z.z < 0.0:
			var tx2: float = -z.z
			z.z = -z.x
			z.x = tx2
		if z.y + z.z < 0.0:
			var ty: float = -z.z
			z.z = -z.y
			z.y = ty

		# rotation around Y (x, z plane)
		var rx2: float = cy * z.x + sy * z.z
		var rz2: float = -sy * z.x + cy * z.z
		z.x = rx2
		z.z = rz2

		# scale toward vertex and translate
		z = z * scale - Vector3.ONE * (offset * (scale - 1.0))

	# IFS distance estimate
	return z.length() * pow(scale, -float(iterations))
