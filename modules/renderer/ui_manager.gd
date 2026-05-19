extends Control

# Посилання на ваші UI елементи
@onready var fractal_dropdown: OptionButton = $MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_Fractal_Content/FractalDropdown
@onready var iterations_slider: HSlider = $MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_Fractal_Content/IterationsSlider
@onready var iterations_lbl: Label = $MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_Fractal_Content/IterationsLbl

# Посилання на ваш контролер рендеру (задайте правильний шлях)
@export var renderer: Node 

func _ready() -> void:
	_setup_ui_elements()

func _setup_ui_elements() -> void:
	# 1. Налаштування Dropdown (Вибір фракталу)
	fractal_dropdown.add_item("Mandelbulb") # ID 0
	fractal_dropdown.add_item("Sierpinski Koleidoscope")  # ID 1
	fractal_dropdown.item_selected.connect(_on_fractal_selected)
	
	# 2. Налаштування Слайдера Ітерацій
	iterations_slider.min_value = 1
	iterations_slider.max_value = 100
	iterations_slider.value = Global.g_fractal.iterations
	iterations_lbl.text = "Iterations: " + str(iterations_slider.value)
	iterations_slider.value_changed.connect(_on_iterations_changed)
	
	# 3. Налаштування Галочки PBR
	#pbr_toggle.button_pressed = true # За замовчуванням увімкнено
	#pbr_toggle.toggled.connect(_on_pbr_toggled)

# --- Функції обробки сигналів ---

func _on_fractal_selected(index: int) -> void:
	# Передаємо ID фракталу в рендерер
	renderer.current_pipeline = renderer.pipelines[index]
	Global.g_fractal = Global.g_data_arr[index]
	renderer._mark_motion() 

func _on_iterations_changed(value: float) -> void:
	iterations_lbl.text = "Iterations: " + str(int(value))
	Global.g_fractal.iterations = int(value)
	renderer._mark_motion()

#func _on_pbr_toggled(button_pressed: bool) -> void:
	#renderer.use_pbr = button_pressed
	#renderer._mark_motion()
