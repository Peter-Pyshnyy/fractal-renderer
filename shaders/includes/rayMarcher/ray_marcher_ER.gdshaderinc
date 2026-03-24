// Epsilon relaxation

// --- Camera ---
uniform float fov;
uniform float fovScale;                 
uniform vec3 cameraPos;
uniform vec3 forward;
uniform vec3 right;
uniform vec3 up = vec3(0.0, 1.0, 0.0);    

// --- Raymarch settings ---
uniform int MAX_STEPS = 250;              // max iterations
uniform float epsilon = 0.00001;     // hit threshold

// --- Lighting ---
uniform vec3 color = vec3(1.0);
uniform vec3 lightPos = vec3(-2.0, 5.0, 3.0);
uniform vec3 lightColor = vec3(0.9, 0.9, 0.68);
uniform vec3 ambientColor = vec3(1.0);

// normal estimation step size
const float DERIVATIVE_STEP = 0.0001;


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


vec3 estimateNormal(vec3 p, float eps) {
    // We use the dynamic 'eps' instead of a fixed DERIVATIVE_STEP
    return normalize(vec3(
        sdf(p + vec3(eps, 0.0, 0.0)) - sdf(p - vec3(eps, 0.0, 0.0)),
        sdf(p + vec3(0.0, eps, 0.0)) - sdf(p - vec3(0.0, eps, 0.0)),
        sdf(p + vec3(0.0, 0.0, eps)) - sdf(p - vec3(0.0, 0.0, eps))
    ));
}


vec3 raymarchER(vec3 rayDir, float w) {
    float pixel_angle = fov / w;
    float t = 0.0;
    float min_coverage = 1.0;
    float best_t = 0.0; // Track the closest approach distance

    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 pos = cameraPos + rayDir * t;
        float d = sdf(pos);
        
        // epsilon-relaxation
        float eps_relaxed = t * pixel_angle;
        
        // check if cone intersects sdf
        if (d < eps_relaxed) {
            float current_coverage = d / eps_relaxed;
            // If this is the deepest we've penetrated the cone, save the coverage and distance
            if (current_coverage < min_coverage) {
                min_coverage = current_coverage;
                best_t = t; 
            }
        }

        // hit solid surface
        if (d < epsilon) {
            min_coverage = 0.0;
            best_t = t; // Save hit distance
            break;
        }

        // Advance along ray. 
        // Note the * 0.8: Fractals often need smaller steps to avoid overshooting fine details!
        t += d * 0.8; 
        
        // Optimization: stop marching if we've gone too far into the void
        if (t > 100.0) break; 
    }
    
    // blend final color
    float alpha = 1.0 - clamp(min_coverage, 0.0, 1.0);
    vec3 lighting = vec3(0.0);
    
    // Only calculate expensive lighting if we actually hit or grazed the object
    if (alpha > 0.001) {
        vec3 hitPos = cameraPos + rayDir * best_t;
        // Calculate the cone radius at the exact hit distance
        float hit_eps = best_t * pixel_angle * 0.125;
        // Pass the cone radius to the normal estimator
        // Note: You can multiply hit_eps by a small factor (e.g., hit_eps * 0.5) 
        // if the normals look *too* blurry/smooth.
        vec3 normal = estimateNormal(hitPos, hit_eps);
        vec3 viewDir = normalize(cameraPos - hitPos);
        vec3 lightDir = normalize(lightPos - hitPos);
        lighting = phong(normal, viewDir, lightDir);
    }

    return mix(vec3(0.0), color * lighting, alpha);
}