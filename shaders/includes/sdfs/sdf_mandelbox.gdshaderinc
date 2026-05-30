float sdf(vec3 pos) {
	vec3 z = pos;
	vec3 c = pos;
	float scale       = -2.1;
	float fixedRadius = 1.0;
	float minRadius       = 0.5;
	float limit   = 0.4;

	float fR2 = fixedRadius * fixedRadius;
	float mR2 = minRadius * minRadius;
	float DEfactor = scale;

	for (int i = 0; i < scene.iterations; i++) {
		if (z.x >  limit) z.x =  2.0 * limit - z.x;
		else if (z.x < -limit) z.x = -2.0 * limit - z.x;
		
		if (z.y >  limit) z.y =  2.0 * limit - z.y;
		else if (z.y < -limit) z.y = -2.0 * limit - z.y;
		
		if (z.z >  limit) z.z =  2.0 * limit - z.z;
		else if (z.z < -limit) z.z = -2.0 * limit - z.z;

		float r2 = dot(z, z);
		if (r2 < mR2) { z *= fR2 / mR2; DEfactor *= fR2 / mR2; }
		else if (r2 < fR2) { z *= fR2 / r2; DEfactor *= fR2 / r2; }
		
		z = z * scale + c;
		DEfactor *= scale;
	}
	
	return length(z) / abs(DEfactor);
}

float sdf_with_color(vec3 pos, out float trap, out int iter_count) {
	vec3 z = pos;
	vec3 c = pos;
	float scale = scene.params.param0;
	float fixedRadius = scene.params.param1;
	float minRadius = scene.params.param2;
	float limit   = 0.4;
	float fR2 = fixedRadius * fixedRadius;
	float mR2 = minRadius * minRadius;
	float DEfactor = scale;
	trap = 1e6;
	iter_count = scene.iterations;
	for (int i = 0; i < scene.iterations; i++) {
		if (z.x >  limit) z.x =  2.0 * limit - z.x;
		else if (z.x < -limit) z.x = -2.0 * limit - z.x;
		
		if (z.y >  limit) z.y =  2.0 * limit - z.y;
		else if (z.y < -limit) z.y = -2.0 * limit - z.y;
		
		if (z.z >  limit) z.z =  2.0 * limit - z.z;
		else if (z.z < -limit) z.z = -2.0 * limit - z.z;
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
