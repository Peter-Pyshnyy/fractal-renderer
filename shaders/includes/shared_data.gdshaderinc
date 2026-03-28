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
const float EPSILON = 0.00001;
const float MAX_DIST = 20.0;