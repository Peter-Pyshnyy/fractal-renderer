float sdf(vec3 pos) {
    vec3 z = pos;
    int   iters  = int(params.param0);
    float scale  = params.param1;
    float offset = 1.0;
    float alpha  = params.param2;
    float beta   = params.param3;

    float ca = cos(alpha), sa = sin(alpha);
    float cb = cos(beta),  sb = sin(beta);

    int n = 0;
    for (int i = 0; i < iters; i++) {
        if (z.x + z.y < 0.0) z.xy = -z.yx;
        if (z.x + z.z < 0.0) z.xz = -z.zx;
        if (z.y + z.z < 0.0) z.zy = -z.yz;

        z = z * scale - offset * (scale - 1.0);

        z.xz = vec2(ca * z.x - sa * z.z, sa * z.x + ca * z.z);
        z.yz = vec2(cb * z.y - sb * z.z, sb * z.y + cb * z.z);
        n++;
    }
    return length(z) * pow(scale, -float(n));
}

float sdf_with_trap(vec3 pos, out float trap) {
    vec3 z = pos;
    int   iters  = int(params.param0);
    float scale  = params.param1;
    float offset = 1.0;
    float alpha  = params.param2;
    float beta   = params.param3;

    float ca = cos(alpha), sa = sin(alpha);
    float cb = cos(beta),  sb = sin(beta);

    trap = 1e6;
	
    int n = 0;
    for (int i = 0; i < iters; i++) {
        if (z.x + z.y < 0.0) z.xy = -z.yx;
        if (z.x + z.z < 0.0) z.xz = -z.zx;
        if (z.y + z.z < 0.0) z.zy = -z.yz;

        z = z * scale - offset * (scale - 1.0);

        z.xz = vec2(ca * z.x - sa * z.z, sa * z.x + ca * z.z);
        z.yz = vec2(cb * z.y - sb * z.z, sb * z.y + cb * z.z);

        float r = max(length(z), 1e-4);
        float d = get_trap_distance(z);
        trap = min(trap, d / r);

        n++;
    }
    return length(z) * pow(scale, -float(n));
}