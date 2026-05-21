extends VBoxContainer

var _syncing := false
@onready var pbr_toggle: CheckBox = $PBRToggle
@onready var metallic_slider: HSlider = $MetallicSlider
@onready var metallic_lbl: Label = $MetallicLbl
@onready var roughness_slider: HSlider = $RoughnessSlider
@onready var roughness_lbl: Label = $RoughnessLbl
@onready var light_x_slider: HSlider = $LightXSlider
@onready var light_x_lbl: Label = $LightXLbl
@onready var light_y_slider: HSlider = $LightYSlider
@onready var light_y_lbl: Label = $LightYLbl
@onready var light_z_slider: HSlider = $LightZSlider
@onready var light_z_lbl: Label = $LightZLbl
@onready var background_color_picker: ColorPickerButton = $BackgroundColorPicker

func _ready() -> void:
	_wire_signals()
	_connect_state()
	_sync()

func _wire_signals() -> void:
	pbr_toggle.toggled.connect(func(v): if not _syncing: StateBus.scene.use_pbr = v)
	metallic_slider.min_value = 0.0; metallic_slider.max_value = 1.0; metallic_slider.step = 0.01
	metallic_slider.value_changed.connect(func(v):
		if _syncing: return
		metallic_lbl.text = "Metallic: %.2f" % v; StateBus.scene.metallic = v)
	roughness_slider.min_value = 0.0; roughness_slider.max_value = 1.0; roughness_slider.step = 0.01
	roughness_slider.value_changed.connect(func(v):
		if _syncing: return
		roughness_lbl.text = "Roughness: %.2f" % v; StateBus.scene.roughness = v)
	light_x_slider.min_value = -5.0; light_x_slider.max_value = 5.0; light_x_slider.step = 0.01
	light_x_slider.value_changed.connect(func(v):
		if _syncing: return
		light_x_lbl.text = "Light X: %.2f" % v
		StateBus.scene.light_dir = Vector3(v, StateBus.scene.light_dir.y, StateBus.scene.light_dir.z))
	light_y_slider.min_value = -5.0; light_y_slider.max_value = 5.0; light_y_slider.step = 0.01
	light_y_slider.value_changed.connect(func(v):
		if _syncing: return
		light_y_lbl.text = "Light Y: %.2f" % v
		StateBus.scene.light_dir = Vector3(StateBus.scene.light_dir.x, v, StateBus.scene.light_dir.z))
	light_z_slider.min_value = -5.0; light_z_slider.max_value = 5.0; light_z_slider.step = 0.01
	light_z_slider.value_changed.connect(func(v):
		if _syncing: return
		light_z_lbl.text = "Light Z: %.2f" % v
		StateBus.scene.light_dir = Vector3(StateBus.scene.light_dir.x, StateBus.scene.light_dir.y, v))
	background_color_picker.color_changed.connect(func(v):
		if _syncing: return
		StateBus.scene.background_color = v)

func _connect_state() -> void:
	StateBus.scene.changed.connect(_sync)

func _sync() -> void:
	_syncing = true
	pbr_toggle.button_pressed = StateBus.scene.use_pbr
	metallic_slider.value = StateBus.scene.metallic
	metallic_lbl.text = "Metallic: %.2f" % StateBus.scene.metallic
	roughness_slider.value = StateBus.scene.roughness
	roughness_lbl.text = "Roughness: %.2f" % StateBus.scene.roughness
	var ld := StateBus.scene.light_dir
	light_x_slider.value = ld.x; light_x_lbl.text = "Light X: %.2f" % ld.x
	light_y_slider.value = ld.y; light_y_lbl.text = "Light Y: %.2f" % ld.y
	light_z_slider.value = ld.z; light_z_lbl.text = "Light Z: %.2f" % ld.z
	background_color_picker.color = StateBus.scene.background_color
	_syncing = false
