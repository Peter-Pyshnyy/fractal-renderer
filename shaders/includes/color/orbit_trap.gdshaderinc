vec3 hsv2rgb(vec3 c) {
    vec3 rgb = clamp( abs(mod(c.x*6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0,
                      0.0,
                      1.0 );
    rgb = rgb * rgb * (3.0 - 2.0 * rgb); // optional smoothing
    return c.z * mix(vec3(1.0), rgb, c.y);
}

vec3 get_trap_color_mix(float x) {
	float i = smoothstep(0.0, 1.0, x);
	return mix(material.color_a.rgb, material.color_b.rgb, i);
}

vec3 get_trap_color_sinmask(float x) {
	return vec3(pow(sin(x + 0.15) * 3.5 ,2.0)) * vec3(1.0, 0.2, 0.0);
}

vec3 get_trap_color_hsv(float x) {
	vec3 orbit_color = hsv2rgb(
		// exp(sin(x + a) ..., b) -> a sets the size of the "rapture", b fills the positive space with set hue
		vec3(pow(sin(x + 8.15) * 2.0 - 1.0, -3.6),
		 1.0,
		 1.0));
	//vec3 orbit_color = hsv2rgb(vec3(x, 1.0, 1.0));
	return mix(material.color_a.rgb, orbit_color, 0.5);
	//return mix(material.color_a.rgb, orbit_color, 0.5);
}

float get_normalized_trap(float d) {
	float k = 0.22;
	float res = d / (d + k);
	//return pow(res, 2.718281828459045); // x^e
	return 1.0 - exp(6.0 * res);
}

float get_trap_distance(vec3 p) {
	return abs(length(p) - 1.0); // spehrical trap of r=1
}