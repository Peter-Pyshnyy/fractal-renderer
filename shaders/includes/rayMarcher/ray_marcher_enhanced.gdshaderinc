vec3 getRayDirection(vec2 resolution, vec2 uv) {
	float aspectRatio = resolution.x / resolution.y;
	vec2 screenCoords = uv*2.0 - 1.0; // Convert to range [-1, 1]
	screenCoords.x *= aspectRatio; // Adjust for aspect ratio
	screenCoords *= cam.fovScale; // Apply FOV scaling

	return normalize(screenCoords.x * cam.right.xyz + screenCoords.y * cam.up.xyz + cam.forward.xyz);
}

vec3 raymarch_enhanced(vec3 rayDir) {
    float t     = 0.0;      // t_min
    float t_max = MAX_DIST;
    float steps = 0.0;

    // ── paper §3.1 ──────────────────────────────────────────────────────────
    float omega           = 1.2;
    float previousRadius  = 0.0;
    float stepLength      = 0.0;
    float candidate_t     = t;
    float candidate_error = 1e9; // INFINITY

    // Angular size of one pixel at unit distance (used as the screen-space
    // error threshold throughout — §3.2 and Listing 2)
    float pixelRadius = cam.fovScale / cam.resolution.y;

    // Detect whether the ray origin is already inside a surface so that
    // signed steps point in the right direction (§3, functionSign)
    float functionSign = sdf(cam.position.xyz) < 0.0 ? -1.0 : 1.0;

    for (int i = 0; i < MAX_STEPS; i++) {
        steps += 1.0;

        vec3  pos          = cam.position.xyz + rayDir * t;
        float signedRadius = functionSign * sdf(pos); // NO * 0.5
        float radius       = abs(signedRadius);

        // ── SOR failure test (§3.1) ──────────────────────────────────────────
        // If the two consecutive unbounding spheres no longer overlap,
        // over-relaxation may have skipped past a surface.
        bool sorFail = (omega > 1.0) && ((radius + previousRadius) < stepLength);

        if (sorFail) {
            // Back up to p_fallback = p_i + d * stepLength * (1 − ω)
            // Listing 2: stepLength -= omega * stepLength
            stepLength -= omega * stepLength;   // = stepLength * (1 − ω)  [negative]
            omega = 1.0;                        // revert to classical sphere tracing
        } else {
            stepLength = signedRadius * omega;
        }

        previousRadius = radius;

        // ── Screen-space error metric (§3.2, Listing 2) ─────────────────────
        // radius / t is the angular size of the unbounding sphere at distance t.
        float error = radius / max(t, 1e-4); // guard against t == 0 at first step

        if (!sorFail && error < candidate_error) {
            candidate_t     = t;
            candidate_error = error;
        }

        // Terminate when sub-pixel accuracy is achieved, or ray exits the scene.
        if ((!sorFail && error < pixelRadius) || t > t_max)
            break;

        t += stepLength;
    }

    // ── Miss condition (§3.2, Listing 2 exit check) ─────────────────────────
    // A hit is only valid when the best candidate reached sub-pixel accuracy.
    if (candidate_error > pixelRadius || candidate_t > t_max) {
        return vec3(0.0);
    }

    t = candidate_t;

    // ── Discontinuity reduction — fixed-point iteration (§3.4, Equation 3) ──
    // p_{i+1} = p_i + d * ( f(p_i) − err(‖p_i − o‖) )
    // err(dist) = pixelRadius * dist  (screen-space metric, Hart & DeFanti §3.4)
	
    //for (int j = 0; j < 3; j++) {
        //vec3 p = cam.position.xyz + rayDir * t;
        //t += functionSign * sdf(p) - pixelRadius * t;
    //}

    // ── Visualise iteration cost (unchanged from original) ──────────────────
    float s0    = 1.0 - steps / float(MAX_STEPS);
    float s1    = 1.0 - (0.5 + 0.5 * sin(steps * 0.01));
    float shade = mix(s0, s1, 0.5);
    return vec3(shade);
}