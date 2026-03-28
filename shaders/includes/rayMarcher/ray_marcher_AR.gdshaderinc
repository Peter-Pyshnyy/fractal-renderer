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


// auto-relaxed raymarch (optimized)
vec3 raymarch_AR(vec3 rayDir) {
    float t = 0.0;
    float tMax = MAX_DIST;

    float omega = 1.0;
    float beta = 0.3;

    float prevRadius = 0.0;
    float stepLen = 0.0;

    float bestT = 0.0;
    float bestError = 1e9;

    // precompute once (important)
    float pixelRadius = cam.fovScale / cam.resolution.y;
    float invPixelFactor = 1.0 / max(pixelRadius * 0.25, 1e-6);
	float pixelThreshold = 0.001; 

    float steps = 0.0;

    for (int i = 0; i < MAX_STEPS; i++) {
        steps += 1.0;

        vec3 pos = cam.position.xyz + rayDir * t;
        float signedR = sdf(pos) * 0.4;
        float radius = abs(signedR);

        // --- overshoot detection ---
        bool sorFail = (omega > 1.0) && ((radius + prevRadius) < stepLen);

        if (sorFail) {
            // rollback overshoot
            t -= (omega - 1.0) * prevRadius;
            stepLen = prevRadius;
            omega = 1.0;
            continue;
        }

        // --- error metric (avoid repeated divisions) ---
        float denom = max(t * 0.1, 1.0 / invPixelFactor);
        float error = radius / denom;

        if (error < bestError) {
            bestError = error;
            bestT = t;
        }

        // exit condition
        if (error < pixelThreshold || t > tMax) {
            break;
        }

        // --- auto-relaxation ---
        float dr = prevRadius - radius;

        float omegaIdeal = 1.0;
        if (dr > 0.0 && stepLen > 0.0) {
            omegaIdeal = stepLen / dr;
        }

        omegaIdeal = clamp(omegaIdeal, 1.0, 1.9);
        omega = mix(omegaIdeal, omega, beta);

        // next step
        stepLen = radius * omega;
        prevRadius = radius;
        t += stepLen;
    }

    t = bestT;

    bool isHit = (bestError <= pixelThreshold);

    // small refinement steps
    if (t < tMax && isHit) {
        for (int i = 0; i < 3; i++) {
            vec3 p = cam.position.xyz + rayDir * t;
            t += sdf(p) - (EPSILON * t);
        }
    }

    // step visualization
    float s0 = 1.0 - steps / float(MAX_STEPS);
    float s1 = 1.0 - (0.5 + 0.5 * sin(steps * 0.01));
    float shade = mix(s0, s1, 0.5);

    if (t >= tMax || !isHit) {
        shade = 0.0;
    }

    return vec3(shade);
}