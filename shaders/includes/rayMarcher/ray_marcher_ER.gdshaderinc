// epsilon relaxation

// --- Camera ---
uniform float fov;
uniform float fovScale;
uniform vec3 cameraPos;
uniform vec3 forward;
uniform vec3 right;
uniform vec3 up = vec3(0.0, 1.0, 0.0);

// --- Raymarch ---
uniform int MAX_STEPS = 250;
uniform float epsilon = 0.00001;

// --- Lighting ---
uniform vec3 color = vec3(1.0);
uniform vec3 lightPos = vec3(-2.0, 5.0, 3.0);
uniform vec3 lightColor = vec3(0.9, 0.9, 0.68);
uniform vec3 ambientColor = vec3(1.0);

// --- testing ---
uniform float TEST = 0.7;

const float DERIVATIVE_STEP = 0.0001;


#ifndef CUSTOM_SDF_PROVIDED
float sdf(vec3 pos) { return 0.0; }
vec3 phong(vec3 normal, vec3 viewDir, vec3 lightDir) { return vec3(0.0); }
#endif


// --- Ray direction ---

vec3 getRayDirection(vec2 resolution, vec2 uv) {
    float aspect = resolution.x / resolution.y;

    vec2 screen = (uv - 0.5) * 2.0;
    screen.x *= aspect;
    screen.y = -screen.y;

    vec2 offset = screen * fovScale;

    return normalize(forward + right * offset.x + up * offset.y);
}


 // --- Normal ---

vec3 estimateNormal(vec3 p, float eps) {
    vec3 e = vec3(0.01, 0.0, 0.0);

	 return normalize(vec3(
        sdf(p + e.xyy),
        sdf(p + e.yxy),
        sdf(p + e.yyx)
    ));

    // reuse offsets to reduce construction cost
    //return normalize(vec3(
        //sdf(p + e.xyy) - sdf(p - e.xyy),
        //sdf(p + e.yxy) - sdf(p - e.yxy),
        //sdf(p + e.yyx) - sdf(p - e.yyx)
    //));
}


// --- Raymarch with epsilon relaxation ---

vec3 raymarch_ER(vec3 rayDir, vec2 resolution) {
    float t = 0.0;
    float steps = 0.0;
    float minCoverage = 1.0;
    float bestT = 0.0;
    float pixelAngle = (2.0 * fovScale) / resolution.y;

    for (int i = 0; i < MAX_STEPS; i++) {
        steps += 1.0;
        vec3 pos = cameraPos + rayDir * t;
        float d = sdf(pos);

        float epsRelaxed = t * pixelAngle;
        if (d < epsRelaxed) {
            float coverage = d / epsRelaxed;
            if (coverage < minCoverage) {
                minCoverage = coverage;
                bestT = t;
            }
        }

        if (d < epsilon) {
            minCoverage = 0.0;
            bestT = t;
            break;
        }

        t += d;
        if (t > 10.0) break;
    }

    float alpha = 1.0 - clamp(minCoverage, 0.0, 1.0);
	
    if (alpha <= 0.0) return vec3(0.0);

    float s0 = 1.0 - steps / float(MAX_STEPS);
    float s1 = sin(steps * 0.01);
    s1 = 1.0 - (0.5 + 0.5 * s1);
    float shade = mix(s0, s1, 0.5);

    return vec3(shade) * alpha;
}