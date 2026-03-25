// --- Camera ---
//uniform float fov;
//uniform float fovScale;
//uniform vec3 cameraPos;
//uniform vec3 forward;
//uniform vec3 right;
//uniform vec3 up = vec3(0.0, 1.0, 0.0);
//
//// --- Raymarch ---
//uniform int MAX_STEPS = 250;
//uniform float epsilon = 0.00001;
//
//// --- Lighting ---
//uniform vec3 color = vec3(1.0);
//uniform vec3 lightPos = vec3(-2.0, 5.0, 3.0);
//uniform vec3 lightColor = vec3(0.9, 0.9, 0.68);
//uniform vec3 ambientColor = vec3(1.0);
//
//const float DERIVATIVE_STEP = 0.0001;


#ifndef CUSTOM_SDF_PROVIDED
float sdf(vec3 pos) { return 0.0; }
vec3 phong(vec3 normal, vec3 viewDir, vec3 lightDir) { return vec3(0.0); }
#endif


// --- Ray direction ---

//vec3 getRayDirection(vec2 resolution, vec2 uv) {
    //float aspect = resolution.x / resolution.y;
//
    //vec2 screen = (uv - 0.5) * 2.0;
    //screen.x *= aspect;
    //screen.y = -screen.y;
//
    //vec2 offset = screen * fovScale;
//
    //return normalize(forward + right * offset.x + up * offset.y);
//}


// --- Normal ---

//vec3 estimateNormal(vec3 p, float eps) {
    //vec3 e = vec3(0.1, 0.0, 0.0) * eps;
//
	 //return normalize(vec3(
        //sdf(p + e.xyy),
        //sdf(p + e.yxy),
        //sdf(p + e.yyx)
    //));
//
    //// reuse offsets to reduce construction cost
    ////return normalize(vec3(
        ////sdf(p + e.xyy) - sdf(p - e.xyy),
        ////sdf(p + e.yxy) - sdf(p - e.yxy),
        ////sdf(p + e.yyx) - sdf(p - e.yyx)
    ////));
//}


// --- Raymarch with epsilon relaxation ---

vec3 raymarchER(vec3 rayDir, float screenWidth) {
    // precompute once (was inside loop implicitly via usage)
    float pixelAngle = fov / screenWidth;

    float t = 0.0;
    float minCoverage = 1.0;
    float bestT = 0.0;

    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 pos = cameraPos + rayDir * t;
        float d = sdf(pos);

        float epsRelaxed = t * pixelAngle;

        // cone intersection test
        if (d < epsRelaxed) {
            float coverage = d / epsRelaxed;

            // track closest approach
            if (coverage < minCoverage) {
                minCoverage = coverage;
                bestT = t;
            }
        }

        // solid hit
        if (d < epsilon) {
            minCoverage = 0.0;
            bestT = t;
            break;
        }

        // step forward (slightly conservative for fractals)
        t += d;

        // early exit (too far)
        if (t > 100.0) break;
    }

    float alpha = 1.0 - clamp(minCoverage, 0.0, 1.0);

    // skip expensive shading if nothing hit
    if (alpha <= 0.1) {
        return vec3(0.0);
    }

    vec3 hitPos = cameraPos + rayDir * bestT;

    // cone-based normal smoothing
    float hitEps = bestT * pixelAngle;
    vec3 normal = estimateNormal(hitPos, hitEps);

    vec3 viewDir = normalize(cameraPos - hitPos);
    vec3 lightDir = normalize(lightPos - hitPos);

    vec3 lighting = phong(normal, viewDir, lightDir);

    return color * lighting * alpha;
}