float sdf(vec3 pos) {
	vec3 z = pos;
	vec3 c = pos;
	float scale       = scene.params.param0;
	float fixedRadius = scene.params.param1;
	float minRadius   = scene.params.param2;
	float fR2 = fixedRadius * fixedRadius;
	float mR2 = minRadius * minRadius;
	float DEfactor = scale;
	for (int i = 0; i < scene.iterations; i++) {
		if (z.x >  1.0) z.x =  2.0 - z.x;
		else if (z.x < -1.0) z.x = -2.0 - z.x;
		if (z.y >  1.0) z.y =  2.0 - z.y;
		else if (z.y < -1.0) z.y = -2.0 - z.y;
		if (z.z >  1.0) z.z =  2.0 - z.z;
		else if (z.z < -1.0) z.z = -2.0 - z.z;
		float r2 = dot(z, z);
		if (r2 < mR2) { z *= fR2 / mR2; DEfactor *= fR2 / mR2; }
		else if (r2 < fR2) { z *= fR2 / r2; DEfactor *= fR2 / r2; }
		z = z * scale + c;
		DEfactor *= scale;
	}
	return length(z) / abs(DEfactor);
}
float sdf_with_trap(vec3 pos, out float trap) {
	vec3 z = pos;
	vec3 c = pos;
	float scale = scene.params.param0;
	float fixedRadius = scene.params.param1;
	float minRadius = scene.params.param2;
	float fR2 = fixedRadius * fixedRadius;
	float mR2 = minRadius * minRadius;
	float DEfactor = scale;
	trap = 1e6;
	for (int i = 0; i < scene.iterations; i++) {
		if (z.x >  1.0) z.x =  2.0 - z.x; else if (z.x < -1.0) z.x = -2.0 - z.x;
		if (z.y >  1.0) z.y =  2.0 - z.y; else if (z.y < -1.0) z.y = -2.0 - z.y;
		if (z.z >  1.0) z.z =  2.0 - z.z; else if (z.z < -1.0) z.z = -2.0 - z.z;
		float r2 = dot(z, z);
		if (r2 < mR2) { z *= fR2 / mR2; DEfactor *= fR2 / mR2; }
		else if (r2 < fR2) { z *= fR2 / r2; DEfactor *= fR2 / r2; }
		z = z * scale + c;
		DEfactor *= scale;
		float r = max(length(z), 1e-4);
		float d = get_trap_distance(z);
		trap = min(trap, d / r);
	}
	return length(z) / abs(DEfactor);
}
