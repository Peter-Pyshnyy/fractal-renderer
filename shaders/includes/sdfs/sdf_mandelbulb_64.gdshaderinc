// ── Constants (lf suffix forces double literal in GLSL 4.0) ──────────────────
const double DP_PI      = 3.14159265358979323846264338327950288lf;
const double DP_TWO_PI  = 6.28318530717958647692528676655900576lf;
const double DP_PI_2    = 1.57079632679489661923132169163975144lf;
const double DP_PI_4    = 0.78539816339744830961566084581987572lf;
// tan(π/8) = √2 − 1  — atan range-reduction boundary
const double DP_TAN_PI8 = 0.41421356237309504880168872420969808lf;


double _sin_kernel(double x) {
    double x2 = x * x;
    return x * (1.0lf
        + x2 * (-1.66666666666666666667e-1lf   //  -1/3!
        + x2 * ( 8.33333333333333333333e-3lf   //  +1/5!
        + x2 * (-1.98412698412698412698e-4lf   //  -1/7!
        + x2 * ( 2.75573192239858906526e-6lf   //  +1/9!
        + x2 * (-2.50521083854417187751e-8lf   //  -1/11!
        + x2 * ( 1.60590438368216145994e-10lf  //  +1/13!
        + x2 * (-7.64716373181981647591e-13lf  //  -1/15!
        + x2 *   2.81145725434552076320e-15lf  //  +1/17!
        ))))))));
}

double _cos_kernel(double x) {
    double x2 = x * x;
    return 1.0lf
        + x2 * (-5.00000000000000000000e-1lf   //  -1/2!
        + x2 * ( 4.16666666666666666667e-2lf   //  +1/4!
        + x2 * (-1.38888888888888888889e-3lf   //  -1/6!
        + x2 * ( 2.48015873015873015873e-5lf   //  +1/8!
        + x2 * (-2.75573192239858906526e-7lf   //  -1/10!
        + x2 * ( 2.08767569878680989792e-9lf   //  +1/12!
        + x2 * (-1.14707455977297247129e-11lf  //  -1/14!
        + x2 *   4.77947733238738529740e-14lf  //  +1/16!
        )))))));
}

double _atan_kernel(double x) {
    double x2 = x * x;
    return x * (1.0lf
        + x2 * (-3.33333333333333333333e-1lf   //  -1/3
        + x2 * ( 2.00000000000000000000e-1lf   //  +1/5
        + x2 * (-1.42857142857142857143e-1lf   //  -1/7
        + x2 * ( 1.11111111111111111111e-1lf   //  +1/9
        + x2 * (-9.09090909090909090909e-2lf   //  -1/11
        + x2 * ( 7.69230769230769230769e-2lf   //  +1/13
        + x2 * (-6.66666666666666666667e-2lf   //  -1/15
        + x2 * ( 5.88235294117647058824e-2lf   //  +1/17
        + x2 * (-5.26315789473684210526e-2lf   //  -1/19
        + x2 * ( 4.76190476190476190476e-2lf   //  +1/21
        + x2 * (-4.34782608695652173913e-2lf   //  -1/23
        + x2 * ( 4.00000000000000000000e-2lf   //  +1/25
        + x2 * (-3.70370370370370370370e-2lf   //  -1/27
        + x2 * ( 3.44827586206896551724e-2lf   //  +1/29
        + x2 * (-3.22580645161290322581e-2lf   //  -1/31
        + x2 * ( 3.03030303030303030303e-2lf   //  +1/33
        + x2 * (-2.85714285714285714286e-2lf   //  -1/35
        + x2 * ( 2.70270270270270270270e-2lf   //  +1/37
        + x2 * (-2.56410256410256410256e-2lf   //  -1/39
        + x2 *   2.43902439024390243902e-2lf   //  +1/41
        ))))))))))))))))))));
}


// ── Public API ────────────────────────────────────────────────────────────────

// Range-reduce x into (−π, π], then map into [0, π/4] using symmetry/reflection.
double d_sin(double x) {
    // Step 1: reduce to (−π, π]
    x -= DP_TWO_PI * round(x / DP_TWO_PI);

    // Step 2: exploit sin(−x) = −sin(x)
    double sign = (x < 0.0lf) ? -1.0lf : 1.0lf;
    x = abs(x);   // now x ∈ [0, π]

    // Step 3: reflect into [0, π/2] then into [0, π/4]
    double result;
    if (x <= DP_PI_4) {
        result = _sin_kernel(x);
    } else if (x <= DP_PI_2) {
        result = _cos_kernel(DP_PI_2 - x);   // sin x = cos(π/2 − x)
    } else if (x <= 3.0lf * DP_PI_4) {
        result = _cos_kernel(x - DP_PI_2);   // sin x = cos(x − π/2)
    } else {
        result = _sin_kernel(DP_PI - x);     // sin x = sin(π − x)
    }

    return sign * result;
}

