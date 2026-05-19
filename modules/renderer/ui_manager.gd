extends Control

@onready var fractal_dropdown: OptionButton = $MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_Fractal_Content/FractalDropdown
@onready var iterations_slider: HSlider = $MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_Fractal_Content/IterationsSlider
@onready var iterations_lbl: Label = $MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_Fractal_Content/IterationsLbl

@onready var param_rows: Array[VBoxContainer] = [
	$MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_Fractal_Content/FractalParamRow1,
	$MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_Fractal_Content/FractalParamRow2,
	$MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_Fractal_Content/FractalParamRow3,
]
@onready var param_labels: Array[Label] = [
	$MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_Fractal_Content/FractalParamRow1/FractalParamLbl,
	$MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_Fractal_Content/FractalParamRow2/FractalParamLbl,
	$MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_Fractal_Content/FractalParamRow3/FractalParamLbl,
]
@onready var param_sliders: Array[HSlider] = [
	$MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_Fractal_Content/FractalParamRow1/FractalParamSlider,
	$MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_Fractal_Content/FractalParamRow2/FractalParamSlider,
	$MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_Fractal_Content/FractalParamRow3/FractalParamSlider,
]

@onready var pbr_toggle: CheckBox = $MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_PBR_Content/PBRToggle
@onready var metallic_slider: HSlider = $MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_PBR_Content/MetallicSlider
@onready var metallic_lbl: Label = $MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_PBR_Content/MetallicLbl
@onready var roughness_slider: HSlider = $MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_PBR_Content/RoughnessSlider
@onready var roughness_lbl: Label = $MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_PBR_Content/RoughnessLbl
@onready var light_x_slider: HSlider = $MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_PBR_Content/LightXSlider
@onready var light_x_lbl: Label = $MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_PBR_Content/LightXLbl
@onready var light_y_slider: HSlider = $MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_PBR_Content/LightYSlider
@onready var light_y_lbl: Label = $MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_PBR_Content/LightYLbl
@onready var light_z_slider: HSlider = $MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_PBR_Content/LightZSlider
@onready var light_z_lbl: Label = $MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_PBR_Content/LightZLbl

@onready var mas_toggle: CheckBox = $MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_MAS_Content/MASToggle
@onready var mas_scale_slider: HSlider = $MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_MAS_Content/MASScaleSlider
@onready var mas_scale_lbl: Label = $MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_MAS_Content/MASScaleLbl

@onready var sensitivity_slider: HSlider = $MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_Camera_Content/SensitivitySlider
@onready var sensitivity_lbl: Label = $MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_Camera_Content/SensitivityLbl
@onready var smooth_orbit_toggle: CheckBox = $MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_Camera_Content/SmoothOrbitToggle
@onready var camera_mode_dropdown: OptionButton = $MainSplit/Sidebar/MarginContainer/VBoxContainer/ScrollContainer/AccordionMenu/Section_Camera_Content/CameraModeDropdown

@export var renderer: Node

func _ready() -> void:
	_setup_ui_elements()
	_sync_ui()

func _setup_ui_elements() -> void:
	fractal_dropdown.add_item("Mandelbulb")
	fractal_dropdown.add_item("Sierpinski Koleidoscope")
	fractal_dropdown.item_selected.connect(_on_fractal_selected)

	iterations_slider.min_value = 1
	iterations_slider.max_value = 100
	iterations_slider.step = 1
	iterations_slider.value_changed.connect(_on_iterations_changed)

	for i in param_sliders.size():
		param_sliders[i].value_changed.connect(_on_fractal_param_changed.bind(i))

	pbr_toggle.toggled.connect(_on_pbr_toggled)
	_setup_slider(metallic_slider, 0.0, 1.0, 0.01, _on_metallic_changed)
	_setup_slider(roughness_slider, 0.0, 1.0, 0.01, _on_roughness_changed)
	_setup_slider(light_x_slider, -5.0, 5.0, 0.01, _on_light_x_changed)
	_setup_slider(light_y_slider, -5.0, 5.0, 0.01, _on_light_y_changed)
	_setup_slider(light_z_slider, -5.0, 5.0, 0.01, _on_light_z_changed)

	mas_toggle.toggled.connect(_on_mas_toggled)
	_setup_slider(mas_scale_slider, 1.0, 8.0, 1.0, _on_mas_scale_changed)

	_setup_slider(sensitivity_slider, 0.001, 0.1, 0.001, _on_sensitivity_changed)
	smooth_orbit_toggle.toggled.connect(_on_smooth_orbit_toggled)
	camera_mode_dropdown.add_item("FPS")
	camera_mode_dropdown.add_item("Orbit")
	camera_mode_dropdown.item_selected.connect(_on_camera_mode_selected)

