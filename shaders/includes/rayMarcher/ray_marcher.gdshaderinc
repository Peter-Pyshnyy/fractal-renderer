// basic ray marcher (inspired by: https://cgmathprog.home.blog/2019/09/02/raymarching-from-scratch)

// --- Camera ---
uniform float fov;
uniform float fovScale;                 
uniform vec3 cameraPos;
uniform vec3 forward;
uniform vec3 right;
uniform vec3 up = vec3(0.0, 1.0, 0.0);    

// --- Raymarch settings ---
uniform int MAX_STEPS = 250;              // max iterations
uniform float epsilon = 0.0000001;     // hit threshold

// --- Lighting ---
uniform vec3 color = vec3(1.0);
uniform vec3 lightPos = vec3(-2.0, 5.0, 3.0);
uniform vec3 lightColor = vec3(0.9, 0.9, 0.68);
uniform vec3 ambientColor = vec3(1.0);

// normal estimation step size
const float DERIVATIVE_STEP = 0.01;

// --- testing ---
uniform float TEST;

// fallback definitions (avoid compile errors)
#ifndef CUSTOM_SDF_PROVIDED
float sdf(vec3 pos) { return 0.0; }
vec3 phong(vec3 normal, vec3 viewDir, vec3 lightDir) { return vec3(0.0); }
#endif


vec3 getRayDirection(vec2 resolution, vec2 uv) {
    float aspect = resolution.x / resolution.y;

    // map UV [0,1] → [-1,1], flip Y
    vec2 screen = (uv - 0.5) * 2.0;
    screen.x *= aspect;
    screen.y = -screen.y;

    // screen-space offset scaled by FOV
    vec2 offset = screen * fovScale;

    // combine into final ray direction
    vec3 rayDir = forward + right * offset.x + up * offset.y;
    return normalize(rayDir);
}


vec3 estimateNormal(vec3 p, float t) {
    vec3 e = vec3(0.01, 0.0, 0.0);

	 return normalize(vec3(
        sdf(p + e.xyy),
        sdf(p + e.yxy),
        sdf(p + e.yyx)
    ));
}


vec3 raymarch(vec3 rayDir) {
    float t = 0.0;
    float steps = 0.0;

    for (int i = 0; i < MAX_STEPS; i++) {
        steps += 1.0;
        vec3 pos = cameraPos + rayDir * t;
        float d = sdf(pos);
        if (d < epsilon) break;
        t += d;
        if (t > 10.0) break;
    }

    float s0 = 1.0 - steps / float(MAX_STEPS);
    float s1 = sin(steps * 0.01);
    s1 = 1.0 - (0.5 + 0.5 * s1);
    float shade = mix(s0, s1, 0.5);

    return vec3(shade);
}