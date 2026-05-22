extends VBoxContainer

var _syncing := false

@onready var color_mode_dropdown: OptionButton      = $ColorModeDropdown

@onready var uniform_group:       VBoxContainer     = $UniformGroup
@onready var uniform_color_picker: ColorPickerButton = $UniformGroup/UniformColorPicker

@onready var iter_group:          VBoxContainer     = $IterGroup
@onready var iter_norm_lbl:       Label             = $IterGroup/IterNormLbl
@onready var iter_norm_slider:    HSlider           = $IterGroup/IterNormSlider
@onready var iter_bw_preview:     CheckBox          = $IterGroup/IterBWPreview

@onready var trap_group:          VBoxContainer     = $TrapGroup
@onready var trap_shape_dropdown: OptionButton      = $TrapGroup/TrapShapeDropdown
@onready var trap_pos_x_lbl:      Label             = $TrapGroup/TrapPosXLbl
@onready var trap_pos_x_slider:   HSlider           = $TrapGroup/TrapPosXSlider
@onready var trap_pos_y_lbl:      Label             = $TrapGroup/TrapPosYLbl
@onready var trap_pos_y_slider:   HSlider           = $TrapGroup/TrapPosYSlider
@onready var trap_pos_z_lbl:      Label             = $TrapGroup/TrapPosZLbl
@onready var trap_pos_z_slider:   HSlider           = $TrapGroup/TrapPosZSlider
@onready var trap_size_lbl:       Label             = $TrapGroup/TrapSizeLbl
@onready var trap_size_slider:    HSlider           = $TrapGroup/TrapSizeSlider
@onready var trap_norm_k_lbl:     Label             = $TrapGroup/TrapNormKLbl
@onready var trap_norm_k_slider:  HSlider           = $TrapGroup/TrapNormKSlider
@onready var trap_lp_power_lbl:   Label             = $TrapGroup/TrapLpPowerLbl
@onready var trap_lp_power_slider: HSlider          = $TrapGroup/TrapLpPowerSlider
@onready var trap_bw_preview:     CheckBox          = $TrapGroup/TrapBWPreview

@onready var palette_group:       VBoxContainer     = $PaletteGroup
@onready var palette_dropdown:    OptionButton      = $PaletteGroup/PaletteDropdown

@onready var color_blend_params:  VBoxContainer     = $PaletteGroup/ColorBlendParams
@onready var color_a_picker:      ColorPickerButton = $PaletteGroup/ColorBlendParams/ColorAPicker
@onready var color_b_picker:      ColorPickerButton = $PaletteGroup/ColorBlendParams/ColorBPicker

@onready var sinmask_params:      VBoxContainer     = $PaletteGroup/SinmaskParams
@onready var sinmask_phase_lbl:   Label             = $PaletteGroup/SinmaskParams/SinmaskPhaseLbl
@onready var sinmask_phase_slider: HSlider          = $PaletteGroup/SinmaskParams/SinmaskPhaseSlider
@onready var sinmask_amp_lbl:     Label             = $PaletteGroup/SinmaskParams/SinmaskAmpLbl
@onready var sinmask_amp_slider:  HSlider           = $PaletteGroup/SinmaskParams/SinmaskAmpSlider

@onready var hsv_params:          VBoxContainer     = $PaletteGroup/HSVParams
@onready var hsv_cycles_lbl:      Label             = $PaletteGroup/HSVParams/HSVCyclesLbl
@onready var hsv_cycles_slider:   HSlider           = $PaletteGroup/HSVParams/HSVCyclesSlider
@onready var hsv_offset_lbl:      Label             = $PaletteGroup/HSVParams/HSVOffsetLbl
@onready var hsv_offset_slider:   HSlider           = $PaletteGroup/HSVParams/HSVOffsetSlider
@onready var hsv_blend_lbl:       Label             = $PaletteGroup/HSVParams/HSVBlendLbl
@onready var hsv_blend_slider:    HSlider           = $PaletteGroup/HSVParams/HSVBlendSlider
@onready var hsv_base_picker:     ColorPickerButton = $PaletteGroup/HSVParams/HSVBasePicker


func _ready() -> void:
    _wire_signals()
    _connect_state()
    _sync()


