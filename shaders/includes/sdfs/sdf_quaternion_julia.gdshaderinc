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
	vec4 za = vec4(pos, 0.0);
	vec4 zb = vec4(0.0);
	vec4 dza = vec4(1.0, 0.0, 0.0, 0.0);
	vec4 dzb = vec4(0.0);
	vec4 cReal = vec4(scene.params.param0, scene.params.param1, scene.params.param2, scene.params.param3);
	vec4 cDual = vec4(scene.params.param4, scene.params.param5, scene.params.param6, scene.params.param7);
	float m2 = dot(za, za) + dot(zb, zb);
	for (int i = 0; i < scene.iterations; i++) {
		vec4 dza_new = 2.0 * qmul(za, dza);
		vec4 dzb_new = 2.0 * (qmul(za, dzb) + qmul(zb, dza));
		vec4 za_new  = qsqr(za) + cReal;
		vec4 zb_new  = qmul(za, zb) + qmul(zb, za) + cDual;
		dza = dza_new;
		dzb = dzb_new;
		za  = za_new;
		zb  = zb_new;
		m2 = dot(za, za) + dot(zb, zb);
		if (m2 > 10000.0) break;
	}
	float m = sqrt(m2);
	float dm = sqrt(dot(dza, dza) + dot(dzb, dzb));
	return 0.5 * log(m) * m / max(dm, 1e-8);
}

float sdf_with_color(vec3 pos, out float trap, out int iter_count) {
	vec4 za = vec4(pos, 0.0);
	vec4 zb = vec4(0.0);
	vec4 dza = vec4(1.0, 0.0, 0.0, 0.0);
	vec4 dzb = vec4(0.0);
	vec4 cReal = vec4(scene.params.param0, scene.params.param1, scene.params.param2, scene.params.param3);
	vec4 cDual = vec4(scene.params.param4, scene.params.param5, scene.params.param6, scene.params.param7);
	float m2 = dot(za, za) + dot(zb, zb);
	trap = 1e6;
	iter_count = scene.iterations;
	for (int i = 0; i < scene.iterations; i++) {
		vec4 dza_new = 2.0 * qmul(za, dza);
		vec4 dzb_new = 2.0 * (qmul(za, dzb) + qmul(zb, dza));
		vec4 za_new  = qsqr(za) + cReal;
		vec4 zb_new  = qmul(za, zb) + qmul(zb, za) + cDual;
		dza = dza_new;
		dzb = dzb_new;
		za  = za_new;
		zb  = zb_new;
		m2 = dot(za, za) + dot(zb, zb);
		float r = sqrt(m2);
		trap = min(get_trap_distance(za.yzw + zb.yzw) / max(r, 1e-8), trap);
		if (m2 > 10000.0) { iter_count = i; break; }
	}
	float m = sqrt(m2);
	float dm = sqrt(dot(dza, dza) + dot(dzb, dzb));
	return 0.5 * log(m) * m / max(dm, 1e-8);
}
