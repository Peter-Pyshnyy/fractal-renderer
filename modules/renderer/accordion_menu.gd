extends VBoxContainer

const COLLAPSED_ARROW := "▶"
const EXPANDED_ARROW := "▼"

func _ready() -> void:
	# Проходимося по всіх дочірніх вузлах
	for i in range(get_child_count()):
		var child = get_child(i)
		
		# Шукаємо кнопки, які є заголовками секцій
		if child is Button and child.toggle_mode:
			# Наступний вузол після кнопки ЗАВЖДИ має бути її контентом (VBoxContainer)
			var content_panel = get_child(i + 1)
			
			if content_panel and content_panel is VBoxContainer:
				# Встановлюємо початковий стан (наприклад, згорнуто)
				child.button_pressed = false
				content_panel.visible = false
				child.clip_text = true
				child.alignment = HORIZONTAL_ALIGNMENT_LEFT
				child.resized.connect(_update_button_text.bind(child))
				_update_button_text(child)
				
				# Підключаємо сигнал натискання кнопки
				child.toggled.connect(_on_section_toggled.bind(content_panel, child))

# Функція, яка ховає або показує контент
func _on_section_toggled(button_pressed: bool, content_panel: Control, btn: Button) -> void:
	content_panel.visible = button_pressed
	# Опціонально: змінюємо текст кнопки (стрілочка вниз/вправо)
	if button_pressed:
		btn.set_meta("expanded", true)
	else:
		btn.set_meta("expanded", false)
	_update_button_text(btn)

func _update_button_text(btn: Button) -> void:
	var base_text = btn.get_meta("base_text", "")
	if base_text == "":
		base_text = btn.text.trim_suffix(" %s" % COLLAPSED_ARROW).trim_suffix(" %s" % EXPANDED_ARROW)
		btn.set_meta("base_text", base_text)

	var arrow = EXPANDED_ARROW if btn.get_meta("expanded", false) else COLLAPSED_ARROW
	var font = btn.get_theme_font("font")
	var font_size = btn.get_theme_font_size("font_size")
	var arrow_text = " %s" % arrow
	var space_width = font.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var total_width = btn.size.x
	var used_width = font.get_string_size(base_text + arrow_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var spaces = maxi(int((total_width - used_width) / max(space_width, 1.0)), 1)
	btn.text = "%s%s%s" % [base_text, " ".repeat(spaces), arrow]