func _wire_signals() -> void:
    color_mode_dropdown.add_item("Uniform")
    color_mode_dropdown.add_item("Iteration Count")
    color_mode_dropdown.add_item("Orbit Trap")
    color_mode_dropdown.item_selected.connect(func(i):
        if not _syncing: StateBus.scene.color_mode = i)

    iter_norm_slider.min_value = 1.0
    iter_norm_slider.max_value = 200.0
    iter_norm_slider.step = 0.5
    iter_norm_slider.value_changed.connect(func(v):
        if _syncing: return
        iter_norm_lbl.text = "Iter. Norm.: %.1f" % v
        StateBus.scene.iter_norm_factor = v)

    iter_bw_preview.toggled.connect(func(v):
        if not _syncing: StateBus.scene.iter_bw_preview = v)

    trap_shape_dropdown.add_item("Sphere")
    trap_shape_dropdown.add_item("Plane")
    trap_shape_dropdown.add_item("Box")
    trap_shape_dropdown.add_item("Axes")
    trap_shape_dropdown.add_item("Cylinder")
    trap_shape_dropdown.item_selected.connect(func(i):
        if not _syncing:
            StateBus.scene.trap_shape = i
            _update_trap_size_visibility(i))

    _configure_slider(trap_pos_x_slider, -3.0, 3.0, 0.01)
    trap_pos_x_slider.value_changed.connect(func(v):
        if _syncing: return
        trap_pos_x_lbl.text = "Trap X: %.2f" % v
        StateBus.scene.trap_position = Vector3(v, StateBus.scene.trap_position.y, StateBus.scene.trap_position.z))

    _configure_slider(trap_pos_y_slider, -3.0, 3.0, 0.01)
    trap_pos_y_slider.value_changed.connect(func(v):
        if _syncing: return
        trap_pos_y_lbl.text = "Trap Y: %.2f" % v
        StateBus.scene.trap_position = Vector3(StateBus.scene.trap_position.x, v, StateBus.scene.trap_position.z))

    _configure_slider(trap_pos_z_slider, -3.0, 3.0, 0.01)
    trap_pos_z_slider.value_changed.connect(func(v):
        if _syncing: return
        trap_pos_z_lbl.text = "Trap Z: %.2f" % v
        StateBus.scene.trap_position = Vector3(StateBus.scene.trap_position.x, StateBus.scene.trap_position.y, v))

    _configure_slider(trap_size_slider, 0.01, 5.0, 0.01)
    trap_size_slider.value_changed.connect(func(v):
        if _syncing: return
        trap_size_lbl.text = "Trap Size: %.2f" % v
        StateBus.scene.trap_size = v)

    _configure_slider(trap_norm_k_slider, 0.01, 2.0, 0.01)
    trap_norm_k_slider.value_changed.connect(func(v):
        if _syncing: return
        trap_norm_k_lbl.text = "Norm. K: %.2f" % v
        StateBus.scene.trap_norm_k = v)

    _configure_slider(trap_lp_power_slider, 0.5, 8.0, 0.05)
    trap_lp_power_slider.value_changed.connect(func(v):
        if _syncing: return
        trap_lp_power_lbl.text = "Lp Power: %.2f" % v
        StateBus.scene.trap_lp_power = v)

    trap_bw_preview.toggled.connect(func(v):
        if not _syncing: StateBus.scene.trap_bw_preview = v)

    palette_dropdown.add_item("Color Blend")
    palette_dropdown.add_item("Sinmask")
    palette_dropdown.add_item("HSV")
    palette_dropdown.add_item("Viridis")
    palette_dropdown.add_item("Heat")
    palette_dropdown.item_selected.connect(func(i):
        if not _syncing: StateBus.scene.palette_type = i)

    color_a_picker.color_changed.connect(func(c):
        if not _syncing: StateBus.scene.set_color_a(c))
    color_b_picker.color_changed.connect(func(c):
        if not _syncing: StateBus.scene.set_color_b(c))

    _configure_slider(sinmask_phase_slider, -3.14159, 3.14159, 0.01)
    sinmask_phase_slider.value_changed.connect(func(v):
        if _syncing: return
        sinmask_phase_lbl.text = "Phase: %.2f" % v
        StateBus.scene.sinmask_phase = v)

    _configure_slider(sinmask_amp_slider, 0.1, 10.0, 0.01)
    sinmask_amp_slider.value_changed.connect(func(v):
        if _syncing: return
        sinmask_amp_lbl.text = "Amplitude: %.2f" % v
        StateBus.scene.sinmask_amp = v)


    _configure_slider(hsv_cycles_slider, 0.1, 20.0, 0.01)
    hsv_cycles_slider.value_changed.connect(func(v):
        if _syncing: return
        hsv_cycles_lbl.text = "Hue Cycles: %.2f" % v
        StateBus.scene.hsv_cycles = v)

    _configure_slider(hsv_offset_slider, 0.0, 10.0, 0.01)
    hsv_offset_slider.value_changed.connect(func(v):
        if _syncing: return
        hsv_offset_lbl.text = "Hue Offset: %.2f" % v
        StateBus.scene.hsv_hue_offset = v)

    _configure_slider(hsv_blend_slider, 0.0, 1.0, 0.01)
    hsv_blend_slider.value_changed.connect(func(v):
        if _syncing: return
        hsv_blend_lbl.text = "Base Blend: %.2f" % v
        StateBus.scene.hsv_blend = v)

    hsv_base_picker.color_changed.connect(func(c):
        if not _syncing: StateBus.scene.set_color_a(c))

    uniform_color_picker.color_changed.connect(func(c):
        if not _syncing: StateBus.scene.uniform_color = c)


