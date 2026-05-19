extends VBoxContainer

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
				
				# Підключаємо сигнал натискання кнопки
				child.toggled.connect(_on_section_toggled.bind(content_panel, child))

# Функція, яка ховає або показує контент
func _on_section_toggled(button_pressed: bool, content_panel: Control, btn: Button) -> void:
	content_panel.visible = button_pressed
	# Опціонально: змінюємо текст кнопки (стрілочка вниз/вправо)
	if button_pressed:
		btn.text = btn.text.trim_suffix(" ▶").trim_suffix(" ▼") + " ▼"
	else:
		btn.text = btn.text.trim_suffix(" ▼").trim_suffix(" ▶") + " ▶"
