float sdf(vec3 pos) {
    vec3 z = pos;
    float r = 0.0;
    float dr = 1.0;
    float power = params.param1;
    float iterations = params.param0;
    float powerMinus1 = power - 1.0;

    for (int i = 0; i < iterations; i++) {
        r = length(z);
        if (r > 2.0) break;

        float invR = 1.0 / max(r, 1e-8);
        float theta = acos(clamp(z.z * invR, -1.0, 1.0));
        float phi = atan(z.y, z.x);
        float rPow = pow(r, powerMinus1);
        dr = rPow * power * dr + 1.0;
        float zr = rPow * r;
        theta *= power;
        phi *= power;
        float sinTheta = sin(theta);
        z = zr * vec3(sinTheta * cos(phi), sinTheta * sin(phi), cos(theta)) + pos;
    }
    return 0.5 * log(r) * r / dr;
}

float sdf_with_trap(vec3 pos, out float trap, out float trap_ref) {
    vec3 z = pos;
    float r = 0.0;
    float dr = 1.0;
    float power = params.param1;
    float iterations = params.param0;
    float powerMinus1 = power - 1.0;

    trap = 1e6;
	trap_ref = 0;

    for (int i = 0; i < iterations; i++) {
        r = length(z);
        if (r > 2.0) break;

        float invR = 1.0 / max(r, 1e-8);
        float theta = acos(clamp(z.z * invR, -1.0, 1.0));
        float phi = atan(z.y, z.x);
        float rPow = pow(r, powerMinus1);
        dr = rPow * power * dr + 1.0;
        float zr = rPow * r;
        theta *= power;
        phi *= power;
        float sinTheta = sin(theta);
        z = zr * vec3(sinTheta * cos(phi), sinTheta * sin(phi), cos(theta)) + pos;

        trap = min(get_trap_distance(z), trap);
		trap_ref = max(r, trap_ref);
    }
    return 0.5 * log(r) * r / dr;
}