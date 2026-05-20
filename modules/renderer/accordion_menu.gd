extends Button

@export var content: Control

const COLLAPSED := "▶  "
const EXPANDED  := "▼  "

func _ready() -> void:
	toggle_mode = true
	button_pressed = false
	if content: content.visible = false
	toggled.connect(_on_toggled)
	_update_arrow()

func _on_toggled(pressed: bool) -> void:
	if content: content.visible = pressed
	_update_arrow()

func _update_arrow() -> void:
	var arrow := get_node_or_null("HeaderRow/HeaderArrow") as Label
	if arrow:
		arrow.text = EXPANDED if button_pressed else COLLAPSED
