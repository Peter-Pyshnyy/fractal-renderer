class_name CustomFractalSection
extends VBoxContainer

@onready var _text_edit:     TextEdit          = $TextEdit
@onready var _radius_lbl:    Label             = $RadiusLbl
@onready var _radius_slider: HSlider           = $RadiusSlider
@onready var _compile_btn:   Button            = $CompileBtn
@onready var _status_lbl:    Label             = $StatusLbl

var _param_inputs: Array[LineEdit] = []


func _ready() -> void:
	_radius_slider.value_changed.connect(_on_radius_changed)
	_compile_btn.pressed.connect(_on_compile_pressed)
	_text_edit.add_theme_font_size_override("font_size", 12)

	for i in 8:
		var input: LineEdit = $ParamsGrid.get_node("P%dInput" % i)
		_param_inputs.append(input)
		var idx := i
		input.text_submitted.connect(func(_t: String) -> void: _on_param_changed(idx))
		input.focus_exited.connect(func() -> void: _on_param_changed(idx))

	_sync_from_state()


func _sync_from_state() -> void:
	var data := Global.custom_fractal_data
	_text_edit.text      = data.glsl_source
	_radius_slider.value = data.sphere_radius
	_radius_lbl.text     = "min_zoom radius: %.2f" % data.sphere_radius
	for i in 8:
		_param_inputs[i].text = str(data.fractal_params[i])


func _on_param_changed(idx: int) -> void:
	var raw := _param_inputs[idx].text
	var v := float(raw) if raw.is_valid_float() else 0.0
	_param_inputs[idx].text = str(v)
	Global.custom_fractal_data.fractal_params[idx] = v
	if StateBus.scene.fractal_index == 7:
		StateBus.scene.emit_changed()


func _on_radius_changed(v: float) -> void:
	Global.custom_fractal_data.sphere_radius = v
	_radius_lbl.text = "min_zoom radius: %.2f" % v


func _on_compile_pressed() -> void:
	var data := Global.custom_fractal_data
	data.glsl_source = _text_edit.text
	for i in 8:
		var raw := _param_inputs[i].text
		data.fractal_params[i] = float(raw) if raw.is_valid_float() else 0.0
	if StateBus.renderer_controller == null:
		_set_status("Error: renderer not ready", true)
		return
	_set_status("Compiling...", false)
	var err: String = StateBus.renderer_controller.compile_custom_shader(data.glsl_source)
	if err == "":
		_set_status("Compiled OK", false)
		StateBus.scene.switch_fractal(8, data)
	else:
		var short := err.substr(0, 200)
		_set_status("Error: " + short, true)
		_status_lbl.tooltip_text = err


func _set_status(msg: String, is_error: bool) -> void:
	_status_lbl.text = msg
	_status_lbl.add_theme_color_override("font_color", Color.RED if is_error else Color.GREEN)
	if not is_error:
		_status_lbl.tooltip_text = ""
