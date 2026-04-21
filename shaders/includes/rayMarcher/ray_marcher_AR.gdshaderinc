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
    float sdfScaler = 0.75;
    float beta = 0.3;
    float pixelRadius = cam.fovScale / cam.resolution.y;

    float t = 0.0;
    float r = sdf(cam.position.xyz);
    float z = r;
    float m = -1.0;

    float bestT    = t;
    float bestError = 1e9;

    for (int i = 0; i < MAX_STEPS; i++) {
        float pixelError = r / max(t * pixelRadius * 0.75, 1e-7);

        if (pixelError < bestError) {
            bestError = pixelError;
            bestT     = t;
        }

        if (pixelError < 1.0 || t + r >= MAX_DIST) break;

        float T = t + z;
        vec3  pos = cam.position.xyz + rayDir * T;
        
        // Знову використовуємо ШВИДКУ sdf
        float R = sdf(pos) * (sdfScaler);

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

    float hit_trap;
    vec3 hit_pos = cam.position.xyz + rayDir * bestT;
    sdf_with_trap(hit_pos, hit_trap);
    hit_trap = log(hit_trap + 1.0);
    float trap_normalized = exp(-hit_trap * 15.0);

	float normal_h = clamp(bestT * pixelRadius * 0.75, 1e-7, 0.01);
	vec3 norm = calcNormal(hit_pos, normal_h);
	
	float ao = calcAO(hit_pos, norm);
	vec3 albedo = get_trap_color_hsv(trap_normalized);
	albedo = mix(vec3(1.0), albedo, 0.85);
	vec3 color = PBR(norm, normal_h, -rayDir, hit_pos, albedo,  ao);
    return color;
}