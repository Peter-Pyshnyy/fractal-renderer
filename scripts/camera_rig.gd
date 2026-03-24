extends Node3D

enum CameraMode { FPS, ORBIT }
@export var current_mode: CameraMode = CameraMode.ORBIT

@export var mouse_sensitivity: float = 0.003
@export var move_speed: float = 3.0
@export var orbit_radius: float = 2.5

@export var zoom_speed: float = 0.1
@export var min_orbit_radius: float = 1.2 # Щоб не залетіти прямо в центр при зумі
@export var max_orbit_radius: float = 50.0

@onready var camera: Camera3D = $VirtualCamera


var yaw: float = 0.0
var pitch: float = 0.0

func _ready() -> void:
	# Курсор від початку вільний для взаємодії з UI
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event: InputEvent) -> void:
	# Перемикання режимів
	if event.is_action_pressed("switch_camera"):
		if current_mode == CameraMode.ORBIT:
			# Перехід: Orbit -> FPS
			current_mode = CameraMode.FPS
			
			# 1. Запам'ятовуємо реальну позицію камери у світі
			var saved_global_pos = camera.global_position
			
			# 2. Переміщуємо наш центр керування (Rig) у цю точку
			global_position = saved_global_pos
			
			# 3. Скидаємо локальний зсув дочірньої камери, щоб уникнути стрибка
			camera.position = Vector3.ZERO
			
		else:
			# Перехід: FPS -> Orbit
			current_mode = CameraMode.ORBIT
			camera.fov = 75.0
			# Повертаємо центр обертання в нуль (центр фрактала)
			position = Vector3.ZERO

	# Тимчасове захоплення миші для "нескінченного" обертання без вмикання в краї екрана
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and current_mode == CameraMode.FPS:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if event.is_pressed() else Input.MOUSE_MODE_VISIBLE)
			
		elif event.button_index == MOUSE_BUTTON_LEFT and current_mode == CameraMode.ORBIT:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if event.is_pressed() else Input.MOUSE_MODE_VISIBLE)
		
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if current_mode == CameraMode.ORBIT:
				# Наближаємо фізично
				orbit_radius = clamp(orbit_radius - zoom_speed, min_orbit_radius, max_orbit_radius)
			elif current_mode == CameraMode.FPS:
				# Звужуємо кут огляду (оптичний зум)
				camera.fov = clamp(camera.fov - 1.0, 10.0, 120.0)
				
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if current_mode == CameraMode.ORBIT:
				# Віддаляємо фізично
				orbit_radius = clamp(orbit_radius + zoom_speed, min_orbit_radius, max_orbit_radius)
			elif current_mode == CameraMode.FPS:
				# Розширюємо кут огляду
				camera.fov = clamp(camera.fov + 1.0, 10.0, 120.0)

	# Обертання камери
	if event is InputEventMouseMotion:
		var is_fps_rotating = current_mode == CameraMode.FPS and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		var is_orbit_rotating = current_mode == CameraMode.ORBIT and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		
		if is_fps_rotating or is_orbit_rotating:
			yaw -= event.relative.x * mouse_sensitivity
			pitch -= event.relative.y * mouse_sensitivity
			pitch = clamp(pitch, -PI/2.1, PI/2.1) # Обмежуємо погляд вгору/вниз
			
			rotation = Vector3(pitch, yaw, 0)

func _process(delta: float) -> void:
	if current_mode == CameraMode.FPS:
		# Рух (WASD) відбувається ТІЛЬКИ коли затиснута права кнопка миші
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
			var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			
			var vertical = 0.0
			if Input.is_action_pressed("move_up"): vertical += 1.0
			if Input.is_action_pressed("move_down"): vertical -= 1.0
			
			position += (direction + Vector3(0, vertical, 0)) * move_speed * delta
			
		# У режимі FPS камера завжди плавно повертається в центр Rig-а
		camera.position = camera.position.lerp(Vector3.ZERO, delta * 10.0)
		
	elif current_mode == CameraMode.ORBIT:
		# У режимі Orbit камеру плавно відсуваємо назад на радіус орбіти
		camera.position = camera.position.lerp(Vector3(0, 0, orbit_radius), delta * 10.0)
