class_name ShaderAssembler

const _HEADER := """#version 450
layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

layout(set = 0, binding = 0, rgba32f) uniform writeonly image2D output_image;
layout(set = 0, binding = 2, rgba32f) uniform readonly image2D history_image;
"""

const _MAIN := """void main() {
	ivec2 base_coord = ivec2(gl_GlobalInvocationID.xy) * resolution_scale;
	ivec2 image_size = imageSize(output_image);
	if (base_coord.x >= image_size.x || base_coord.y >= image_size.y) return;

	vec2 offset = vec2(float(resolution_scale) * 0.5);
	vec2 uv = (vec2(base_coord) + offset + jitter) / vec2(image_size);
	uv.y = 1.0 - uv.y;

	vec3 rayDir = getRayDirection(cam.resolution, uv);
	vec3 color = raymarch_AR(rayDir);

	for (int y = 0; y < resolution_scale; y++) {
		for (int x = 0; x < resolution_scale; x++) {
			ivec2 write_coord = base_coord + ivec2(x, y);
			if (write_coord.x < image_size.x && write_coord.y < image_size.y) {
				float exposure = scene.exposure;
				vec3 current_color;
				if (scene.use_pbr == 1) {
					current_color = color * exposure;
					current_color = current_color / (current_color + 1.0);
				} else {
					current_color = color;
				}
				vec3 history_gamma = imageLoad(history_image, write_coord).rgb;
				vec3 history_linear = pow(max(history_gamma, vec3(0.0)), vec3(2.2));
				if (any(isnan(history_linear))) history_linear = current_color;
				vec3 blended_linear = mix(current_color, history_linear, history_blend);
				vec3 final_color = pow(max(blended_linear, vec3(0.0)), vec3(1.0 / 2.2));
				imageStore(output_image, write_coord, vec4(final_color, 1.0));
			}
		}
	}
}
"""

static func build(sdf_source: String) -> String:
	return (
		_HEADER + "\n" +
		_read("res://shaders/includes/shared_data.gdshaderinc") + "\n" +
		_read("res://shaders/includes/color/orbit_trap.gdshaderinc") + "\n" +
		sdf_source + "\n" +
		_read("res://shaders/includes/color/PBR.gdshaderinc") + "\n" +
		_read("res://shaders/includes/rayMarcher/ray_marcher_AR.gdshaderinc") + "\n" +
		_MAIN
	)

static func _read(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("ShaderAssembler: cannot read " + path)
		return ""
	return f.get_as_text()
