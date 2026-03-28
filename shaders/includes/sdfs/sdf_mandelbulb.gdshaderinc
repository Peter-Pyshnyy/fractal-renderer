//uniform float power = 8.0;     // mandelbulb power (8 = classic)
//uniform int iterations = 10;   // iteration count


float sdf(vec3 pos) {
    // early bounding sphere (cheap rejection)
    //float safeDist = length(pos) - 1.2;
    //if (safeDist > 0.1) {
        //return safeDist;
    //}

    vec3 z = pos;
    float r = 0.0;
    float dr = 1.0;
	float power = 8.0;
	int iterations = 10;

    // precompute constants
    float powerMinus1 = power - 1.0;

    for (int i = 0; i < iterations; i++) {
        r = length(z);
        if (r > 2.0) break; // escape radius

        // avoid division instability near zero
        float invR = 1.0 / max(r, 1e-6);

        // spherical coordinates
        float theta = acos(z.z * invR);
        float phi = atan(z.y, z.x);

        // derivative update (distance estimation)
        float rPow = pow(r, powerMinus1);
        dr = rPow * power * dr + 1.0;

        // scale + rotate
        float zr = rPow * r; // == pow(r, power)
        theta *= power;
        phi *= power;

        // back to cartesian
        float sinTheta = sin(theta);
        z = zr * vec3(
            sinTheta * cos(phi),
            sinTheta * sin(phi),
            cos(theta)
        ) + pos;
    }

    // distance estimation
    return 0.5 * log(r) * r / dr;
}