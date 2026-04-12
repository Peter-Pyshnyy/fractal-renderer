#[compute]
#version 450
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
#include "res://shaders/includes/color/PBR.gdshaderinc"

const int MAX_STEPS_64 = 250;
const double EPSILON_64 = 1e-10;
const double MAX_DIST_64 = 20.0;
const int AO_STEPS_64 = 5;
const double AO_BASE_H_64 = 0.01;

double dsdf_mandelbulb(dvec3 pos) {
	dvec3 z = pos;
	double r = 0.0;
	double dr = 1.0;
	double power = double(params.param1);
	int iterations = int(params.param0);
	double power_minus_1 = power - 1.0;

	for (int i = 0; i < iterations; i++) {
		r = length(z);
		if (r > 2.0) {
			break;
		}

		double inv_r = 1.0 / max(r, 1e-18);
		double theta = acos(clamp(z.z * inv_r, -1.0, 1.0));
		double phi = atan(z.y, z.x);
		double r_pow = pow(r, power_minus_1);
		dr = r_pow * power * dr + 1.0;
		double zr = r_pow * r;
		theta *= power;
		phi *= power;
		double sin_theta = sin(theta);
		z = zr * dvec3(sin_theta * cos(phi), sin_theta * sin(phi), cos(theta)) + pos;
	}

	r = max(r, 1e-18);
	return 0.5 * log(r) * r / max(dr, 1e-18);
}

double dsdf_with_trap(dvec3 pos, out double trap) {
	dvec3 z = pos;
	double r = 0.0;
	double dr = 1.0;
	double power = double(params.param1);
	int iterations = int(params.param0);
	double power_minus_1 = power - 1.0;
	trap = 1e12;

	for (int i = 0; i < iterations; i++) {
		r = length(z);
		if (r > 2.0) {
			break;
		}

		double inv_r = 1.0 / max(r, 1e-18);
		double theta = acos(clamp(z.z * inv_r, -1.0, 1.0));
		double phi = atan(z.y, z.x);
		double r_pow = pow(r, power_minus_1);
		dr = r_pow * power * dr + 1.0;
		double zr = r_pow * r;
		theta *= power;
		phi *= power;
		double sin_theta = sin(theta);
		z = zr * dvec3(sin_theta * cos(phi), sin_theta * sin(phi), cos(theta)) + pos;

		trap = min(trap, abs(length(z) - 1.0));
	}

	r = max(r, 1e-18);
	return 0.5 * log(r) * r / max(dr, 1e-18);
}

float sdf(vec3 pos) {
	return float(dsdf_mandelbulb(dvec3(pos)));
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

double dsdf_scene(dvec3 p_world, dvec3 cam_origin_world) {
	// Hook for camera-relative remapping strategies; currently full FP64 world-space SDF.
	return dsdf_mandelbulb(p_world);
}

dvec3 calc_normal_64(dvec3 p_world, dvec3 cam_origin_world, double h) {
	const dvec2 k = dvec2(1.0, -1.0);
	return normalize(
		k.xyy * dsdf_scene(p_world + k.xyy * h, cam_origin_world) +
		k.yyx * dsdf_scene(p_world + k.yyx * h, cam_origin_world) +
		k.yxy * dsdf_scene(p_world + k.yxy * h, cam_origin_world) +
		k.xxx * dsdf_scene(p_world + k.xxx * h, cam_origin_world)
	);
}

double calc_ao_64(dvec3 pos_world, dvec3 norm_world, dvec3 cam_origin_world) {
	double occ = 0.0;
	double sca = 1.0;
	for (int i = 0; i < AO_STEPS_64; i++) {
		double h = AO_BASE_H_64 + 0.12 * double(i) / 4.0;
		double d = dsdf_scene(pos_world + h * norm_world, cam_origin_world);
		occ += (h - d) * sca;
		sca *= 0.95;
	}
	return clamp(1.0 - 3.0 * occ, 0.0, 1.0);
}

vec3 raymarch_64(dvec3 ray_dir) {
	dvec3 origin = cam64.position64.xyz;
	double t = 0.0;
	bool hit = false;

	for (int i = 0; i < MAX_STEPS_64; i++) {
		dvec3 p = origin + ray_dir * t;
		double d = dsdf_scene(p, origin);
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

	dvec3 hit_pos_world = origin + ray_dir * t;
	dvec3 hit_pos_relative = hit_pos_world - origin;
	double trap;
	dsdf_with_trap(hit_pos_relative + origin, trap);
	float trap_f = log(float(trap) + 1.0);
	float trap_normalized = exp(-trap_f * 15.0);

	float normal_h = clamp(float(t) * (cam64.resolution_fov.z / cam64.resolution_fov.y), 1e-7, 0.01);
	dvec3 norm64 = calc_normal_64(hit_pos_world, origin, double(normal_h));
	double ao64 = calc_ao_64(hit_pos_world, norm64, origin);

	vec3 hit_pos = vec3(hit_pos_relative);
	vec3 norm = normalize(vec3(norm64));
	float ao = float(ao64);
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
