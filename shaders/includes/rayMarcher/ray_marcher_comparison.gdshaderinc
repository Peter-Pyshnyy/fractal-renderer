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

vec3 turbo(float x) {
    x = clamp(x, 0.0, 1.0);
    vec3 c0 = vec3(0.18995, 0.07176, 0.23217);
    vec3 c1 = vec3(0.86343, 0.96138, 0.30498);
    vec3 c2 = vec3(0.70470, 0.01497, 0.15050);
    return c0
         + x * (4.61539 * c1 - 4.22054 * c0 - 0.39487 * c2)
         + x * x * (4.84844 * c0 - 9.23078 * c1 + 4.38234 * c2)
         + x * x * x * (4.61539 * c1 - 0.61539 * c0 - 4.0 * c2);
}

vec3 raymarch(vec3 rayDir) {
    float sdfScaler = 0.75;

    float t = 0.0;
    float r = sdf(cam.position.xyz) * sdfScaler;
    int steps;

    for (steps = 0; steps < MAX_STEPS; steps++) {
        if (r < EPSILON || t + r >= MAX_DIST) break;

        float T = t + r;
        vec3  pos = cam.position.xyz + rayDir * T;
        float R   = sdf(pos) * sdfScaler;

        t = T;
        r = R;
    }

    return turbo(float(steps) / 60.0);
}

vec3 raymarch_relaxed(vec3 rayDir) {
    float sdfScaler   = 0.75;
    float omega       = 1.5;
    float omegaActive = omega;

    float t = 0.0;
    float r = sdf(cam.position.xyz) * sdfScaler;
    int steps;

    for (steps = 0; steps < MAX_STEPS; steps++) {
        if (r < EPSILON || t + r >= MAX_DIST) break;

        float stepLen = r * omegaActive;
        float T       = t + stepLen;
        vec3  pos     = cam.position.xyz + rayDir * T;
        float R       = sdf(pos) * sdfScaler;

        if (omegaActive > 1.0 && (r + abs(R)) < stepLen) {
            // Overshoot — discard, stay at t, switch to omega = 1 from now on.
            omegaActive = 1.0;
        } else {
            t = T;
            r = R;
        }
    }

    return turbo(float(steps) / 60.0);
}

vec3 raymarch_enhanced(vec3 rayDir) {
    float sdfScaler = 0.75;
    float omega     = 0.88;

    float t = 0.0;
    float r = sdf(cam.position.xyz) * sdfScaler;
    float z = r;   // first step is basic (no slope info yet)
    int steps;

    for (steps = 0; steps < MAX_STEPS; steps++) {
        if (r < EPSILON || t + r >= MAX_DIST) break;

        float T   = t + z;
        vec3  pos = cam.position.xyz + rayDir * T;
        float R   = sdf(pos) * sdfScaler;

        if (z <= r + abs(R)) {
            // Accept and compute the next planar-inferred step
            float prev_r   = r;
            float z_actual = z;
            t = T;
            r = R;

            float numer  = z_actual + R - prev_r;
            float denom  = z_actual + prev_r - R;
            float z_next = (denom <= EPSILON) ? R : R + omega * R * numer / denom;
            z = max(z_next, R);
        } else {
            // Reject — retry with basic step from same t
            z = r;
        }
    }

    return turbo(float(steps) / 60.0);
}

vec3 raymarch_AR(vec3 rayDir) {
    float sdfScaler = 0.75;
    float beta      = 0.3;

    float t = 0.0;
    float r = sdf(cam.position.xyz) * sdfScaler;
    float m = -1.0;
    float z = 2.0 * r / (1.0 - m);   // = r initially
    int steps;

    for (steps = 0; steps < MAX_STEPS; steps++) {
        if (r < EPSILON || t + r >= MAX_DIST) break;

        float T   = t + z;
        vec3  pos = cam.position.xyz + rayDir * T;
        float R   = sdf(pos) * sdfScaler;

        if (z <= r + abs(R)) {
            float M = (R - r) / (T - t);
            m = (1.0 - beta) * m + beta * M;
            t = T;
            r = R;
        } else {
            m = -1.0;
        }
        z = 2.0 * r / (1.0 - m);
    }

    return turbo(float(steps) / 60.0);
}