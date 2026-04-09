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

vec3 get_trap_color_hsv(float x) {
	vec3 orbit_color = hsv2rgb(vec3(sin(x * params.param2) * 2.0 - 1.0, 1.0, 1.0));
	return mix(material.color_a.rgb, orbit_color, params.param3);
}

float get_trap_distance(vec3 p) {
	return abs(length(p) - 1.0); // spehrical trap of r=1
}