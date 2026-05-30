struct FractalData {
	float param0, param1, param2, param3;
	float param4, param5, param6, param7;
};

struct MaterialData {
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

layout(set = 0, binding = 3, std430) restrict readonly buffer SceneBuffer {
	FractalData params;
	MaterialData material;
	vec4  light_dir;
	float metallic;
	float roughness;
	float sdf_scalar;
	float lod_scalar;
	vec4  background_color;
	float exposure;
	float iter_norm_a;
	float iter_norm_b;
	float _pad_exp;
	int   iterations;
	int   use_pbr;
	int   max_steps;
	int   _pad3;
	int   color_mode;
	int   palette_type;
	float _pad_color0;
	int   iter_bw_preview;
	vec4  uniform_color;
	vec4  trap_pos_size;
	int   trap_shape;
	float trap_norm_a;
	int   trap_bw_preview;
	float _pad_trap;
	float hsv_cycles;
	float hsv_hue_offset;
	float hsv_blend;
	float trap_lp_power;
	float trap_norm_b;
	int   light_type;        // 0=dirlight, 1=pointlight, 2=egolight
	float light_multiplier;
	float light_radius_mult;
	vec4  light_color;
} scene;

layout(push_constant, std430) uniform FrameConstants {
	vec2  jitter;         //  8 B
	float history_blend;  //  4 B
	float _pad_f0;        //  4 B
	int   resolution_scale; // 4 B
	int   frame_index;    //  4 B
	int   _pad_i0;        //  4 B
	int   _pad_i1;        //  4 B
};

#define MAX_STEPS scene.max_steps
const float EPSILON = 0.001;
const float MAX_DIST = 20.0;
