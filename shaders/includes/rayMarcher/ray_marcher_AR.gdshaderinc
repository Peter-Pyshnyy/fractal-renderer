const float BENCH_BETA            = 0.3;   // ARST relaxation 
const float BENCH_SURFACE_EPSILON = 0.00001;
const float BENCH_EPSILON_CLAMP   = 1e-7;  

vec3 getRayDirection(vec2 resolution, vec2 uv) {
    float aspect = resolution.x / resolution.y;
    vec2 screen = uv * 2.0 - 1.0;
    screen.x *= aspect;
    screen *= cam.fovScale;
    return normalize(
        cam.forward.xyz +
        cam.right.xyz * screen.x +
        cam.up.xyz * screen.y
    );
}

float bench_pixelRadius() {
	return cam.fovScale / cam.resolution.y;
}

float bench_lodThreshold(float t) {
	return max(t * bench_pixelRadius() * scene.lod_scalar, BENCH_EPSILON_CLAMP);
}

vec3 raymarch_ST(vec3 rayDir) {
	float t = 0.0;
	int i;
	for (i = 0; i < MAX_STEPS; i++) {
		float r = sdf(cam.position.xyz + rayDir * t);
		if (r < BENCH_SURFACE_EPSILON || t >= MAX_DIST) break;
		t += r;
	}
	return vec3(float(i) / float(MAX_STEPS));
}

vec3 raymarch_ST_LOD(vec3 rayDir) {
	float t = 0.0;
	int i;
	for (i = 0; i < MAX_STEPS; i++) {
		float r = sdf(cam.position.xyz + rayDir * t);
		if (r < bench_lodThreshold(t) || t >= MAX_DIST) break;
		t += r;
	}
	return vec3(float(i) / float(MAX_STEPS));
}

vec3 raymarch_ARST(vec3 rayDir) {
	float t = 0.0;
	float r = sdf(cam.position.xyz);
	float z = r;
	float m = -1.0;
	int i;
	for (i = 0; i < MAX_STEPS; i++) {
		if (r < BENCH_SURFACE_EPSILON || t >= MAX_DIST) break;
		float T = t + z;
		float R = sdf(cam.position.xyz + rayDir * T);
		if (z <= r + abs(R)) {
			float M = (R - r) / (T - t);
			m = (1.0 - BENCH_BETA) * m + BENCH_BETA * M;
			t = T;
			r = R;
		} else {
			m = -1.0;
		}
		z = 2.0 * r / (1.0 - m);
	}
	return vec3(float(i) / float(MAX_STEPS));
}

vec3 raymarch_ARST_LOD(vec3 rayDir) {
	float t = 0.0;
	float r = sdf(cam.position.xyz);
	float z = r;
	float m = -1.0;
	int i;
	for (i = 0; i < MAX_STEPS; i++) {
		if (r < bench_lodThreshold(t) || t >= MAX_DIST) break;
		float T = t + z;
		float R = sdf(cam.position.xyz + rayDir * T);
		if (z <= r + abs(R)) {
			float M = (R - r) / (T - t);
			m = (1.0 - BENCH_BETA) * m + BENCH_BETA * M;
			t = T;
			r = R;
		} else {
			m = -1.0;
		}
		z = 2.0 * r / (1.0 - m);
	}
	return vec3(float(i) / float(MAX_STEPS));
}

// raymarch_ST, raymarch_ST_LOD, raymarch_ARST, raymarch_ARST_LOD
vec3 raymarch_AR(vec3 rayDir) {
	return raymarch_ST(rayDir);
}
