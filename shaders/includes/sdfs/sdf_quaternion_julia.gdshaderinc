vec4 qsqr(vec4 q) {
	return vec4(
		q.x * q.x - q.y * q.y - q.z * q.z - q.w * q.w,
		2.0 * q.x * q.y,
		2.0 * q.x * q.z,
		2.0 * q.x * q.w
	);
}

vec4 qmul(vec4 a, vec4 b) {
	return vec4(
		a.x * b.x - a.y * b.y - a.z * b.z - a.w * b.w,
		a.x * b.y + a.y * b.x + a.z * b.w - a.w * b.z,
		a.x * b.z - a.y * b.w + a.z * b.x + a.w * b.y,
		a.x * b.w + a.y * b.z - a.z * b.y + a.w * b.x
	);
}

float sdf(vec3 pos) {
	vec4 za = vec4(pos.x, pos.y, 0.0, 0.0);
	vec4 zb = vec4(pos.z, 0.0, 0.0, 0.0);
	vec4 dza = vec4(1.0, 0.0, 0.0, 0.0);
	vec4 dzb = vec4(1.0, 0.0, 0.0, 0.0);
	vec4 cReal = vec4(scene.params.param1, scene.params.param2, scene.params.param3, scene.params.param4);
	vec4 cDual = vec4(scene.params.param5, scene.params.param6, scene.params.param7, 0.0);
	float m2 = dot(za, za) + dot(zb, zb);

	for (int i = 0; i < scene.iterations; i++) {
		dza = 2.0 * qmul(za, dza);
		dzb = 2.0 * qmul(zb, dzb);
		za = qsqr(za) + cReal;
		zb = qsqr(zb) + cDual;
		m2 = dot(za, za) + dot(zb, zb);
		if (m2 > 4.0) break;
	}

	float m = sqrt(m2);
	float dm = sqrt(dot(dza, dza) + dot(dzb, dzb));
	return 0.5 * log(m) * m / max(dm, 1e-8);
}

float sdf_with_trap(vec3 pos, out float trap) {
	vec4 za = vec4(pos.x, pos.y, 0.0, 0.0);
	vec4 zb = vec4(pos.z, 0.0, 0.0, 0.0);
	vec4 dza = vec4(1.0, 0.0, 0.0, 0.0);
	vec4 dzb = vec4(1.0, 0.0, 0.0, 0.0);
	vec4 cReal = vec4(scene.params.param1, scene.params.param2, scene.params.param3, scene.params.param4);
	vec4 cDual = vec4(scene.params.param5, scene.params.param6, scene.params.param7, 0.0);
	float m2 = dot(za, za) + dot(zb, zb);
	trap = 1e6;

	for (int i = 0; i < scene.iterations; i++) {
		dza = 2.0 * qmul(za, dza);
		dzb = 2.0 * qmul(zb, dzb);
		za = qsqr(za) + cReal;
		zb = qsqr(zb) + cDual;
		m2 = dot(za, za) + dot(zb, zb);
		float r = sqrt(m2);
		vec3 z3 = vec3(za.x, za.y, zb.x);
		trap = min(get_trap_distance(z3) / max(r, 1e-8), trap);
		if (m2 > 4.0) break;
	}

	float m = sqrt(m2);
	float dm = sqrt(dot(dza, dza) + dot(dzb, dzb));
	return 0.5 * log(m) * m / max(dm, 1e-8);
}
