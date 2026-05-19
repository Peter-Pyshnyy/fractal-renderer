extends VBoxContainer

const COLLAPSED_ARROW := "▶"
const EXPANDED_ARROW := "▼"

func _ready() -> void:
	for i in range(get_child_count()):
		var child = get_child(i)

		if child is Button and child.toggle_mode:
			var content_panel = get_child(i + 1)

			if content_panel and content_panel is VBoxContainer:
				child.button_pressed = false
				content_panel.visible = false
				child.toggled.connect(_on_section_toggled.bind(content_panel, child))
				_update_button_visual(child)

func _on_section_toggled(button_pressed: bool, content_panel: Control, btn: Button) -> void:
	content_panel.visible = button_pressed
	_update_button_visual(btn)

func _update_button_visual(btn: Button) -> void:
	var arrow_label := btn.get_node_or_null("HeaderRow/HeaderArrow") as Label
	if arrow_label == null:
		return
	arrow_label.text = EXPANDED_ARROW if btn.button_pressed else COLLAPSED_ARROW
