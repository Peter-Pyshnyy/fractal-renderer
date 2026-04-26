struct FractalData { // float = 4*7 = 28b
	float param0;
    float param1;
    float param2;
    float param3;
};

struct MaterialData { // vec4 = 4*4 = 16b, 16*2 = 32b
	vec4 color_a;
	vec4 color_b;
};

layout(set = 0, binding = 1, std430) buffer CameraData {
    vec4 position;
    vec4 forward;
    vec4 right;
    vec4 up;
    vec2 resolution;
    float fovScale;
    float padding;
} cam;

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

const int MAX_STEPS = 250;
const float EPSILON = 0.001;
const float MAX_DIST = 20.0;
