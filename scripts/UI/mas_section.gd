extends VBoxContainer

var _syncing := false

@onready var mas_toggle:   CheckBox = $MASToggle
@onready var scale_slider: HSlider  = $MASScaleSlider
@onready var scale_lbl:    Label    = $MASScaleLbl


func _ready() -> void:
	_wire_signals()
	_connect_state()
	_sync()


func _wire_signals() -> void:
	mas_toggle.toggled.connect(func(v): if not _syncing: StateBus.render.vrs_enabled = v)

	scale_slider.value_changed.connect(func(v):
		if _syncing: return
		var s := int(v)
		scale_lbl.text = "MAS Scale: %d" % s
		StateBus.render.vrs_scale = s)


func _connect_state() -> void:
	StateBus.render.changed.connect(_sync)


func _sync() -> void:
	_syncing = true
	mas_toggle.button_pressed = StateBus.render.vrs_enabled
	scale_slider.value = StateBus.render.vrs_scale
	scale_lbl.text = "MAS Scale: %d" % StateBus.render.vrs_scale
	_syncing = false
