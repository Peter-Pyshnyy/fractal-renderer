shader_type canvas_item;
render_mode unshaded; // to check what does

#define CUSTOM_SDF_PROVIDED
#include "res://shaders/includes/color/blinn_phong.gdshaderinc"
#include "res://shaders/includes/sdfs/sdf_mandelbulb.gdshaderinc"
//#include "res://shaders/includes/rayMarcher/ray_marcher_ER.gdshaderinc"
#include "res://shaders/includes/rayMarcher/ray_marcher.gdshaderinc"

void fragment() {
	vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
    vec3 rayDir = getRayDirection(resolution, UV);
    //vec3 raymarchColor = raymarchER(rayDir, resolution.x);
    vec3 raymarchColor = raymarch(rayDir);
    COLOR = vec4(raymarchColor, 1.0);
}