double d_cos(double x) {
    // cos is even; reduce to [0, π]
    x = abs(x - DP_TWO_PI * round(x / DP_TWO_PI));

    if (x <= DP_PI_4) {
        return  _cos_kernel(x);
    } else if (x <= DP_PI_2) {
        return  _sin_kernel(DP_PI_2 - x);    // cos x =  sin(π/2 − x)
    } else if (x <= 3.0lf * DP_PI_4) {
        return -_sin_kernel(x - DP_PI_2);    // cos x = −sin(x − π/2)
    } else {
        return -_cos_kernel(DP_PI - x);      // cos x = −cos(π − x)
    }
}

double d_atan(double x) {
    bool negative   = (x < 0.0lf);
    x = abs(x);

    bool reciprocal = (x > 1.0lf);
    if (reciprocal) x = 1.0lf / x;   // x now ∈ (0, 1]

    bool offset = (x > DP_TAN_PI8);
    if (offset) x = (x - 1.0lf) / (x + 1.0lf);  // x now ∈ (−tan(π/8), 0]

    double r = _atan_kernel(x);
    if (offset)    r += DP_PI_4;
    if (reciprocal) r  = DP_PI_2 - r;
    if (negative)  r  = -r;
    return r;
}

// Full atan2, matching GLSL atan(y,x) semantics.
double d_atan2(double y, double x) {
    if (x == 0.0lf) {
        if (y > 0.0lf) return  DP_PI_2;
        if (y < 0.0lf) return -DP_PI_2;
        return 0.0lf;   // both zero — undefined; 0 matches common GPU behaviour
    }
    double r = d_atan(y / x);
    if (x < 0.0lf) r += (y >= 0.0lf) ? DP_PI : -DP_PI;
    return r;
}

double d_acos(double x) {
    x = clamp(x, -1.0lf, 1.0lf);
    if (x >=  1.0lf) return 0.0lf;
    if (x <= -1.0lf) return DP_PI;
    return 2.0lf * d_atan(sqrt((1.0lf - x) / (1.0lf + x)));
}

float sdf(vec3 pos) {
    dvec3 dpos = dvec3(pos);
    dvec3 z    = dpos;

    double r   = 0.0lf;
    double dr  = 1.0lf;
    double power       = double(params.param1);
    int    iterations  = int(params.param0);
    double powerMinus1 = power - 1.0lf;

    for (int i = 0; i < iterations; i++) {
        r = length(z);
        if (r > 2.0lf) break;

        double invR  = 1.0lf / max(r, 1e-15lf);
        double rPow  = pow(r, powerMinus1);

        // acos and atan2 now fully double-precision
        double theta = d_acos(clamp(z.z * invR, -1.0lf, 1.0lf));
        double phi   = d_atan2(z.y, z.x);

        dr     = rPow * power * dr + 1.0lf;
        double zr = rPow * r;

        theta *= power;
        phi   *= power;

        // sin/cos now fully double-precision
        double sinTheta = d_sin(theta);
        double cosTheta = d_cos(theta);
        double sinPhi   = d_sin(phi);
        double cosPhi   = d_cos(phi);

        z = zr * dvec3(sinTheta * cosPhi,
                       sinTheta * sinPhi,
                       cosTheta) + dpos;
    }

    return float(0.5lf * log(r) * r / dr);
}

float sdf_with_trap(vec3 pos, out float trap) {
    dvec3 dpos = dvec3(pos);
    dvec3 z    = dpos;

    double r   = 0.0lf;
    double dr  = 1.0lf;
    double power       = double(params.param1);
    int    iterations  = int(params.param0);
    double powerMinus1 = power - 1.0lf;

    trap = 1e6;

    for (int i = 0; i < iterations; i++) {
        r = length(z);
        if (r > 2.0lf) break;

        double invR  = 1.0lf / max(r, 1e-15lf);
        double rPow  = pow(r, powerMinus1);

        double theta = d_acos(clamp(z.z * invR, -1.0lf, 1.0lf));
        double phi   = d_atan2(z.y, z.x);

        dr     = rPow * power * dr + 1.0lf;
        double zr = rPow * r;

        theta *= power;
        phi   *= power;

        double sinTheta = d_sin(theta);
        double cosTheta = d_cos(theta);
        double sinPhi   = d_sin(phi);
        double cosPhi   = d_cos(phi);

        z = zr * dvec3(sinTheta * cosPhi,
                       sinTheta * sinPhi,
                       cosTheta) + dpos;

        trap = min(get_trap_distance(vec3(z)), trap);
    }

    return float(0.5lf * log(r) * r / dr);
}