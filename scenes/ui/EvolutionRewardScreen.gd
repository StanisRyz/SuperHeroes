extends CanvasLayer

signal evolution_selected(evolution_id: String)
signal closed_without_selection

var _option_buttons: Array[Button] = []
var _message_label: Label
var _continue_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_build_ui()
	hide()


func show_options(options: Array[Dictionary]) -> void:
	for button in _option_buttons:
		button.hide()
		if button.has_focus():
			button.release_focus()
		button.set_meta("evolution_id", "")
		button.modulate = Color.WHITE
	for index in mini(options.size(), _option_buttons.size()):
		var evolution: Dictionary = options[index]
		var button := _option_buttons[index]
		button.text = _format_evolution_text(evolution)
		button.set_meta("evolution_id", evolution.get("id", ""))
		button.modulate = Color(1.0, 0.9, 0.5, 1.0)
		button.show()
	if options.is_empty():
		_message_label.text = "No evolution available at this time.\nKeep building your archetype and try again."
	else:
		_message_label.text = "Choose one evolution for this run. All listed prerequisites are complete."
		if not _option_buttons.is_empty() and _option_buttons[0].visible:
			_option_buttons[0].grab_focus()
	_continue_button.visible = options.is_empty()
	show()


func _format_evolution_text(evolution: Dictionary) -> String:
	var title := str(evolution.get("title", "Evolution"))
	var description := str(evolution.get("description", ""))
	var effect_summary := str(evolution.get("effect_summary", ""))
	var target_ability := str(evolution.get("target_ability_id", ""))
	if target_ability.is_empty():
		target_ability = str(evolution.get("target_passive_id", ""))
	target_ability = target_ability.replace("_", " ").capitalize()
	var prerequisite_lines := _format_prerequisites(evolution.get("prerequisites", []))
	var lines: PackedStringArray = ["EVOLUTION", title]
	if not target_ability.is_empty():
		lines.append("Target: %s" % target_ability)
	if not description.is_empty():
		lines.append(description)
	if not effect_summary.is_empty():
		lines.append("Effect: %s" % effect_summary)
	if not prerequisite_lines.is_empty():
		lines.append("Requires:\n%s" % prerequisite_lines)
	return "\n".join(lines)


func _format_prerequisites(prerequisites: Array) -> String:
	var lines: PackedStringArray = []
	for prerequisite: Dictionary in prerequisites:
		lines.append("- %s: %d/%d" % [str(prerequisite.get("title", prerequisite.get("upgrade_id", "Upgrade"))), int(prerequisite.get("current_level", 0)), int(prerequisite.get("required_level", 0))])
	return "\n".join(lines)


func hide_screen() -> void:
	hide()


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.72)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(760, 650)
	panel.offset_left = -380
	panel.offset_top = -325
	panel.offset_right = 380
	panel.offset_bottom = 325
	root.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var title := Label.new()
	title.text = "Choose Evolution"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	box.add_child(title)

	_message_label = Label.new()
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_message_label)

	for index in range(3):
		var button := Button.new()
		button.custom_minimum_size = Vector2(700, 150)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_text = false
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_on_option_pressed.bind(button))
		box.add_child(button)
		_option_buttons.append(button)

	_continue_button = Button.new()
	_continue_button.custom_minimum_size = Vector2(240, 52)
	_continue_button.text = "Continue"
	_continue_button.pressed.connect(_on_continue_pressed)
	box.add_child(_continue_button)


func _on_option_pressed(button: Button) -> void:
	var evolution_id := str(button.get_meta("evolution_id", ""))
	if evolution_id.is_empty():
		return
	evolution_selected.emit(evolution_id)


func _on_continue_pressed() -> void:
	closed_without_selection.emit()
