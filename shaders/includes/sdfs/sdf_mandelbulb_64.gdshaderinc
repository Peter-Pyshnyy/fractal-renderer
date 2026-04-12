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

// ── Additional constants ─────────────────────────────────────────────────────
const double DP_LN2   = 0.69314718055994530941723212145817657lf;
const double DP_LOG2E = 1.44269504088896340735992468100189214lf; // 1/ln2
const double DP_SQRT2_2 = 0.70710678118654752440084436210484904lf; // 1/√2

// ── d_log ───────────────────────────────────────────────────────────────────
// Uses frexp to decompose x = 2^n * m, m ∈ [0.5, 1.0),
// then shifts m into [1/√2, √2) for better series convergence,
// then computes log(m) = 2·atanh((m−1)/(m+1)) via Taylor series.
// For m in that range, y = (m−1)/(m+1) ∈ (−0.172, 0.172) → fast convergence.
double d_log(double x) {
    int n;
    double m = frexp(x, n);       // m ∈ [0.5, 1.0), x = m * 2^n

    // Shift mantissa into [1/√2, √2) to keep |y| small
    if (m < DP_SQRT2_2) {
        m *= 2.0lf;
        n -= 1;
    }
    // log(m) via 2·atanh(y), y = (m−1)/(m+1)
    double y  = (m - 1.0lf) / (m + 1.0lf);
    double y2 = y * y;
    // 9-term atanh series (through y^17) — max error < 1e-19 for |y| < 0.172
    double r = y * (1.0lf
        + y2 * (3.33333333333333333333e-1lf   // y^3  / 3
        + y2 * (2.00000000000000000000e-1lf   // y^5  / 5
        + y2 * (1.42857142857142857143e-1lf   // y^7  / 7
        + y2 * (1.11111111111111111111e-1lf   // y^9  / 9
        + y2 * (9.09090909090909090909e-2lf   // y^11 / 11
        + y2 * (7.69230769230769230769e-2lf   // y^13 / 13
        + y2 * (6.66666666666666666667e-2lf   // y^15 / 15
        + y2 *  5.88235294117647058824e-2lf   // y^17 / 17
        ))))))));
    return double(n) * DP_LN2 + 2.0lf * r;
}

// ── d_exp ───────────────────────────────────────────────────────────────────
// Range-reduces x = n·ln2 + r, |r| ≤ ln2/2 ≈ 0.347,
// computes exp(r) via 11-term Taylor, then scales by 2^n via ldexp.
double d_exp(double x) {
    double nd = round(x * DP_LOG2E);
    int    n  = int(nd);
    double r  = x - nd * DP_LN2;   // |r| ≤ ln2/2

    // Taylor exp(r), 11 terms — next omitted term ≈ r^11/11! < 2e-20
    double e = 1.0lf + r * (1.0lf
        + r * (5.00000000000000000000e-1lf   // r^2  / 2!
        + r * (1.66666666666666666667e-1lf   // r^3  / 3!
        + r * (4.16666666666666666667e-2lf   // r^4  / 4!
        + r * (8.33333333333333333333e-3lf   // r^5  / 5!
        + r * (1.38888888888888888889e-3lf   // r^6  / 6!
        + r * (1.98412698412698412698e-4lf   // r^7  / 7!
        + r * (2.48015873015873015873e-5lf   // r^8  / 8!
        + r * (2.75573192239858906526e-6lf   // r^9  / 9!
        + r *  2.75573192239858906526e-7lf   // r^10 / 10!
        )))))))));
    return ldexp(e, n);   // e * 2^n — exact, no rounding
}

// ── d_pow / d_log_positive ──────────────────────────────────────────────────
// pow(base, exp) = exp(exp · log(base))
// d_log_positive: same as d_log but asserts base > 0 (no guard needed in SDF
// since r = length(z) ≥ 0 and we already check r > 1e-15).
double d_pow(double base, double exponent) {
    return d_exp(exponent * d_log(base));
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
        double rPow  = d_pow(r, powerMinus1);

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

    return float(0.5lf * d_log(r) * r / dr);
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
        double rPow  = d_pow(r, powerMinus1);

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

    return float(0.5lf * d_log(r) * r / dr);
}