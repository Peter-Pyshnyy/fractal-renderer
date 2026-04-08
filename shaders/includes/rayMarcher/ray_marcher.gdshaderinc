vec3 getRayDirection(vec2 resolution, vec2 uv) {
	float aspectRatio = resolution.x / resolution.y;
	vec2 screenCoords = uv*2.0 - 1.0; // Convert to range [-1, 1]
	screenCoords.x *= aspectRatio; // Adjust for aspect ratio
	screenCoords *= cam.fovScale; // Apply FOV scaling

	return normalize(screenCoords.x * cam.right.xyz + screenCoords.y * cam.up.xyz + cam.forward.xyz);
}


vec3 raymarch(vec3 rayDir) {
    float t     = 0.0;
    float t_max = MAX_DIST;
    float steps = 0.0;

    // Angular size of one pixel at unit distance.
    // When the unbounding sphere subtends less than this angle, we're sub-pixel.
    float pixelRadius = cam.fovScale / cam.resolution.y;

    // §3.2: track the candidate with the smallest screen-space error seen so far,
    // rather than blindly using the last evaluated point.
    float candidate_t     = t;
    float candidate_error = 1e9;

    for (int i = 0; i < MAX_STEPS; i++) {
        steps += 1.0;

        vec3  pos    = cam.position.xyz + rayDir * t;
        float march_trap = 1e6;
        float radius = sdf(pos, march_trap);

        // Angular size of the unbounding sphere at this distance (§3.2).
        // This is the screen-space error: how large the "miss" looks on screen.
        float error = radius / max(t, 1e-4);

        // Keep whichever point has the tightest screen-space fit so far.
        if (error < candidate_error) {
            candidate_t     = t;
            candidate_error = error;
        }

        // Hit: unbounding sphere is smaller than one pixel → sub-pixel accuracy.
        if (error < pixelRadius) break;

        // Miss: ray left the scene.
        if (t > t_max) break;

        t += radius;
    }

    // Only shade if we actually reached sub-pixel accuracy.
    if (candidate_error > pixelRadius || candidate_t > t_max)
        return vec3(0.0);

     // Evaluate orbit trap once at the selected hit candidate to keep color stable
    // while zooming (instead of inheriting a trap value from intermediate march samples).
    float hit_trap = 1e6;
    vec3 hit_pos = cam.position.xyz + rayDir * candidate_t;
    sdf(hit_pos, hit_trap);
	
	//return vec3(exp(-hit_trap * 50.0)); 
	hit_trap = log(hit_trap + 1.0);
    float trap_normalized = exp(-hit_trap * 15.0);
    return get_trap_color(trap_normalized);
}