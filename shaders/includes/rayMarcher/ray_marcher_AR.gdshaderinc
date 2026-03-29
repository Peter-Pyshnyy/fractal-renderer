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
    // Algorithm 4 — Bán & Valasek (2023)
    // with screen-size-dependent LOD convergence
	
	float sdfScaler = 0.2;
    float beta = 0.3;

    // Angular size of one pixel. When r < t * pixelRadius, the unbounding
    // sphere is sub-pixel at that depth — no finer convergence is visible.
    float pixelRadius = cam.fovScale / cam.resolution.y;

    // Line 4: t := 0, r := f(s(t)), i := 1, z := r, m := −1
    float t = 0.0;
    float r = sdf(cam.position.xyz) * sdfScaler * params.resolution_scale;
    float z = r;
    float m = -1.0;

    // bestT tracks the position of minimum pixel-error seen so far.
    // Needed because LOD convergence can trigger before the true minimum.
    float bestT    = t;
    float bestError = 1e9;

    int stepsTaken = 1;

    for (int i = 1; i < MAX_STEPS; i++) {
        stepsTaken = i;

        // LOD-aware error: ratio of SDF radius to projected pixel size.
        // < 1.0 means the sphere is smaller than one pixel — converged.
        // Replaces the paper's fixed  r ≤ ε  stopping condition.
        float pixelError = r / max(t * pixelRadius * 0.25 * params.resolution_scale, 1e-6);

        if (pixelError < bestError) {
            bestError = pixelError;
            bestT     = t;
        }

        // Line 5 stopping conditions (miss or LOD-converged)
        if (pixelError < 1.0 || t + r >= MAX_DIST) break;

        // Line 6: T := t + z,  R := f(s(T))
        float T = t + z;
        vec3  pos = cam.position.xyz + rayDir * T;
        float R = sdf(pos) * sdfScaler * params.resolution_scale;

        // Line 7: if z ≤ r + |R|  (unbounding spheres overlap)
        if (z <= r + abs(R)) {
            // Lines 8–10: update exponential slope estimate, advance
            float M = (R - r) / (T - t);
            m = (1.0 - beta) * m + beta * M;
            t = T;
            r = R;
        } else {
            // Line 12: over-relaxed step — reset slope to basic ST fallback
            m = -1.0;
        }

        // Line 14: z := 2r / (1 − m)
        z = 2.0 * r / (1.0 - m);
    }

    bool  isHit = (bestError < 1.0);
    float shade = isHit ? (1.0 - float(stepsTaken) / float(MAX_STEPS)) : 0.0;
    return vec3(shade);
}