vec4 qsqr(vec4 a) {
	return vec4(
		a.x*a.x - a.y*a.y - a.z*a.z - a.w*a.w,
		2.0*a.x*a.y,
		2.0*a.x*a.z,
		2.0*a.x*a.w
	);
}

float qlength2(vec4 q) { return dot(q, q); }

float sdf(vec3 pos) {
	vec4 c = vec4(scene.params.param0, scene.params.param1, scene.params.param2, scene.params.param3);
	vec4 z = vec4(pos, 0.0);
	float md2 = 1.0;
	float mz2 = dot(z, z);
	for (int i = 0; i < scene.iterations; i++) {
		md2 *= 4.0 * mz2;
		z = qsqr(z) + c;
		mz2 = qlength2(z);
		if (mz2 > 4.0) break;
	}
	return 0.25 * sqrt(mz2 / md2) * log(mz2);
}

float sdf_with_trap(vec3 pos, out float trap, out int iter_count) {
	vec4 c = vec4(scene.params.param0, scene.params.param1, scene.params.param2, scene.params.param3);
	vec4 z = vec4(pos, 0.0);
	float md2 = 1.0;
	float mz2 = dot(z, z);
	trap = 1e6;
	iter_count = scene.iterations;
	for (int i = 0; i < scene.iterations; i++) {
		md2 *= 4.0 * mz2;
		z = qsqr(z) + c;
		mz2 = qlength2(z);
		float r = max(length(z.xyz), 1e-4);
		float d = get_trap_distance(z.xyz);
		trap = min(trap, d / r);
		if (mz2 > 4.0) { iter_count = i; break; }
	}
	return 0.25 * sqrt(mz2 / md2) * log(mz2);
}