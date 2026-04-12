#[compute]
#version 450
#extension GL_ARB_gpu_shader_fp64 : require
layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

layout(set = 0, binding = 0, rgba32f) uniform writeonly image2D output_image;
layout(set = 0, binding = 2, rgba32f) uniform readonly image2D history_image;

struct FractalData {
	float param0;
	float param1;
	float param2;
	float param3;
};

struct MaterialData {
	vec4 color_a;
	vec4 color_b;
};

layout(set = 0, binding = 1, std430) buffer CameraData64 {
	dvec4 position64;
	vec4 forward;
	vec4 right;
	vec4 up;
	vec4 resolution_fov;
} cam64;

layout(push_constant, std430) uniform PushConstants {
	FractalData params;
	MaterialData material;
	float u_metallic;
	float u_roughness;
	vec4 u_lightDir;
	int resolution_scale;
	float jitter_x;
	float jitter_y;
	float history_blend;
};

#include "res://shaders/includes/color/orbit_trap.gdshaderinc"
#include "res://shaders/includes/sdfs/sdf_mandelbulb.gdshaderinc"
#include "res://shaders/includes/color/PBR.gdshaderinc"

const int MAX_STEPS_64 = 250;
const double EPSILON_64 = 1e-8;
const double MAX_DIST_64 = 20.0;


double dsdf(dvec3 p) {
	// Reuses existing float SDF while keeping world-space traversal in float64.
	return double(sdf(vec3(p)));
}


dvec3 get_ray_direction_64(vec2 uv) {
	double aspect = double(cam64.resolution_fov.x) / double(cam64.resolution_fov.y);
	dvec2 screen = dvec2(uv) * 2.0 - 1.0;
	screen.x *= aspect;
	screen *= double(cam64.resolution_fov.z);

	dvec3 f = dvec3(cam64.forward.xyz);
	dvec3 r = dvec3(cam64.right.xyz);
	dvec3 u = dvec3(cam64.up.xyz);
	return normalize(f + r * screen.x + u * screen.y);
}


vec3 raymarch_64(dvec3 ray_dir) {
	dvec3 origin = cam64.position64.xyz;
	double t = 0.0;
	bool hit = false;

	for (int i = 0; i < MAX_STEPS_64; i++) {
		dvec3 p = origin + ray_dir * t;
		double d = dsdf(p);
		if (d < EPSILON_64) {
			hit = true;
			break;
		}
		t += d;
		if (t > MAX_DIST_64) {
			break;
		}
	}

	if (!hit) {
		return vec3(0.0);
	}

	vec3 hit_pos = vec3(origin + ray_dir * t);
	float trap;
	sdf_with_trap(hit_pos, trap);
	trap = log(trap + 1.0);
	float trap_normalized = exp(-trap * 15.0);

	float normal_h = clamp(float(t) * (cam64.resolution_fov.z / cam64.resolution_fov.y), 1e-7, 0.01);
	vec3 norm = calcNormal(hit_pos, normal_h);
	float ao = calcAO(hit_pos, norm);
	vec3 albedo = get_trap_color_hsv(trap_normalized);
	return PBR(norm, normal_h, -vec3(ray_dir), hit_pos, albedo, ao);
}


void main() {
	ivec2 base_coord = ivec2(gl_GlobalInvocationID.xy) * resolution_scale;
	ivec2 image_size = imageSize(output_image);
	if (base_coord.x >= image_size.x || base_coord.y >= image_size.y) return;

	vec2 offset = vec2(float(resolution_scale) * 0.5);
	vec2 jitter = vec2(jitter_x, jitter_y);
	vec2 uv = (vec2(base_coord) + offset + jitter) / vec2(image_size);
	uv.y = 1.0 - uv.y;

	dvec3 ray_dir = get_ray_direction_64(uv);
	vec3 color = raymarch_64(ray_dir);

	for (int y = 0; y < resolution_scale; y++) {
		for (int x = 0; x < resolution_scale; x++) {
			ivec2 write_coord = base_coord + ivec2(x, y);
			if (write_coord.x < image_size.x && write_coord.y < image_size.y) {
				float exposure = 3.0;
				vec3 current_ldr = color * exposure;
				current_ldr = current_ldr / (current_ldr + 1.0);

				vec3 history_gamma = imageLoad(history_image, write_coord).rgb;
				vec3 history_linear = pow(history_gamma, vec3(2.2));
				vec3 blended_linear = mix(current_ldr, history_linear, history_blend);
				vec3 final_color = pow(blended_linear, vec3(1.0 / 2.2));
				imageStore(output_image, write_coord, vec4(final_color, 1.0));
			}
		}
	}
}
