float sdf(vec3 pos);
float sdf_with_trap(vec3 pos, out float trap);

double sdf64(dvec3 pos) {
    dvec3 z = pos;
    double r = 0.0;
    double dr = 1.0;
    double power = double(params.param1);
    int iterations = int(params.param0);
    double powerMinus1 = power - 1.0;

    for (int i = 0; i < iterations; i++) {
        r = length(z);
        if (r > 2.0) {
            break;
        }

        double invR = 1.0 / max(r, 1e-12);
        double theta = acos(clamp(z.z * invR, -1.0, 1.0));
        double phi = atan(z.y, z.x);
        double rPow = pow(r, powerMinus1);
        dr = rPow * power * dr + 1.0;
        double zr = rPow * r;
        theta *= power;
        phi *= power;
        double sinTheta = sin(theta);

        z = zr * dvec3(
            sinTheta * cos(phi),
            sinTheta * sin(phi),
            cos(theta)
        ) + pos;
    }

    return 0.5 * log(max(r, 1e-12)) * r / max(dr, 1e-12);
}

double sdf_with_trap64(dvec3 pos, out double trap) {
    dvec3 z = pos;
    double r = 0.0;
    double dr = 1.0;
    double power = double(params.param1);
    int iterations = int(params.param0);
    double powerMinus1 = power - 1.0;

    trap = 1e12;

    for (int i = 0; i < iterations; i++) {
        r = length(z);
        if (r > 2.0) {
            break;
        }

        double invR = 1.0 / max(r, 1e-12);
        double theta = acos(clamp(z.z * invR, -1.0, 1.0));
        double phi = atan(z.y, z.x);
        double rPow = pow(r, powerMinus1);
        dr = rPow * power * dr + 1.0;
        double zr = rPow * r;
        theta *= power;
        phi *= power;
        double sinTheta = sin(theta);

        z = zr * dvec3(
            sinTheta * cos(phi),
            sinTheta * sin(phi),
            cos(theta)
        ) + pos;

        trap = min(double(get_trap_distance(vec3(z))), trap);
    }

    return 0.5 * log(max(r, 1e-12)) * r / max(dr, 1e-12);
}

float sdf(vec3 pos) {
    return float(sdf64(dvec3(pos)));
}

float sdf_with_trap(vec3 pos, out float trap) {
    double trap64;
    double dist64 = sdf_with_trap64(dvec3(pos), trap64);
    trap = float(trap64);
    return float(dist64);
}
