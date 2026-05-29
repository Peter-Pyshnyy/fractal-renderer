extends VBoxContainer

var _syncing := false

@onready var pbr_toggle:              CheckBox          = $PBRToggle
@onready var metallic_slider:         HSlider           = $MetallicSlider
@onready var metallic_lbl:            Label             = $MetallicLbl
@onready var roughness_slider:        HSlider           = $RoughnessSlider
@onready var roughness_lbl:           Label             = $RoughnessLbl
@onready var light_type_dropdown:     OptionButton      = $LightTypeDropdown
@onready var dir_pos_group:           VBoxContainer     = $DirPosGroup
@onready var light_x_slider:          HSlider           = $DirPosGroup/LightXSlider
@onready var light_x_lbl:             Label             = $DirPosGroup/LightXLbl
@onready var light_y_slider:          HSlider           = $DirPosGroup/LightYSlider
@onready var light_y_lbl:             Label             = $DirPosGroup/LightYLbl
@onready var light_z_slider:          HSlider           = $DirPosGroup/LightZSlider
@onready var light_z_lbl:             Label             = $DirPosGroup/LightZLbl
@onready var radius_group:            VBoxContainer     = $RadiusGroup
@onready var light_radius_slider:     HSlider           = $RadiusGroup/LightRadiusSlider
@onready var light_radius_lbl:        Label             = $RadiusGroup/LightRadiusLbl
@onready var light_color_picker:      ColorPickerButton = $LightColorGroup/LightColorPicker
@onready var light_multiplier_slider: HSlider           = $LightColorGroup/LightMultiplierSlider
@onready var light_multiplier_lbl:    Label             = $LightColorGroup/LightMultiplierLbl
@onready var exposure_slider:         HSlider           = $ExposureSlider
@onready var exposure_lbl:            Label             = $ExposureLbl
@onready var background_color_picker: ColorPickerButton = $BackgroundColorPicker


func _ready() -> void:
	_wire_signals()
	_connect_state()
	_sync()


func _wire_signals() -> void:
	pbr_toggle.toggled.connect(func(v): if not _syncing: StateBus.scene.use_pbr = v)

	metallic_slider.value_changed.connect(func(v):
		if _syncing: return
		metallic_lbl.text = "Metallic: %.2f" % v
		StateBus.scene.metallic = v)

	roughness_slider.value_changed.connect(func(v):
		if _syncing: return
		roughness_lbl.text = "Roughness: %.2f" % v
		StateBus.scene.roughness = v)

	light_type_dropdown.item_selected.connect(func(i):
		if not _syncing:
			StateBus.scene.light_type = i
			_update_light_groups(i))

	light_x_slider.value_changed.connect(func(v):
		if _syncing: return
		_update_dir_pos_labels()
		StateBus.scene.light_dir = Vector3(v, StateBus.scene.light_dir.y, StateBus.scene.light_dir.z))

	light_y_slider.value_changed.connect(func(v):
		if _syncing: return
		_update_dir_pos_labels()
		StateBus.scene.light_dir = Vector3(StateBus.scene.light_dir.x, v, StateBus.scene.light_dir.z))

	light_z_slider.value_changed.connect(func(v):
		if _syncing: return
		_update_dir_pos_labels()
		StateBus.scene.light_dir = Vector3(StateBus.scene.light_dir.x, StateBus.scene.light_dir.y, v))

	light_radius_slider.value_changed.connect(func(v):
		if _syncing: return
		light_radius_lbl.text = "Radius Mult: %.1f" % v
		StateBus.scene.light_radius_mult = v)

	light_color_picker.color_changed.connect(func(v):
		if _syncing: return
		StateBus.scene.light_color = v)

	light_multiplier_slider.value_changed.connect(func(v):
		if _syncing: return
		light_multiplier_lbl.text = "Brightness: %.2f" % v
		StateBus.scene.light_multiplier = v)

	exposure_slider.value_changed.connect(func(v):
		if _syncing: return
		exposure_lbl.text = "Exposure: %.2f" % v
		StateBus.scene.exposure = v)

	background_color_picker.color_changed.connect(func(v):
		if _syncing: return
		StateBus.scene.background_color = v)


func _connect_state() -> void:
	StateBus.scene.changed.connect(_sync)


func _update_dir_pos_labels() -> void:
	var is_dir := StateBus.scene.light_type == 0
	var x := light_x_slider.value
	var y := light_y_slider.value
	var z := light_z_slider.value
	if is_dir:
		light_x_lbl.text = "Dir X: %.2f" % x
		light_y_lbl.text = "Dir Y: %.2f" % y
		light_z_lbl.text = "Dir Z: %.2f" % z
	else:
		light_x_lbl.text = "Pos X: %.2f" % x
		light_y_lbl.text = "Pos Y: %.2f" % y
		light_z_lbl.text = "Pos Z: %.2f" % z


func _update_light_groups(light_type: int) -> void:
	dir_pos_group.visible = light_type != 2
	radius_group.visible  = light_type != 0
	_update_dir_pos_labels()


func _sync() -> void:
	_syncing = true
	pbr_toggle.button_pressed = StateBus.scene.use_pbr
	metallic_slider.value   = StateBus.scene.metallic
	metallic_lbl.text       = "Metallic: %.2f"   % StateBus.scene.metallic
	roughness_slider.value  = StateBus.scene.roughness
	roughness_lbl.text      = "Roughness: %.2f"  % StateBus.scene.roughness
	light_type_dropdown.selected = StateBus.scene.light_type
	var ld := StateBus.scene.light_dir
	light_x_slider.value = ld.x
	light_y_slider.value = ld.y
	light_z_slider.value = ld.z
	light_radius_slider.value   = StateBus.scene.light_radius_mult
	light_radius_lbl.text       = "Radius Mult: %.1f" % StateBus.scene.light_radius_mult
	light_color_picker.color    = StateBus.scene.light_color
	light_multiplier_slider.value = StateBus.scene.light_multiplier
	light_multiplier_lbl.text   = "Brightness: %.2f" % StateBus.scene.light_multiplier
	exposure_slider.value   = StateBus.scene.exposure
	exposure_lbl.text       = "Exposure: %.2f"   % StateBus.scene.exposure
	background_color_picker.color = StateBus.scene.background_color
	_update_light_groups(StateBus.scene.light_type)
	_syncing = false
