#[compute]
#version 450
layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;


layout(set = 0, binding = 0) uniform writeonly image2D output_image;
layout(set = 0, binding = 2) uniform sampler2D macro_depth_map;

#include "res://shaders/includes/shared_data.gdshaderinc"
#include "res://shaders/includes/sdfs/sdf_mandelbulb.gdshaderinc"
#include "res://shaders/includes/rayMarcher/ray_marcher_AR.gdshaderinc"
//#include "res://shaders/includes/rayMarcher/ray_marcher_enhanced.gdshaderinc"

void main() {
	ivec2 pixel_coords = ivec2(gl_GlobalInvocationID.xy);
	ivec2 image_size = imageSize(output_image);

	if (pixel_coords.x >= image_size.x || pixel_coords.y >= image_size.y) {
		return; // Out of bounds
	}

	vec2 uv = vec2(pixel_coords) / vec2(image_size);
	uv.y = 1.0 - uv.y; // Flip Y coordinate for correct orientation

	vec3 rayOrigin = cam.position.xyz;
	vec3 rayDirection = getRayDirection(cam.resolution, uv);

	vec3 color = raymarch_AR(rayDirection);
//		color = raymarch_enhanced(rayDirection);
 

	imageStore(output_image, pixel_coords, vec4(color, 1.0));
}