func _configure_slider(s: HSlider, mn: float, mx: float, st: float) -> void:
    s.min_value = mn; s.max_value = mx; s.step = st


func _connect_state() -> void:
    StateBus.scene.changed.connect(_sync)


func _update_trap_size_visibility(shape: int) -> void:
    trap_size_lbl.visible  = shape != 2
    trap_size_slider.visible = shape != 2


func _sync() -> void:
    _syncing = true
    var s := StateBus.scene

    color_mode_dropdown.selected = s.color_mode

    uniform_group.visible  = (s.color_mode == 0)
    iter_group.visible     = (s.color_mode == 1)
    trap_group.visible     = (s.color_mode == 2)
    palette_group.visible  = (s.color_mode != 0)

    uniform_color_picker.color = s.uniform_color

    iter_norm_lbl.text     = "Iter. Norm.: %.1f" % s.iter_norm_factor
    iter_norm_slider.value = s.iter_norm_factor
    iter_bw_preview.button_pressed = s.iter_bw_preview

    trap_shape_dropdown.selected = s.trap_shape
    _update_trap_size_visibility(s.trap_shape)
    trap_pos_x_lbl.text = "Trap X: %.2f" % s.trap_position.x; trap_pos_x_slider.value = s.trap_position.x
    trap_pos_y_lbl.text = "Trap Y: %.2f" % s.trap_position.y; trap_pos_y_slider.value = s.trap_position.y
    trap_pos_z_lbl.text = "Trap Z: %.2f" % s.trap_position.z; trap_pos_z_slider.value = s.trap_position.z
    trap_size_lbl.text  = "Trap Size: %.2f" % s.trap_size;    trap_size_slider.value  = s.trap_size
    trap_norm_k_lbl.text = "Norm. K: %.2f" % s.trap_norm_k;   trap_norm_k_slider.value = s.trap_norm_k
    trap_lp_power_lbl.text = "Lp Power: %.2f" % s.trap_lp_power; trap_lp_power_slider.value = s.trap_lp_power
    trap_bw_preview.button_pressed = s.trap_bw_preview

    palette_dropdown.selected = s.palette_type
    color_blend_params.visible = (s.palette_type == 0)
    sinmask_params.visible     = (s.palette_type == 1)
    hsv_params.visible         = (s.palette_type == 2)

    color_a_picker.color   = s.material.color0
    color_b_picker.color   = s.material.color1

    sinmask_phase_lbl.text  = "Phase: %.2f" % s.sinmask_phase;  sinmask_phase_slider.value  = s.sinmask_phase
    sinmask_amp_lbl.text    = "Amplitude: %.2f" % s.sinmask_amp; sinmask_amp_slider.value   = s.sinmask_amp

    hsv_cycles_lbl.text  = "Hue Cycles: %.2f" % s.hsv_cycles;   hsv_cycles_slider.value  = s.hsv_cycles
    hsv_offset_lbl.text  = "Hue Offset: %.2f" % s.hsv_hue_offset; hsv_offset_slider.value = s.hsv_hue_offset
    hsv_blend_lbl.text   = "Base Blend: %.2f" % s.hsv_blend;    hsv_blend_slider.value   = s.hsv_blend
    hsv_base_picker.color = s.material.color0

    _syncing = false
