float sdf(vec3 pos) {
	vec3 z = pos;
	float scale = scene.params.param0;
	float alpha = scene.params.param1;
	float beta  = scene.params.param2;
	float limit = 0.8;

	float ca = cos(alpha), sa = sin(alpha);
	float cb = cos(beta),  sb = sin(beta);

	int n = 0;
	for (int i = 0; i < scene.iterations; i++) {
		if (z.x + z.y < 0.0) z.xy = -z.yx;
		if (z.x + z.z < 0.0) z.xz = -z.zx;
		if (z.y + z.z < 0.0) z.zy = -z.yz;

		z = z * scale - limit * (scale - 1.0);

		z.xz = vec2(ca * z.x - sa * z.z, sa * z.x + ca * z.z);
		z.yz = vec2(cb * z.y - sb * z.z, sb * z.y + cb * z.z);
		n++;
		
	}
	return length(z) * pow(scale, -float(n));
}

float sdf_with_color(vec3 pos, out float trap, out int iter_count) {
	vec3 z = pos;
	float scale = scene.params.param0;
	float alpha = scene.params.param1;
	float beta  = scene.params.param2;
	float limit = 0.8;

	float ca = cos(alpha), sa = sin(alpha);
	float cb = cos(beta),  sb = sin(beta);

	trap = 1e6;
	iter_count = scene.iterations;

	int n = 0;
	for (int i = 0; i < scene.iterations; i++) {
		if (z.x + z.y < 0.0) z.xy = -z.yx;
		if (z.x + z.z < 0.0) z.xz = -z.zx;
		if (z.y + z.z < 0.0) z.zy = -z.yz;

		z = z * scale - limit * (scale - 1.0);

		z.xz = vec2(ca * z.x - sa * z.z, sa * z.x + ca * z.z);
		z.yz = vec2(cb * z.y - sb * z.z, sb * z.y + cb * z.z);

		float r = max(length(z), 1e-4);
		float d = get_trap_distance(z);
		trap = min(trap, d / r);

		n++;
	}
	return length(z) * pow(scale, -float(n));
}
