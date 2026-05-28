class_name CustomFractalData
extends FractalData

var sphere_radius: float = 1.5
var glsl_source: String = ""

func _init() -> void:
	iterations = 15
	var f := FileAccess.open("res://shaders/includes/sdfs/sdf_mandelbulb.gdshaderinc", FileAccess.READ)
	if f:
		glsl_source = f.get_as_text()

func get_shader_params() -> PackedFloat32Array:
	var arr := super.get_shader_params()
	arr[0] = 8.0
	return arr

func sdf(pos: Vector3) -> float:
	return pos.length() - sphere_radius
