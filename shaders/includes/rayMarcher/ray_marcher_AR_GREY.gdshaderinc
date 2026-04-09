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


vec3 raymarch_AR(vec3 rayDir) {
	float steps = 0.0;
    float sdfScaler = params.param2;
    float beta = 0.3;
    float pixelRadius = cam.fovScale / cam.resolution.y;

    float t = 0.0;
    // Використовуємо ШВИДКУ sdf (без пастки!)
    float r = sdf(cam.position.xyz) * (sdfScaler / float(resolution_scale));
    float z = r;
    float m = -1.0;

    float bestT    = t;
    float bestError = 1e9;

    for (int i = 1; i < MAX_STEPS; i++) {
		steps++;
        float pixelError = r / max(t * pixelRadius * params.param3 * float(resolution_scale), 1e-9);

        if (pixelError < bestError) {
            bestError = pixelError;
            bestT     = t;
        }

        if (pixelError < 1.0 || t + r >= MAX_DIST) break;

        float T = t + z;
        vec3  pos = cam.position.xyz + rayDir * T;
        
        // Знову використовуємо ШВИДКУ sdf
        float R = sdf(pos) * (sdfScaler / float(resolution_scale));

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

    if (bestError >= 1.0 || bestT >= MAX_DIST) {
        return vec3(0.0);
    }

    float s0    = 1.0 - steps / float(MAX_STEPS);
    float s1    = 1.0 - (0.5 + 0.5 * sin(steps * 0.01));
    float shade = mix(s0, s1, 0.5);
    return vec3(shade);
}