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
    return vec3(pow(sin(x + scene.sinmask_phase) * scene.sinmask_amp, 2.0))
           * scene.material.color_a.rgb;
}

vec3 get_trap_color_hsv(float x) {
    float hue = fract(x * scene.hsv_cycles + scene.hsv_hue_offset);
    vec3 orbit_color = hsv2rgb(vec3(hue, 1.0, 1.0));
    return mix(scene.material.color_a.rgb, orbit_color, scene.hsv_blend);
}

vec3 get_palette_color(float t) {
    if (scene.palette_type == 0) return get_trap_color_mix(t);
    if (scene.palette_type == 1) return get_trap_color_sinmask(t);
    return get_trap_color_hsv(t);
}

float get_normalized_trap(float d) {
    return d / (d + scene.trap_norm_k);
}

float length_Lp(vec3 p, float power) {
    vec3 ap = pow(abs(p), vec3(power));
    return pow(ap.x + ap.y + ap.z, 1.0 / power);
}

float get_trap_distance(vec3 p) {
    vec3  tp = scene.trap_pos_size.xyz;
    float ts = scene.trap_pos_size.w;
    if (scene.trap_shape == 0)
        return abs(length_Lp(p - tp, 1.0) - ts);
    if (scene.trap_shape == 1)
        return abs(length(p - tp) - ts);
    if (scene.trap_shape == 2)
        return length(p - tp);
    return length(vec2(p.x - tp.x, p.z - tp.z));
}
