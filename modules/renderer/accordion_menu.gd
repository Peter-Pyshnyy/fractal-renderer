extends VBoxContainer

const COLLAPSED_ARROW := "▶"
const EXPANDED_ARROW := "▼"

const META_TITLE_LABEL := "accordion_title_label"
const META_ARROW_LABEL := "accordion_arrow_label"

func _ready() -> void:
	for i in range(get_child_count()):
		var child = get_child(i)

		if child is Button and child.toggle_mode:
			var content_panel = get_child(i + 1)

			if content_panel and content_panel is VBoxContainer:
				_setup_section_button(child)
				child.button_pressed = false
				content_panel.visible = false
				child.toggled.connect(_on_section_toggled.bind(content_panel, child))
				_update_button_visual(child)

func _on_section_toggled(button_pressed: bool, content_panel: Control, btn: Button) -> void:
	content_panel.visible = button_pressed
	_update_button_visual(btn)

func _setup_section_button(btn: Button) -> void:
	var base_text := btn.text.trim_suffix(" %s" % COLLAPSED_ARROW).trim_suffix(" %s" % EXPANDED_ARROW)
	btn.text = ""

	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var title := Label.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.text = base_text
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var arrow := Label.new()
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arrow.text = COLLAPSED_ARROW
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE

	row.add_child(title)
	row.add_child(arrow)
	btn.add_child(row)

	btn.set_meta(META_TITLE_LABEL, title)
	btn.set_meta(META_ARROW_LABEL, arrow)

func _update_button_visual(btn: Button) -> void:
	var arrow_label: Label = btn.get_meta(META_ARROW_LABEL, null)
	if arrow_label == null:
		return
	arrow_label.text = EXPANDED_ARROW if btn.button_pressed else COLLAPSED_ARROW
