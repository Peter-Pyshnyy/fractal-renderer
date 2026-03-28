#[compute]
#version 450

layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

// 1. ФОРМАТ R32F: Нам потрібен лише один канал (float) для збереження дистанції
layout(set = 0, binding = 0, r32f) uniform writeonly image2D out_depth_map;

// 2. БУФЕР КАМЕРИ
layout(set = 0, binding = 1, std430) buffer CameraData {
    vec4 position;
    vec4 forward;
    vec4 right;
    vec4 up;
    vec2 resolution;
    float fovScale;
    float padding;
} cam;

// 3. PUSH CONSTANTS (Додаємо pass_scale)
layout(push_constant, std430) uniform FractalParams {
    float power;
    float iterations;
    float bailout;
    float step_scale;
    
    float omega_max;
    float omega_beta;
    float pass_scale; // НОВЕ: Масштаб проходу (наприклад, 8.0 для екрана 1/8)
    float padding2;
} params;

#include "res://shaders/includes/sdfs/sdf_mandelbulb.gdshaderinc"

const int MAX_STEPS = 250;
const float MAX_DIST = 20.0;

vec3 getRayDirection(vec2 resolution, vec2 uv) {
    float aspect = resolution.x / resolution.y;

    vec2 screen = uv * 2.0 - 1.0;
    screen.x *= aspect;
    screen *= cam.fovScale;

    // combine basis vectors
    return normalize(
        cam.forward.xyz +
        cam.right.xyz * screen.x +
        cam.up.xyz * screen.y
    );
}

void main() {
    ivec2 pixel_coords = ivec2(gl_GlobalInvocationID.xy);
    ivec2 image_size = imageSize(out_depth_map);

    if (pixel_coords.x >= image_size.x || pixel_coords.y >= image_size.y) {
        return; 
    }

    vec2 uv = vec2(pixel_coords) / vec2(image_size);
    uv.y = 1.0 - uv.y; 

    vec3 rayDir = getRayDirection(cam.resolution, uv);

    // --- CONE MARCHING ЛОГІКА ---
    
    // Базовий радіус одного пікселя фінального екрана
    float basePixelRadius = cam.fovScale / cam.resolution.y;
    
    // Радіус нашого поточного "товстого" конуса
    // Якщо pass_scale = 8.0, наш конус у 8 разів ширший за піксель
    float coneRadius = basePixelRadius * params.pass_scale;

    float t = 0.0;
    
    // Для грубого проходу використовуємо звичайний консервативний Sphere Tracing,
    // бо нам не потрібна міліметрова точність Алгоритму 4, нам потрібна гарантована безпека.
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 pos = cam.position.xyz + rayDir * t;
        float r = sdf(pos) * params.step_scale;
        
        // Поточна ширина конуса на дистанції t
        float currentConeWidth = max(t * coneRadius, 1e-6);
        
        // ЗУПИНКА: Якщо відстань до фрактала менша за ширину конуса, 
        // конус "вдарився" у поверхню.
        if (abs(r) < currentConeWidth || t > MAX_DIST) {
            break;
        }
        
        t += r;
    }

    // --- КРИТИЧНИЙ МОМЕНТ: БЕЗПЕЧНИЙ ВІДСТУП ---
    // Оскільки наш конус товстий (наприклад, охоплює площу 8x8 пікселів),
    // реальна поверхня для конкретного мікро-пікселя може бути трохи ближче до камери, 
    // ніж центр конуса.
    // Тому ми віднімаємо подвійну ширину конуса від результату, щоб гарантувати, 
    // що наступний прохід почнеться в "безпечній зоні" ПЕРЕД фракталом, а не всередині нього.
    float safe_t = max(0.0, t - (t * coneRadius * 4.0) - 0.05);
    
    if (t >= MAX_DIST) {
        safe_t = MAX_DIST; // Промінь полетів у небо
    }

    // Зберігаємо нашу безпечну дистанцію у R32F текстуру
    imageStore(out_depth_map, pixel_coords, vec4(safe_t, 0.0, 0.0, 0.0));
}