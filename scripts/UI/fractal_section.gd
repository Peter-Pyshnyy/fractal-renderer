extends VBoxContainer

var _syncing := false
@onready var dropdown: OptionButton = $FractalDropdown
@onready var iter_slider: HSlider = $IterationsSlider
@onready var iter_lbl: Label = $IterationsLbl
var _param_rows: Array
var _param_labels: Array
var _param_sliders: Array

func _ready() -> void:
	_param_rows = [$FractalParamRow1, $FractalParamRow2, $FractalParamRow3]
	_param_labels = [$FractalParamRow1/FractalParamLbl, $FractalParamRow2/FractalParamLbl, $FractalParamRow3/FractalParamLbl]
	_param_sliders = [$FractalParamRow1/FractalParamSlider, $FractalParamRow2/FractalParamSlider, $FractalParamRow3/FractalParamSlider]
	_wire_signals()
	_connect_state()
	await get_tree().process_frame  # fractal_data is null until renderer._ready() seeds it
	_sync()

func _wire_signals() -> void:
	dropdown.add_item("Mandelbulb")
	dropdown.add_item("Sierpinski Koleidoscope")
	dropdown.item_selected.connect(func(i): if not _syncing: _on_fractal_selected(i))
	iter_slider.min_value = 1; iter_slider.max_value = 100; iter_slider.step = 1
	iter_slider.value_changed.connect(func(v):
		if _syncing: return
		iter_lbl.text = "Iterations: %d" % int(v)
		StateBus.scene.set_iterations(int(v)))
	for i in 3:
		_param_sliders[i].value_changed.connect(func(v, idx=i): _on_param_changed(v, idx))

func _connect_state() -> void:
	StateBus.scene.changed.connect(_sync)

func _on_fractal_selected(idx: int) -> void:
	var data: FractalData = Global.g_data_arr[idx]
	var defs := data.get_param_definitions()
	for i in defs.size():
		data.set_param_value(i, defs[i].get("default", data.get_param_value(i)))
	StateBus.scene.switch_fractal(idx, data)

func _on_param_changed(v: float, idx: int) -> void:
	if _syncing: return
	if StateBus.scene.fractal_data == null: return
	var defs := StateBus.scene.fractal_data.get_param_definitions()
	if idx >= defs.size(): return
	_param_labels[idx].text = "%s: %.2f" % [defs[idx].get("name", "Param"), v]
	StateBus.scene.set_param(idx, v)

func _sync() -> void:
	if StateBus.scene.fractal_data == null: return
	_syncing = true
	dropdown.selected = StateBus.scene.fractal_index
	var fd := StateBus.scene.fractal_data
	iter_slider.value = fd.iterations
	iter_lbl.text = "Iterations: %d" % fd.iterations
	var defs := fd.get_param_definitions()
	for i in _param_rows.size():
		var active := i < defs.size()
		_param_rows[i].visible = active
		if not active: continue
		_param_sliders[i].min_value = defs[i].get("min", 0.0)
		_param_sliders[i].max_value = defs[i].get("max", 1.0)
		_param_sliders[i].step = defs[i].get("step", 0.01)
		_param_sliders[i].value = fd.get_param_value(i)
		_param_labels[i].text = "%s: %.2f" % [defs[i].get("name", "Param"), fd.get_param_value(i)]
	_syncing = false
