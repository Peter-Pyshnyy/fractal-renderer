extends VBoxContainer

var _syncing := false

@onready var sensitivity_slider: HSlider = $SensitivitySlider
@onready var sensitivity_lbl:    Label   = $SensitivityLbl
@onready var mode_button:        Button  = $CameraModeSwitch
@onready var fov_slider:         HSlider = $FOVSlider
@onready var fov_lbl:            Label   = $FOVLbl


func _ready() -> void:
	_wire_signals()
	_connect_state()
	_sync()


func _wire_signals() -> void:
	sensitivity_slider.value_changed.connect(func(v):
		if _syncing: return
		sensitivity_lbl.text = "Sensitivity: %.3f" % v
		StateBus.camera.mouse_sensitivity = v)

	mode_button.pressed.connect(_on_mode_pressed)

	fov_slider.value_changed.connect(func(v):
		if _syncing: return
		fov_lbl.text = "FOV: %.0f" % v
		StateBus.camera.fov = v)


func _on_mode_pressed() -> void:
	StateBus.camera.mode = 1 - StateBus.camera.mode


func _connect_state() -> void:
	StateBus.camera.changed.connect(_sync)


func _sync() -> void:
	_syncing = true
	sensitivity_slider.value = StateBus.camera.mouse_sensitivity
	sensitivity_lbl.text = "Sensitivity: %.3f" % StateBus.camera.mouse_sensitivity
	var mode_name := "Free Flight" if StateBus.camera.mode == 0 else "Orbit"
	mode_button.text = "Camera Mode: %s" % mode_name
	fov_slider.value = StateBus.camera.fov
	fov_lbl.text = "FOV: %.0f" % StateBus.camera.fov
	_syncing = false
