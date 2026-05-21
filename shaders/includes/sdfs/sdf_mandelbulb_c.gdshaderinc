float sdf(vec3 pos) {
	vec3 z = pos;
	float r = 0.0;
	float dr = 1.0;
	float power = scene.params.param0;
	float powerMinus1 = power - 1.0;
	float t = scene.params.param1;
	float phaseAngle = scene.params.param2;
	float cosA = cos(phaseAngle);
	float sinA = sin(phaseAngle);

	for (int i = 0; i < scene.iterations; i++) {
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
		z = zr * vec3(sinTheta * cos(phi), sinTheta * sin(phi), cos(theta));

		float fi = float(i);
		z += 0.2 * vec3(
			sin(0.5 * t + 0.1 * fi),
			cos(0.3 * t + 0.2 * fi),
			sin(0.4 * t + 0.15 * fi)
		);
		z.xy = vec2(cosA * z.x - sinA * z.y, sinA * z.x + cosA * z.y);
		z += pos;
	}

	return 0.5 * log(r) * r / dr;
}

float sdf_with_trap(vec3 pos, out float trap) {
	vec3 z = pos;
	float r = 0.0;
	float dr = 1.0;
	float power = scene.params.param0;
	float powerMinus1 = power - 1.0;
	float t = scene.params.param1;
	float phaseAngle = scene.params.param2;
	float cosA = cos(phaseAngle);
	float sinA = sin(phaseAngle);
	trap = 1e6;

	for (int i = 0; i < scene.iterations; i++) {
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
		z = zr * vec3(sinTheta * cos(phi), sinTheta * sin(phi), cos(theta));

		float fi = float(i);
		z += 0.2 * vec3(
			sin(0.5 * t + 0.1 * fi),
			cos(0.3 * t + 0.2 * fi),
			sin(0.4 * t + 0.15 * fi)
		);
		z.xy = vec2(cosA * z.x - sinA * z.y, sinA * z.x + cosA * z.y);
		z += pos;
		trap = min(get_trap_distance(z) / r, trap);
	}

	return 0.5 * log(r) * r / dr;
}
