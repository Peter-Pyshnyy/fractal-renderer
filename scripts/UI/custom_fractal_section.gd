class_name CustomFractalSection
extends VBoxContainer

var _text_edit: TextEdit
var _radius_slider: HSlider
var _radius_lbl: Label
var _compile_btn: Button
var _status_lbl: Label

func _ready() -> void:
	_build_ui()
	_sync_from_state()

func _build_ui() -> void:
	var src_lbl := Label.new()
	src_lbl.text = "GLSL Source (sdf + sdf_with_trap):"
	add_child(src_lbl)

	_text_edit = TextEdit.new()
	_text_edit.custom_minimum_size = Vector2(0, 320)
	_text_edit.wrap_mode = TextEdit.LINE_WRAPPING_NONE
	add_child(_text_edit)

	var radius_row := HBoxContainer.new()
	add_child(radius_row)

	_radius_lbl = Label.new()
	_radius_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	radius_row.add_child(_radius_lbl)

	_radius_slider = HSlider.new()
	_radius_slider.min_value = 0.1
	_radius_slider.max_value = 5.0
	_radius_slider.step = 0.01
	_radius_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	radius_row.add_child(_radius_slider)

	_compile_btn = Button.new()
	_compile_btn.text = "Compile"
	add_child(_compile_btn)

	_status_lbl = Label.new()
	_status_lbl.text = ""
	_status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_status_lbl)

	_radius_slider.value_changed.connect(_on_radius_changed)
	_compile_btn.pressed.connect(_on_compile_pressed)

func _sync_from_state() -> void:
	var data := Global.custom_fractal_data
	_text_edit.text = data.glsl_source
	_radius_slider.value = data.sphere_radius
	_radius_lbl.text = "Sphere radius: %.2f" % data.sphere_radius

func _on_radius_changed(v: float) -> void:
	Global.custom_fractal_data.sphere_radius = v
	_radius_lbl.text = "Sphere radius: %.2f" % v

func _on_compile_pressed() -> void:
	var data := Global.custom_fractal_data
	data.glsl_source = _text_edit.text

	if StateBus.renderer_controller == null:
		_set_status("Error: renderer not ready", true)
		return

	_set_status("Compiling...", false)
	var err: String = StateBus.renderer_controller.compile_custom_shader(data.glsl_source)
	if err == "":
		_set_status("Compiled OK", false)
		if StateBus.scene.fractal_index != 8:
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
