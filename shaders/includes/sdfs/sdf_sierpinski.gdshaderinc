float sdf(vec3 pos) {
    vec3 z = pos;
    float iterations = params.param0;
    float scale   = params.param1;
    float offset  = params.param2;
    float angleX  = params.param2;
	float angleY = 0.0;

    float cx = cos(angleX), sx = sin(angleX);
    float cy = cos(angleY), sy = sin(angleY);

    for (int i = 0; i < iterations; i++) {
        // Rotation around X
        z.yz = vec2(cx * z.y - sx * z.z, sx * z.y + cx * z.z);

        // Sierpinski tetrahedral folds
        if (z.x + z.y < 0.0) z.xy = -z.yx;
        if (z.x + z.z < 0.0) z.xz = -z.zx;
        if (z.y + z.z < 0.0) z.yz = -z.zy;

        // Rotation around Y
        z.xz = vec2(cy * z.x + sy * z.z, -sy * z.x + cy * z.z);

        // Scale and translate toward vertex (1,1,1)
        z = z * scale - offset * (scale - 1.0);
    }

    return length(z) * pow(scale, -iterations);
}

float sdf_with_trap(vec3 pos, out float trap) {
    vec3 z = pos;
    float iterations = params.param0;
    float scale   = params.param1;
    float offset  = params.param2;
    float angleX  = params.param2;
	float angleY = 0.0;

    float cx = cos(angleX), sx = sin(angleX);
    float cy = cos(angleY), sy = sin(angleY);

    trap = 1e6;

    for (int i = 0; i < iterations; i++) {
        z.yz = vec2(cx * z.y - sx * z.z, sx * z.y + cx * z.z);

        if (z.x + z.y < 0.0) z.xy = -z.yx;
        if (z.x + z.z < 0.0) z.xz = -z.zx;
        if (z.y + z.z < 0.0) z.yz = -z.zy;

        z.xz = vec2(cy * z.x + sy * z.z, -sy * z.x + cy * z.z);

        z = z * scale - offset * (scale - 1.0);

        trap = min(get_trap_distance(z), trap);
    }

    return length(z) * pow(scale, -iterations);
}