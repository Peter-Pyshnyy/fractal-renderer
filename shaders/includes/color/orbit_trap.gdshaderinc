vec3 hsv2rgb(vec3 c) {
    vec3 rgb = clamp(abs(mod(c.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
    rgb = rgb * rgb * (3.0 - 2.0 * rgb);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

vec3 get_trap_color_mix(float x) {
    float i = smoothstep(0.0, 1.0, x);
    return mix(scene.material.color_a.rgb, scene.material.color_b.rgb, i);
}

vec3 get_trap_color_sinmask(float x) {
    float v = clamp(pow(sin(x + scene.sinmask_offset + scene.sinmask_phase) * scene.sinmask_amp, 2.0), 0.0, 1.0);
    vec3 sinmask_color = hsv2rgb(vec3(v, v, v));
    return mix(scene.material.color_a.rgb, sinmask_color, scene.sinmask_blend);
}

vec3 get_trap_color_hsv(float x) {
    float hue = fract(x * scene.hsv_cycles + scene.hsv_hue_offset);
    vec3 orbit_color = hsv2rgb(vec3(hue, 1.0, 1.0));
    return mix(scene.material.color_a.rgb, orbit_color, scene.hsv_blend);
}

vec3 get_trap_color_viridis(float x) {
    return clamp(vec3(0.2803 + 1.3217 * x - 1.16 * x * x, -0.001 + 1.27 * x - 0.37 * x * x, 0.334 + 1.44 * x - 1.37 * x * x), 0.0, 1.0);
}

vec3 get_trap_color_heat(float x) {
    return clamp(vec3(1.5 * x, 1.7 * x * x, x * x * x), 0.0, 1.0);
}

vec3 get_palette_color(float t) {
    if (scene.palette_type == 0) return get_trap_color_mix(t);
    if (scene.palette_type == 1) return get_trap_color_sinmask(t);
    if (scene.palette_type == 2) return get_trap_color_hsv(t);
    if (scene.palette_type == 3) return get_trap_color_viridis(t);
    return get_trap_color_heat(t);
}

float get_normalized_trap(float d) {
    float safe_d = min(d, 100000.0);
    return 1.0 / (1.0 + exp(scene.trap_norm_a * (scene.trap_norm_b - safe_d)));
}

float length_Lp(vec3 p, float power) {
    vec3 ap = pow(abs(p), vec3(power));
    return pow(ap.x + ap.y + ap.z, 1.0 / power);
}

float length_Lp2(vec2 p, float power) {
    vec2 ap = pow(abs(p), vec2(power));
    return pow(ap.x + ap.y, 1.0 / power);
}

float get_trap_distance(vec3 p) {
    vec3 tp = scene.trap_pos_size.xyz;
    float ts = scene.trap_pos_size.w;
    float lp = scene.trap_lp_power;
    vec3 q = p - tp;
    if (scene.trap_shape == 0) return abs(length_Lp(q, lp) - ts);
    if (scene.trap_shape == 1) return abs(q.y - ts);
    if (scene.trap_shape == 2) return length_Lp(max(abs(q) - vec3(ts), vec3(0.0)), lp);
    if (scene.trap_shape == 3) return min(min(length_Lp2(q.yz, lp), length_Lp2(q.xz, lp)), length_Lp2(q.xy, lp));
    return abs(length_Lp2(q.xz, lp) - ts);
}
