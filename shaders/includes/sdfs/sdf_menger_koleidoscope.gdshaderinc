float sdf(vec3 pos) {
	vec3 z = pos;
	float scale = scene.params.param0;
	float alpha = scene.params.param1;
	float beta  = scene.params.param2;
	float c     = 0.8;
	float ca = cos(alpha), sa = sin(alpha);
	float cb = cos(beta),  sb = sin(beta);
	float bailout = 100.0;
	float r2 = 0.0;
	int n = 0;
	for (int i = 0; i < scene.iterations; i++) {
		z.xz = vec2(ca * z.x - sa * z.z, sa * z.x + ca * z.z);
		z = abs(z);
		if (z.x - z.y < 0.0) z.xy = z.yx;
		if (z.x - z.z < 0.0) z.xz = z.zx;
		if (z.y - z.z < 0.0) z.yz = z.zy;
		z.xz = vec2(cb * z.x - sb * z.z, sb * z.x + cb * z.z);
		z.x = scale * (z.x - c) + c;
		z.y = scale * (z.y - c) + c;
		z.z = scale * z.z;
		if (z.z > c * (scale - 1.0) * 0.5) z.z = z.z - c * (scale - 1.0);
		n++;
		r2 = dot(z, z);
		if (r2 > bailout) break;
	}
	return (sqrt(r2) - 2.0) * pow(scale, -float(n));
}

float sdf_with_trap(vec3 pos, out float trap) {
	vec3 z = pos;
	float scale = scene.params.param0;
	float alpha = scene.params.param1;
	float beta  = scene.params.param2;
	float c     = 0.8;
	float ca = cos(alpha), sa = sin(alpha);
	float cb = cos(beta),  sb = sin(beta);
	float bailout = 100.0;
	float r2 = 0.0;
	int n = 0;
	trap = 1e6;
	for (int i = 0; i < scene.iterations; i++) {
		z.xz = vec2(ca * z.x - sa * z.z, sa * z.x + ca * z.z);
		z = abs(z);
		if (z.x - z.y < 0.0) z.xy = z.yx;
		if (z.x - z.z < 0.0) z.xz = z.zx;
		if (z.y - z.z < 0.0) z.yz = z.zy;
		z.xz = vec2(cb * z.x - sb * z.z, sb * z.x + cb * z.z);
		z.x = scale * (z.x - c) + c;
		z.y = scale * (z.y - c) + c;
		z.z = scale * z.z;
		if (z.z > c * (scale - 1.0) * 0.5) z.z = z.z - c * (scale - 1.0);
		float r = max(length(z), 1e-4);
		float d = get_trap_distance(z);
		trap = min(trap, d / r);
		n++;
		r2 = dot(z, z);
		if (r2 > bailout) break;
	}
	return (sqrt(r2) - 2.0) * pow(scale, -float(n));
}