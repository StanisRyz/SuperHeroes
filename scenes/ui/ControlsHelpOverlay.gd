extends CanvasLayer

signal closed

const ControlsHelpContent = preload("res://scenes/ui/ControlsHelpContent.gd")
const UIStateColors = preload("res://scenes/ui/UIStateColors.gd")

var _close_button: Button


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide()


func open() -> void:
	show()
	if _close_button != null:
		_close_button.grab_focus()


func close() -> void:
	if not visible:
		return
	hide()
	closed.emit()


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func is_open() -> bool:
	return visible


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause") or event.is_action_pressed("help_toggle"):
			close()
			get_viewport().set_input_as_handled()
			return


func _build_ui() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var dimmer := ColorRect.new()
	dimmer.name = "Dimmer"
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.68)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dimmer)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -360.0
	panel.offset_top = -260.0
	panel.offset_right = 360.0
	panel.offset_bottom = 260.0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(panel)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var title := Label.new()
	title.name = "TitleLabel"
	title.text = "Help / Controls"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.custom_minimum_size = Vector2(640.0, 360.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)

	var sections: Array = ControlsHelpContent.get_sections()
	for i: int in sections.size():
		if i > 0:
			content.add_child(HSeparator.new())
		_add_section(content, str(sections[i].get("title", "")), sections[i].get("lines", []))

	_close_button = Button.new()
	_close_button.name = "CloseButton"
	_close_button.custom_minimum_size = Vector2(220.0, 44.0)
	_close_button.text = "Close"
	_close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	layout.add_child(_close_button)
	_close_button.pressed.connect(_on_close_button_pressed)


func _add_section(parent: VBoxContainer, title_text: String, lines: Array) -> void:
	var title := Label.new()
	title.text = title_text.to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.modulate = UIStateColors.warning_color()
	title.add_theme_font_size_override("font_size", 14)
	parent.add_child(title)

	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.text = _format_lines(lines)
	parent.add_child(body)


func _format_lines(lines: Array) -> String:
	var formatted: Array[String] = []
	for line in lines:
		formatted.append("- %s" % str(line))
	return "\n".join(formatted)


func _on_close_button_pressed() -> void:
	close()
