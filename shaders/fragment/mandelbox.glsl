#[compute]
#version 460

#define CUSTOM_SDF_PROVIDED

#include "res://shaders/includes/shared_data.gdshaderinc"
#include "res://shaders/includes/screen/screen.gdshaderinc"
#include "res://shaders/includes/camera/camera.gdshaderinc"
#include "res://shaders/includes/screen/screen_uv.gdshaderinc"
#include "res://shaders/includes/sdfs/sdf_mandelbox.gdshaderinc"
#include "res://shaders/includes/rayMarcher/ray_marcher.gdshaderinc"
#include "res://shaders/includes/color/color.gdshaderinc"
#include "res://shaders/includes/main/main.gdshaderinc"
