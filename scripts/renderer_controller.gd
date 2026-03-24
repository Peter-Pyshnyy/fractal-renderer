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
	
	#TODO: pass on change only, as a callback
	fractal_material.set_shader_parameter("cameraPos", cam_pos)
	fractal_material.set_shader_parameter("forward", cam_forward.normalized()) 
	fractal_material.set_shader_parameter("up", cam_up.normalized())
	fractal_material.set_shader_parameter("right", cam_forward.cross(cam_up).normalized())
	fractal_material.set_shader_parameter("fov", virtual_camera.fov)
	fractal_material.set_shader_parameter("fovScale", tan(deg_to_rad(virtual_camera.fov) * 0.5))
