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
		button.set_meta("evolution_id", "")
	for index in mini(options.size(), _option_buttons.size()):
		var evolution := options[index]
		var button := _option_buttons[index]
		button.text = "%s\n%s" % [evolution.get("title", "Evolution"), evolution.get("description", "")]
		button.set_meta("evolution_id", evolution.get("id", ""))
		button.show()
	_message_label.text = "No evolution available yet." if options.is_empty() else "Choose one evolution for this run."
	_continue_button.visible = options.is_empty()
	show()


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
	panel.custom_minimum_size = Vector2(620, 360)
	panel.offset_left = -310
	panel.offset_top = -180
	panel.offset_right = 310
	panel.offset_bottom = 180
	root.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	var title := Label.new()
	title.text = "Choose Evolution"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)

	_message_label = Label.new()
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_message_label)

	for index in range(3):
		var button := Button.new()
		button.custom_minimum_size = Vector2(560, 68)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
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
