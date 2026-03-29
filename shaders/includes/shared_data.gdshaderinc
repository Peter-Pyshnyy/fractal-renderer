// Камера абсолютно однакова для всіх
layout(set = 0, binding = 1, std430) buffer CameraData {
    vec4 position;
    vec4 forward;
    vec4 right;
    vec4 up;
    vec2 resolution;
    float fovScale;
    float padding;
} cam;

// Push Constants однакові для всіх
layout(push_constant, std430) uniform FractalParams {
    float TEST;
    float power;
    float iterations;
    float step_scale;
    float omega_max;
    float omega_beta;
    float pass_scale; 
	int resolution_scale;
    float padding0;
    float padding1;
    float padding2;
    float padding3;
} params;

const int MAX_STEPS = 250;
const float EPSILON = 0.00001;
const float MAX_DIST = 20.0;