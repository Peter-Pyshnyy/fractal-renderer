vec3 get_trap_color(float x) {
	float i = smoothstep(0.0, 1.0, x);
	return mix(material.color_a.rgb, material.color_b.rgb, i);
}

float get_trap_distance(vec3 p) {
	return abs(length(p) - 1.0); // spehrical trap of r=1
}