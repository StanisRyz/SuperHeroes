extends CanvasLayer

signal evolution_chosen(evolution_id: String)

var _option_buttons: Array[Button] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	layer = 22
	_build_ui()
	hide()


func show_evolutions(options: Array) -> void:
	for button in _option_buttons:
		button.hide()
		button.set_meta("evolution_id", "")
	for index in mini(options.size(), _option_buttons.size()):
		var triple: Dictionary = options[index]
		var button := _option_buttons[index]
		button.text = _format_card(triple)
		button.set_meta("evolution_id", str(triple.get("evolution_id", "")))
		button.modulate = Color(1.0, 0.85, 0.3, 1.0)
		button.show()
	show()


func _format_card(triple: Dictionary) -> String:
	var title := str(triple.get("title", "Evolution"))
	var target_type := str(triple.get("target_type", "active"))
	var target_id := str(triple.get("target_id", triple.get("target_active_skill_id", "")))
	var type_label := "%s EVOLUTION" % target_type.to_upper()
	var target := target_id.replace("_", " ").to_upper()
	var description := str(triple.get("description", ""))
	var lines: Array = triple.get("required_lines", [])

	var line_parts: PackedStringArray = []
	for line_data: Dictionary in lines:
		var cat := str(line_data.get("category", "")).to_upper().left(3)
		var line_id := str(line_data.get("id", ""))
		var cur := int(line_data.get("current_level", 0))
		var max_lvl := int(line_data.get("max_level", 1))
		line_parts.append("[%s] %s  %d/%d" % [cat, line_id, cur, max_lvl])

	var lines_str := ""
	if not line_parts.is_empty():
		lines_str = "\n" + "  |  ".join(line_parts)

	return "%s  ->  %s\n%s\n%s%s" % [type_label, target, title, description, lines_str]


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.07, 0.86)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(overlay)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(700, 460)
	panel.offset_left = -350
	panel.offset_top = -230
	panel.offset_right = 350
	panel.offset_bottom = 230
	root.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var title_label := Label.new()
	title_label.text = "⚡ OVERDRIVE READY"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 26)
	title_label.modulate = Color(1.0, 0.88, 0.18, 1.0)
	box.add_child(title_label)

	var subtitle := Label.new()
	subtitle.text = "Choose an evolution to permanently transform one part of your build this run."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(subtitle)

	for _index in range(3):
		var button := Button.new()
		button.custom_minimum_size = Vector2(640, 84)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_on_option_pressed.bind(button))
		box.add_child(button)
		_option_buttons.append(button)


func _on_option_pressed(button: Button) -> void:
	var evolution_id := str(button.get_meta("evolution_id", ""))
	if evolution_id.is_empty():
		return
	hide()
	evolution_chosen.emit(evolution_id)
