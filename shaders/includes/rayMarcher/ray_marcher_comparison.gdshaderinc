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

vec3 magma(float t) {
    t = clamp(t, 0.0, 1.0);
    const vec3 c0 = vec3(-0.002136485053939582, -0.000749655052795221, -0.005386127855323933);
    const vec3 c1 = vec3( 0.2516605407371642,    0.6775232436837668,    2.494026599312351);
    const vec3 c2 = vec3( 8.353717279216625,    -3.577719514958484,     0.3144679030132573);
    const vec3 c3 = vec3(-27.66873308576866,    14.26473078096533,    -13.64921318813922);
    const vec3 c4 = vec3( 52.17613981234068,   -27.94360607168351,    12.94416944238394);
    const vec3 c5 = vec3(-50.76852536473588,    29.04658282127291,     4.23415299384598);
    const vec3 c6 = vec3( 18.65570506591883,   -11.48977351997711,    -5.601961508734096);
    vec3 col = c0 + t*(c1 + t*(c2 + t*(c3 + t*(c4 + t*(c5 + t*c6)))));
	return pow(col, vec3(2.2));
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

    return magma(float(steps) / 85.0);
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

    return magma(float(steps) / 85.0);
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

    return magma(float(steps) / 85.0);
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

    return magma(float(steps) / 85.0);
}