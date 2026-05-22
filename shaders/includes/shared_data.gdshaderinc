struct FractalData {
	float param0, param1, param2, param3;
	float param4, param5, param6, param7;
};

struct MaterialData {
	vec4 color_a;
	vec4 color_b;
};

// Binding 1: camera — per frame, unchanged
layout(set = 0, binding = 1, std430) buffer CameraData {
	vec4 position;
	vec4 forward;
	vec4 right;
	vec4 up;
	vec2 resolution;
	float fovScale;
	float padding;
} cam;

// Binding 3: scene SSBO — updated only when SceneState.changed fires
layout(set = 0, binding = 3, std430) restrict readonly buffer SceneBuffer {
	FractalData params;   // 32 B
	MaterialData material; // 32 B
	vec4  light_dir;      // 16 B
	float metallic;       //  4 B
	float roughness;      //  4 B
	float sdf_scalar;     //  4 B
	float lod_scalar;     //  4 B
	vec4  background_color; // 16 B
	int   iterations;     //  4 B
	int   use_pbr;        //  4 B
	int   max_steps;          //  4 B
	int   _pad3;          //  4 B
	int   color_mode;
	int   palette_type;
	float iter_norm_factor;
	int   iter_bw_preview;
	vec4  uniform_color;
	vec4  trap_pos_size;
	int   trap_shape;
	float trap_norm_k;
	int   trap_bw_preview;
	float _pad_trap;
	float sinmask_phase;
	float sinmask_amp;
	float hsv_cycles;
	float hsv_hue_offset;
	float hsv_blend;
	float trap_lp_power;
	float _pad_p1;
	float _pad_p2;
} scene;                  // total: 224 B

// Push constants — frame-transient only (32 B)
layout(push_constant, std430) uniform FrameConstants {
	vec2  jitter;         //  8 B
	float history_blend;  //  4 B
	float _pad_f0;        //  4 B (aligns int block to 16 B)
	int   resolution_scale; // 4 B
	int   frame_index;    //  4 B
	int   _pad_i0;        //  4 B
	int   _pad_i1;        //  4 B
};

#define MAX_STEPS scene.max_steps
const float EPSILON = 0.001;
const float MAX_DIST = 20.0;
