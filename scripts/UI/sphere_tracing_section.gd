extends VBoxContainer

var _syncing := false
@onready var sdf_scalar_slider: HSlider = $SDFScalarSlider
@onready var sdf_scalar_lbl: Label = $SDFScalarLbl
@onready var lod_scalar_slider: HSlider = $LODScalarSlider
@onready var lod_scalar_lbl: Label = $LODScalarLbl
@onready var max_steps_slider: HSlider = $MaxStepsSlider
@onready var max_steps_lbl: Label = $MaxStepsLbl

func _ready() -> void:
	_wire_signals()
	_connect_state()
	_sync() 

func _wire_signals() -> void:
	sdf_scalar_slider.min_value = 0.1; sdf_scalar_slider.max_value = 2.0; sdf_scalar_slider.step = 0.01
	sdf_scalar_slider.value_changed.connect(func(v):
		if _syncing: return
		sdf_scalar_lbl.text = "Step-Size Scalar: %.2f" % v
		StateBus.scene.sdf_scalar = v)
	lod_scalar_slider.min_value = 0.1; lod_scalar_slider.max_value = 2.0; lod_scalar_slider.step = 0.01
	lod_scalar_slider.value_changed.connect(func(v):
		if _syncing: return
		lod_scalar_lbl.text = "LOD Scalar: %.2f" % v
		StateBus.scene.lod_scalar = v)
	max_steps_slider.min_value = 10; max_steps_slider.max_value = 1500; max_steps_slider.step = 1
	max_steps_slider.value_changed.connect(func(v):
		if _syncing: return
		max_steps_lbl.text = "Max Steps: %d" % int(v)
		StateBus.scene.max_steps = int(v))

func _connect_state() -> void:
	StateBus.scene.changed.connect(_sync)

func _sync() -> void:
	_syncing = true
	sdf_scalar_slider.value = StateBus.scene.sdf_scalar
	sdf_scalar_lbl.text = "Step-Size Scalar: %.2f" % StateBus.scene.sdf_scalar
	lod_scalar_slider.value = StateBus.scene.lod_scalar
	lod_scalar_lbl.text = "LOD Scalar: %.2f" % StateBus.scene.lod_scalar
	max_steps_slider.value = StateBus.scene.max_steps
	max_steps_lbl.text = "Max Steps: %d" % StateBus.scene.max_steps
	_syncing = false
