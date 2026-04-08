vec3 get_trap_color(float x) {
	return vec3(x);
}

float get_trap_distance(vec3 p) {
	return abs(length(p) - 1.0); // spehrical trap of r=1
}