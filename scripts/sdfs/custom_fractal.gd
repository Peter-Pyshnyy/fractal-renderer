class_name CustomFractalData
extends FractalData

var sphere_radius: float = 1.15
var glsl_source: String = ""
var fractal_params: Array[float] = [8.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

func _init() -> void:
	iterations = 15
	glsl_source = "float sdf(vec3 pos) {
	vec3 z = pos;
	float r = 1.2;
	float dr = 1.0;
	float power = scene.params.param0;
	float powerMinus1 = power - 1.0;

	for (int i = 0; i < scene.iterations; i++) {
		r = length(z);
		if (r > 2.0) break;

		float invR = 1.0 / max(r, 1e-8);
		float theta = acos(clamp(z.z * invR, -1.0, 1.0));
		float phi = atan(z.y, z.x);
		float rPow = pow(r, powerMinus1);
		dr = rPow * power * dr + 1.0;
		float zr = rPow * r;
		theta *= power;
		phi *= power;
		float sinTheta = sin(theta);
		z = zr * vec3(sinTheta * cos(phi), sinTheta * sin(phi), cos(theta)) + pos;
	}
	return 0.5 * log(r) * r / dr;
}

float sdf_with_color(vec3 pos, out float trap, out int iter_count) {
	vec3 z = pos;
	float r = 1.2;
	float dr = 1.0;
	float power = scene.params.param0;
	float powerMinus1 = power - 1.0;

	trap = 1e6;
	iter_count = scene.iterations;

	for (int i = 0; i < scene.iterations; i++) {
		r = length(z);
		if (r > 2.0) { iter_count = i; break; }

		float invR = 1.0 / max(r, 1e-8);
		float theta = acos(clamp(z.z * invR, -1.0, 1.0));
		float phi = atan(z.y, z.x);
		float rPow = pow(r, powerMinus1);
		dr = rPow * power * dr + 1.0;
		float zr = rPow * r;
		theta *= power;
		phi *= power;
		float sinTheta = sin(theta);
		z = zr * vec3(sinTheta * cos(phi), sinTheta * sin(phi), cos(theta)) + pos;

		trap = min(get_trap_distance(z) / r, trap);
	}
	return 0.5 * log(r) * r / dr;
}"

func get_shader_params() -> PackedFloat32Array:
	var arr := PackedFloat32Array()
	arr.resize(8)
	for i in 8:
		arr[i] = fractal_params[i]
	return arr

func sdf(pos: Vector3) -> float:
	return pos.length() - sphere_radius
