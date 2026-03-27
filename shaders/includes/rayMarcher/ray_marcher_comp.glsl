#[compute]
#version 450

layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

layout(set = 0, binding = 0) uniform writeonly image2D output_image;

layout(set = 0, binding = 1, std430) buffer CameraData {
    vec4 position;
    vec4 forward;
    vec4 right;
    vec4 up;
    vec2 resolution;
    float fovScale;
    float padding;
} cam;

const int MAX_STEPS = 250;
const float EPSILON = 0.001;
const float MAX_DIST = 20.0;

float sdf(vec3 pos) {
    // early bounding sphere (cheap rejection)
    //float safeDist = length(pos) - 1.2;
    //if (safeDist > 0.1) {
        //return safeDist;
    //}

    vec3 z = pos;
    float r = 0.0;
    float dr = 1.0;
    float power = 8.0;
    float iterations = 10.0;

    // precompute constants
    float powerMinus1 = power - 1.0;

    for (int i = 0; i < iterations; i++) {
        r = length(z);
        if (r > 2.0) break; // escape radius

        // avoid division instability near zero
        float invR = 1.0 / max(r, 1e-6);

        // spherical coordinates
        float theta = acos(z.z * invR);
        float phi = atan(z.y, z.x);

        // derivative update (distance estimation)
        float rPow = pow(r, powerMinus1);
        dr = rPow * power * dr + 1.0;

        // scale + rotate
        float zr = rPow * r; // == pow(r, power)
        theta *= power;
        phi *= power;

        // back to cartesian
        float sinTheta = sin(theta);
        z = zr * vec3(
            sinTheta * cos(phi),
            sinTheta * sin(phi),
            cos(theta)
        ) + pos;
    }

    // distance estimation
    return 0.5 * log(r) * r / dr;
}

vec3 getRayDirection(vec2 resolution, vec2 uv) {
	float aspectRatio = resolution.x / resolution.y;
	vec2 screenCoords = uv*2.0 - 1.0; // Convert to range [-1, 1]
	screenCoords.x *= aspectRatio; // Adjust for aspect ratio
	screenCoords *= cam.fovScale; // Apply FOV scaling

	return normalize(screenCoords.x * cam.right.xyz + screenCoords.y * cam.up.xyz + cam.forward.xyz);
}

vec3 raymarch(vec3 rayDir) {
    float t = 0.0;
    float steps = 0.0;

    for (int i = 0; i < MAX_STEPS; i++) {
        steps += 1.0;
        vec3 pos = cam.position.xyz + rayDir * t;
        float d = sdf(pos);
        if (d < EPSILON) break;
        t += d;
        if (t > 10.0) break;
    }

    float s0 = 1.0 - steps / float(MAX_STEPS);
    float s1 = sin(steps * 0.01);
    s1 = 1.0 - (0.5 + 0.5 * s1);
    float shade = mix(s0, s1, 0.5);

    return vec3(shade);
}

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

	vec3 color = raymarch(rayDirection);

	imageStore(output_image, pixel_coords, vec4(color, 1.0));
}

