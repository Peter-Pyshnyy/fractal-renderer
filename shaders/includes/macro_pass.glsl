#[compute]
#version 450

layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;
layout(set = 0, binding = 0, r32f) uniform writeonly image2D out_depth_map;

// НОВЕ: Семплер для читання попереднього макро-буфера
layout(set = 0, binding = 2) uniform sampler2D prev_depth_map;

#include "res://shaders/includes/shared_data.gdshaderinc"
#include "res://shaders/includes/sdfs/sdf_mandelbulb.gdshaderinc"

vec3 getRayDirection(vec2 resolution, vec2 uv) {
	float aspectRatio = resolution.x / resolution.y;
	vec2 screenCoords = uv*2.0 - 1.0; // Convert to range [-1, 1]
	screenCoords.x *= aspectRatio; // Adjust for aspect ratio
	screenCoords *= cam.fovScale; // Apply FOV scaling

	return normalize(screenCoords.x * cam.right.xyz + screenCoords.y * cam.up.xyz + cam.forward.xyz);
}

void main() {
    ivec2 pixel_coords = ivec2(gl_GlobalInvocationID.xy);
    ivec2 image_size = imageSize(out_depth_map);
    if (pixel_coords.x >= image_size.x || pixel_coords.y >= image_size.y) return; 

    vec2 uv_sample = vec2(pixel_coords) / vec2(image_size);
    vec2 uv = uv_sample;
    uv.y = 1.0 - uv.y; 

    vec3 rayDir = getRayDirection(cam.resolution, uv);
    float basePixelRadius = cam.fovScale / cam.resolution.y;
    float coneRadius = basePixelRadius * params.pass_scale;

    // --- СТАРТ З ФОРОЮ ---
    float t = 0.0;
    // Якщо це не перший прохід (pass_index > 0), читаємо глибину від попередника
    if (params.pass_index > 0.5) {
        t = texture(prev_depth_map, uv_sample).r;
    } 

    // Звичайний Cone Marching
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 pos = cam.position.xyz + rayDir * t;
        float r = sdf(pos) * params.step_scale;
        float currentConeWidth = max(t * coneRadius, 1e-6);
        
        if (abs(r) < currentConeWidth || t > MAX_DIST) break;
        t += r;
    }

    float cone_width = t * coneRadius;
    float safe_t = max(0.0, t - cone_width);
    if (t >= MAX_DIST) safe_t = MAX_DIST;

    imageStore(out_depth_map, pixel_coords, vec4(safe_t, 0.0, 0.0, 0.0));
}