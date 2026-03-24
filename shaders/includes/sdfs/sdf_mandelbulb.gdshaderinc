uniform float power = 8.0; // The "Power" of the Mandelbulb (8 is standard)
uniform int iterations = 10; // Complexity of the fractal

float sdf(vec3 pos) {
    vec3 z = pos;
    float dr = 1.0;
    float r = 0.0;

	// Розраховуємо відстань до безпечної обмежувальної сфери (радіус 1.2)
    float safe_dist = length(pos) - 1.2;

    // Якщо ми ще далеко від фрактала, безпечно крокуємо до сфери.
    // Якщо ми близько (менше ніж 0.1 одиниці до сфери), використовуємо точний SDF фрактала.
	// early exit
    if (safe_dist > 0.1) {
        return safe_dist;
    }

    for (int i = 0; i < iterations; i++) {
        r = length(z);
        if (r > 2.0) break; // Escape radius

        // Convert to polar coordinates
        float theta = acos(z.z / r);
        float phi = atan(z.y, z.x);

        // Scale the derivative for distance estimation
        dr = pow(r, power - 1.0) * power * dr + 1.0;

        // Scale and rotate the point
        float zr = pow(r, power);
        theta = theta * power;
        phi = phi * power;

        // Convert back to cartesian coordinates
        z = zr * vec3(sin(theta) * cos(phi), sin(phi) * sin(theta), cos(theta));
        z += pos;
    }

    // Розраховуємо оцінку відстані фрактала
    float fractal_dist = 0.5 * log(r) * r / dr;



    return fractal_dist;
}