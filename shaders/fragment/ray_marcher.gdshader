// basic ray marcher, implemented as in https://cgmathprog.home.blog/2019/09/02/raymarching-from-scratch
shader_type canvas_item;

uniform float fov = 45.0; // the vectical field of view (FOV) in degrees
uniform vec3 cameraPos = vec3(0.0, 0.0, 5.0); // position of the camera in world coordinates
uniform vec3 lookAt = vec3(0.0, 0.0, -1.0); // where are we looking at
uniform vec3 up = vec3(0.0, 1.0, 0.0); // what we consider
uniform int MAX_STEPS = 250; // march at most 250 times
uniform float MAX_DIST = 20; // don't continue if depth if larger than 20
uniform float MIN_HIT_DIST = 0.0001; // hit depth threshold

uniform float globalAmbient = 0.1; // how strong is the ambient lightning
uniform float globalDiffuse = 1.0; // how strong is the diffuse lightning
uniform float globalSpecular = 1.0; // how strong is the specular lightning
uniform float globalSpecularExponent = 64.0; // how focused is the shiny spot
uniform vec3 lightPos = vec3(-2.0, 5.0, 3.0); // position of the light source
uniform vec3 lightColor = vec3(0.9, 0.9, 0.68); // color of the light source
uniform vec3 ambientColor = vec3(1.0, 1.0, 1.0); // ambient color

//---------------------------
uniform float power = 8.0; // The "Power" of the Mandelbulb (8 is standard)
uniform int iterations = 10; // Complexity of the fractal
//---------------------------

const float DERIVATIVE_STEP = 0.0001;

float sdSphere( vec3 p, vec3 c, float r ) {
    return length(c - p) - r;
}
 
//float sdf(vec3 pos) {
    //return sdSphere(pos, vec3(0), 1);
//}

float sdf(vec3 pos) {
    vec3 z = pos;
    float dr = 1.0;
    float r = 0.0;
    
    for (int i = 0; i < iterations; i++) {
        r = length(z);
        if (r > 2.0) break; // Escape radius
        
        // Convert to polar coordinates
        float theta = acos(z.z / r);
        float phi = atan(z.y, z.x);
        
        // Scale the derivative for distance estimation
        dr = pow(r, power - 1.0) * power * dr + 1.0;
        
        // Scale and rotate the point
        float zr = pow(r, power);
        theta = theta * power;
        phi = phi * power;
        
        // Convert back to cartesian coordinates
        z = zr * vec3(sin(theta) * cos(phi), sin(phi) * sin(theta), cos(theta));
        z += pos;
    }
    return 0.5 * log(r) * r / dr;
}

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

vec3 blinnPhong(vec3 position, // hit point
                vec3 lightPosition, // position of the light source
                vec3 ambientCol, // ambient color
                vec3 lightCol, // light source color
                float ambientCoeff, // scale ambient contribution
                float diffuseCoeff, // scale diffuse contribution
                float specularCoeff, // scale specular contribution
                float specularExponent // how focused should the shiny spot be
)
{
    vec3 normal = estimateNormal(position);
    vec3 toEye = normalize(cameraPos - position);
    vec3 toLight = normalize(lightPosition - position);
    vec3 reflection = reflect(-toLight, normal);
     
    vec3 ambientFactor = ambientCol * ambientCoeff;
    vec3 diffuseFactor = diffuseCoeff * lightCol * max(0.0, dot(normal, toLight));
    vec3 specularFactor = lightCol * pow(max(0.0, dot(toEye, reflection)), specularExponent)
                     * specularCoeff;
     
    return ambientFactor + diffuseFactor + specularFactor;
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
    		return hitColor * (it / float(MAX_STEPS));
			//return blinnPhong(pos, lightPos, ambientColor, lightColor, globalAmbient, globalDiffuse, globalSpecular, globalSpecularExponent);
        }
		it += 1.0;
        depth += dist;
    }
    return missColor;
}

void fragment() {
	vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
     
    vec3 rayDir = getRayDirection(resolution, UV);
    vec3 raymarchColor = raymarch(rayDir);
    COLOR = vec4(raymarchColor, 1.0);
}
