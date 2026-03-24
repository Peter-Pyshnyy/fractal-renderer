extends Node

@export var color_rect: ColorRect
@export var virtual_camera: Camera3D

var fractal_material: ShaderMaterial

func _ready() -> void:
	if color_rect:
		fractal_material = color_rect.material as ShaderMaterial
		
	if not fractal_material:
		push_error("У ColorRect немає ShaderMaterial!")

func _process(_delta: float) -> void:
	if not fractal_material or not virtual_camera:
		return
		
	var cam_pos = virtual_camera.global_position
	var cam_forward = -virtual_camera.global_transform.basis.z
	var cam_up = virtual_camera.global_transform.basis.y
	
	fractal_material.set_shader_parameter("cameraPos", cam_pos)
	fractal_material.set_shader_parameter("lookAt", cam_forward) 
	fractal_material.set_shader_parameter("up", cam_up)
	fractal_material.set_shader_parameter("fov", virtual_camera.fov)
