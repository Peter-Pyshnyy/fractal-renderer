vec3 getRayDirection(vec2 resolution, vec2 uv) {
	float aspectRatio = resolution.x / resolution.y;
	vec2 screenCoords = uv*2.0 - 1.0; // Convert to range [-1, 1]
	screenCoords.x *= aspectRatio; // Adjust for aspect ratio
	screenCoords *= cam.fovScale; // Apply FOV scaling

	return normalize(screenCoords.x * cam.right.xyz + screenCoords.y * cam.up.xyz + cam.forward.xyz);
}


vec3 raymarch(vec3 rayDir) {
    float sdfScaler = 0.75;
    float t       = 0.0;
    float t_max   = MAX_DIST;

    // Angular size of one pixel at unit distance.
    float pixelRadius = cam.fovScale / cam.resolution.y;

    float candidate_t     = t;
    float candidate_error = 1e9;

    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 pos = cam.position.xyz + rayDir * t;

        // Fast SDF evaluation during the march (no trap calculation)
        // Scaled to match AR parameters
        float radius = sdf(pos) * (sdfScaler / float(resolution_scale));

        // Normalized LOD error metric matching AR
        float error = radius / max(t * pixelRadius * 0.75 * float(resolution_scale), 1e-7);

        // Keep whichever point has the tightest screen-space fit so far.
        if (error < candidate_error) {
            candidate_t     = t;
            candidate_error = error;
        }

        // Hit: error is less than 1.0 (sub-pixel threshold reached)
        // Miss: ray left the scene
        if (error < 1.0 || t + radius >= t_max) break;

        t += radius;
    }

    // Only shade if we actually reached sub-pixel accuracy and stayed within bounds.
    if (candidate_error >= 1.0 || candidate_t >= t_max) {
        return vec3(0.0);
    }

    // Evaluate orbit trap once at the selected hit candidate
    float hit_trap;
    vec3 hit_pos = cam.position.xyz + rayDir * candidate_t;
    sdf_with_trap(hit_pos, hit_trap);

    hit_trap = log(hit_trap + 1.0);
    float trap_normalized = exp(-hit_trap * 15.0);
    return get_trap_color(trap_normalized);
}