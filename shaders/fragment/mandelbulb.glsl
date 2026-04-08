#[compute]
#version 450
layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;


layout(set = 0, binding = 0) uniform writeonly image2D output_image;

#include "res://shaders/includes/shared_data.gdshaderinc"
#include "res://shaders/includes/color/orbit_trap.gdshaderinc"
#include "res://shaders/includes/sdfs/sdf_mandelbulb.gdshaderinc"
#include "res://shaders/includes/rayMarcher/ray_marcher.gdshaderinc" 
//#include "res://shaders/includes/rayMarcher/ray_marcher_enhanced.gdshaderinc"
//#include "res://shaders/includes/rayMarcher/ray_marcher_AR.gdshaderinc" 
  
void main() {
    ivec2 base_coord = ivec2(gl_GlobalInvocationID.xy) * resolution_scale;
    ivec2 image_size = imageSize(output_image);

    if (base_coord.x >= image_size.x || base_coord.y >= image_size.y) return;

    vec2 offset = vec2(float(resolution_scale) * 0.5);
    vec2 uv = (vec2(base_coord) + offset) / vec2(image_size);
    uv.y = 1.0 - uv.y;
    
    vec3 rayDir = getRayDirection(cam.resolution, uv);
    vec3 color = raymarch(rayDir);
     
    for (int y = 0; y < resolution_scale; y++) {
        for (int x = 0; x < resolution_scale; x++) {
            ivec2 write_coord = base_coord + ivec2(x, y);
            if (write_coord.x < image_size.x && write_coord.y < image_size.y) {
                imageStore(output_image, write_coord, vec4(color, 1.0));
            }
        } 
    } 
}  