func _setup_slider(slider: HSlider, min_v: float, max_v: float, step_v: float, callback: Callable) -> void:
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step_v
	slider.value_changed.connect(callback)

func _on_fractal_selected(index: int) -> void:
	renderer.current_pipeline = renderer.pipelines[index]
	Global.g_fractal = Global.g_data_arr[index]
	renderer._mark_motion()
	_sync_ui()

func _on_iterations_changed(value: float) -> void:
	iterations_lbl.text = "Iterations: %d" % int(value)
	Global.g_fractal.iterations = int(value)
	renderer._mark_motion()

func _on_fractal_param_changed(value: float, index: int) -> void:
	var defs = Global.g_fractal.get_param_definitions()
	if index >= defs.size():
		return
	var param_name = defs[index].get("name", "Param")
	param_labels[index].text = "%s: %.2f" % [param_name, value]
	Global.g_fractal.set_param_value(index, value)
	renderer._mark_motion()

func _on_pbr_toggled(pressed: bool) -> void:
	renderer.use_pbr = pressed
	renderer._mark_motion()

func _on_metallic_changed(value: float) -> void:
	metallic_lbl.text = "Metallic: %.2f" % value
	renderer.u_metallic = value
	renderer._mark_motion()

func _on_roughness_changed(value: float) -> void:
	roughness_lbl.text = "Roughness: %.2f" % value
	renderer.u_roughness = value
	renderer._mark_motion()

func _on_light_x_changed(value: float) -> void:
	light_x_lbl.text = "Light X: %.2f" % value
	renderer.u_lightDir.x = value
	renderer._mark_motion()

func _on_light_y_changed(value: float) -> void:
	light_y_lbl.text = "Light Y: %.2f" % value
	renderer.u_lightDir.y = value
	renderer._mark_motion()

func _on_light_z_changed(value: float) -> void:
	light_z_lbl.text = "Light Z: %.2f" % value
	renderer.u_lightDir.z = value
	renderer._mark_motion()

func _on_mas_toggled(pressed: bool) -> void:
	renderer.VRS = pressed
	renderer._mark_motion()

func _on_mas_scale_changed(value: float) -> void:
	var scale := int(value)
	mas_scale_lbl.text = "MAS Scale: %d" % scale
	renderer.VRSScale = scale
	renderer._mark_motion()

func _on_sensitivity_changed(value: float) -> void:
	sensitivity_lbl.text = "Sensitivity: %.3f" % value
	renderer.camera_rig.mouse_sensitivity = value
	renderer._mark_motion()

func _on_smooth_orbit_toggled(pressed: bool) -> void:
	renderer.camera_rig.smooth_orbit = pressed
	renderer._mark_motion()

func _on_camera_mode_selected(index: int) -> void:
	renderer.camera_rig.current_mode = index
	renderer._mark_motion()

func _sync_ui() -> void:
	iterations_slider.value = Global.g_fractal.iterations
	iterations_lbl.text = "Iterations: %d" % Global.g_fractal.iterations

	var defs = Global.g_fractal.get_param_definitions()
	for i in param_rows.size():
		var active = i < defs.size()
		param_rows[i].visible = active
		if not active:
			continue
		var def = defs[i]
		var name = def.get("name", "Param")
		var slider = param_sliders[i]
		slider.min_value = def.get("min", 0.0)
		slider.max_value = def.get("max", 1.0)
		slider.step = def.get("step", 0.01)
		slider.value = Global.g_fractal.get_param_value(i)
		param_labels[i].text = "%s: %.2f" % [name, slider.value]

	pbr_toggle.button_pressed = renderer.use_pbr
	metallic_slider.value = renderer.u_metallic
	roughness_slider.value = renderer.u_roughness
	light_x_slider.value = renderer.u_lightDir.x
	light_y_slider.value = renderer.u_lightDir.y
	light_z_slider.value = renderer.u_lightDir.z
	mas_toggle.button_pressed = renderer.VRS
	mas_scale_slider.value = renderer.VRSScale
	sensitivity_slider.value = renderer.camera_rig.mouse_sensitivity
	smooth_orbit_toggle.button_pressed = renderer.camera_rig.smooth_orbit
	camera_mode_dropdown.select(renderer.camera_rig.current_mode)
