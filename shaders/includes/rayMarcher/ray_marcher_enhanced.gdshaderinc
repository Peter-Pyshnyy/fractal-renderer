//vec3 getRayDirection(vec2 resolution, vec2 uv) {
	//float aspectRatio = resolution.x / resolution.y;
	//vec2 screenCoords = uv*2.0 - 1.0; // Convert to range [-1, 1]
	//screenCoords.x *= aspectRatio; // Adjust for aspect ratio
	//screenCoords *= cam.fovScale; // Apply FOV scaling
//
	//return normalize(screenCoords.x * cam.right.xyz + screenCoords.y * cam.up.xyz + cam.forward.xyz);
//}

vec3 raymarch_enhanced(vec3 rayDir) {
	float t = 0.0;
    float t_max = 10.0; 
    float steps = 0.0;
	//float safeDist = length(cam.position.xyz) - 1.35;
	//if (safeDist > 0.1) {
    //t = safeDist;
	//}
    
    float omega = 1.2; 
    float previousRadius = 0.0;
    float stepLength = 0.0;
    
    float candidate_t = t;
    float candidate_error = 999999.0;
    
    // Use a realistic pixel threshold for screen-space error, not absolute epsilon
    float pixelThreshold = 0.001; 
	float pixelRadius = cam.fovScale / cam.resolution.y;
	
    for (int i = 0; i < MAX_STEPS; i++) {
        steps += 1.0;
        vec3 pos = cam.position.xyz + rayDir * t;
        float signedRadius = sdf(pos) * 0.5;
        float radius = abs(signedRadius);
        
        bool sorFail = omega > 1.0 && (radius + previousRadius) < stepLength;
        
        if (sorFail) {
            // Un-relax the step to calculate the correct fallback
            stepLength = (stepLength / omega) - stepLength;
            omega = 1.0;
        } else {
            stepLength = signedRadius * omega;
        }
        previousRadius = radius;
        
        //float error = radius / max(t * 0.2, pixelRadius);
		
		// much preciser close-up, but more noise
        float error = radius / max(t * 0.15, pixelRadius * 0.25);
        
        if (!sorFail && error < candidate_error) {
            candidate_t = t;
            candidate_error = error;
        }
        
        // Terminate using the screen-space pixel threshold
        if (!sorFail && error < pixelThreshold || t > t_max) {
            break;
        }
        
        t += stepLength;
    }
    
    t = candidate_t;
    
    // Check if the candidate actually struck the geometry
    bool isHit = (candidate_error <= pixelThreshold);
    
    if (t < t_max && isHit) {
        for (int j = 0; j < 3; j++) {
            vec3 p = cam.position.xyz + rayDir * t;
            t += sdf(p) - (EPSILON * t); 
        }
    }

    float s0 = 1.0 - steps / float(MAX_STEPS);
    float s1 = sin(steps * 0.01);
    s1 = 1.0 - (0.5 + 0.5 * s1);
    float shade = mix(s0, s1, 0.5);

    // Fade to black if the ray completely bypassed geometry
    if (t >= t_max || !isHit) {
        shade = 0.0;
    }

    return vec3(shade);
}