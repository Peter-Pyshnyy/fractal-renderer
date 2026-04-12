dvec3 getRayDirection64(vec2 resolution, vec2 uv) {
    double aspect = double(resolution.x) / double(resolution.y);

    dvec2 screen = dvec2(uv) * 2.0 - 1.0;
    screen.x *= aspect;
    screen *= double(cam.fovScale);

    return normalize(
        dvec3(cam.forward.xyz) +
        dvec3(cam.right.xyz) * screen.x +
        dvec3(cam.up.xyz) * screen.y
    );
}

vec3 raymarch_AR64(dvec3 rayDir) {
    double sdfScaler = 0.75;
    double beta = 0.3;
    double pixelRadius = double(cam.fovScale) / double(cam.resolution.y);

    double t = 0.0;
    double r = sdf64(dvec3(cam.position.xyz));
    double z = r;
    double m = -1.0;

    double bestT = t;
    double bestError = 1e18;

    for (int i = 0; i < MAX_STEPS; i++) {
        double pixelError = r / max(t * pixelRadius * 0.75, 1e-12);

        if (pixelError < bestError) {
            bestError = pixelError;
            bestT = t;
        }

        if (pixelError < 1.0 || t + r >= double(MAX_DIST)) {
            break;
        }

        double T = t + z;
        dvec3 pos = dvec3(cam.position.xyz) + rayDir * T;
        double R = sdf64(pos) * sdfScaler;

        if (z <= r + abs(R)) {
            double M = (R - r) / max(T - t, 1e-12);
            m = (1.0 - beta) * m + beta * M;
            t = T;
            r = R;
        } else {
            m = -1.0;
        }

        z = 2.0 * r / max(1.0 - m, 1e-12);
    }

    if (bestError >= 1.0 || bestT >= double(MAX_DIST)) {
        return vec3(0.0);
    }

    double hit_trap64;
    dvec3 hit_pos64 = dvec3(cam.position.xyz) + rayDir * bestT;
    sdf_with_trap64(hit_pos64, hit_trap64);

    float hit_trap = float(log(hit_trap64 + 1.0));
    float trap_normalized = exp(-hit_trap * 15.0);

    vec3 hit_pos = vec3(hit_pos64);
    float normal_h = clamp(float(bestT * pixelRadius * 0.75), 1e-7, 0.01);
    vec3 norm = calcNormal(hit_pos, normal_h);

    float ao = calcAO(hit_pos, norm);
    vec3 albedo = get_trap_color_hsv(trap_normalized);
    vec3 color = PBR(norm, normal_h, -vec3(rayDir), hit_pos, albedo, ao);
    return color;
}
