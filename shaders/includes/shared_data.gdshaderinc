struct FractalData { // float = 8*7 = 56b
	float param0;
    float param1;
    float param2;
    float param3;
    float param4;
    float param5;
    float param6;
    float param7;
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
    FractalData params;       // 32
    MaterialData material;    // 32
    vec4 u_lightDir;          // 16
    float u_metallic;         // 4
    float u_roughness;        // 4
    int use_pbr;              // 4
    int resolution_scale;     // 4
    float jitter_x;           // 4
    float jitter_y;           // 4
    float history_blend;      // 4
    float push_constant_padding; // 4
};

const int MAX_STEPS = 250;
const float EPSILON = 0.001;
const float MAX_DIST = 20.0;
