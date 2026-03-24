// basic ray marcher, implemented as in https://cgmathprog.home.blog/2019/09/02/raymarching-from-scratch
uniform float fov = 45.0; // the vectical field of view (FOV) in degrees
uniform vec3 cameraPos = vec3(0.0, 0.0, 5.0); // position of the camera in world coordinates
uniform vec3 lookAt = vec3(0.0, 0.0, -1.0); // where are we looking at
uniform vec3 up = vec3(0.0, 1.0, 0.0); // what we consider
uniform int MAX_STEPS = 250; // march at most 250 times
uniform float MAX_DIST = 20; // don't continue if depth if larger than 20
uniform float MIN_HIT_DIST = 0.00001; // hit depth threshold

uniform vec3 lightPos = vec3(-2.0, 5.0, 3.0); // position of the light source
uniform vec3 lightColor = vec3(0.9, 0.9, 0.68); // color of the light source
uniform vec3 ambientColor = vec3(1.0, 1.0, 1.0); // ambient color

const float DERIVATIVE_STEP = 0.0001;

vec3 getRayDirection(vec2 resolution, vec2 uv) {
	float aspect = resolution.x / resolution.y;
    float fov2 = radians(fov) / 2.0;
	// convert coordinates from [0, 1] to [-1, 1]
    // and invert y axis to flow from bottom to top
    vec2 screenCoord = (uv - 0.5) * 2.0;
    screenCoord.x *= aspect;
    screenCoord.y = -screenCoord.y;

    // contibutions of the up and right vectors
    vec2 offsets = screenCoord * tan(fov2);
	// compute 3 orthogonal unit vectors
    vec3 rayLookAt = normalize(lookAt);
    vec3 rayRight = normalize(cross(rayLookAt, normalize(up)));
    vec3 rayUp = cross(rayRight, rayLookAt);
    vec3 rayDir = rayLookAt + rayRight * offsets.x + rayUp * offsets.y;

    return normalize(rayDir);
}

vec3 estimateNormal(vec3 p) {
    return normalize(vec3(
        sdf(vec3(p.x + DERIVATIVE_STEP, p.y, p.z)) - sdf(vec3(p.x - DERIVATIVE_STEP, p.y, p.z)),
        sdf(vec3(p.x, p.y + DERIVATIVE_STEP, p.z)) - sdf(vec3(p.x, p.y - DERIVATIVE_STEP, p.z)),
        sdf(vec3(p.x, p.y, p.z  + DERIVATIVE_STEP)) - sdf(vec3(p.x, p.y, p.z - DERIVATIVE_STEP))
    ));
}

vec3 raymarch(vec3 rayDir) {
    vec3 hitColor = vec3(1.0, 1.0, 1.0);
    vec3 missColor = vec3(0.0, 0.0, 0.0);
 	float it = 0.0;
    float depth = 0.0;
    for (int i=0; depth<MAX_DIST && i<MAX_STEPS; ++i)
    {
        vec3 pos = cameraPos + rayDir * depth;
        float dist = sdf(pos);
        if (dist < MIN_HIT_DIST) {
    		vec3 pos = cameraPos + rayDir * depth;

    		vec3 normal = estimateNormal(pos);
    		vec3 viewDir = normalize(cameraPos - pos);
    		vec3 lightDir = normalize(lightPos - pos);
    		return phong(normal, viewDir, lightDir);
		}
		it += 1.0;
        depth += dist;
    }
    return missColor;
}
