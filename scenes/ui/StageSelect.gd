extends CanvasLayer

signal stage_confirmed(stage_id: String)
signal back_requested

var _stage_data_provider: Node = null
var _stages: Array[Dictionary] = []
var _selected_stage_id: String = ""
var _stage_buttons: Dictionary = {}

var _cards_box: VBoxContainer
var _name_label: Label
var _subtitle_label: Label
var _description_label: Label
var _difficulty_label: Label
var _final_boss_label: Label
var _start_button: Button
var _back_button: Button
var _color_swatch: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide()


func setup(stage_data_provider: Node) -> void:
	_stage_data_provider = stage_data_provider
	_reload_stages()


func open() -> void:
	_reload_stages()
	show()
	if _start_button != null:
		_start_button.grab_focus()


func close() -> void:
	hide()


func get_selected_stage_id() -> String:
	return _selected_stage_id


func _build_ui() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var background := ColorRect.new()
	background.name = "Background"
	background.color = Color(0.045, 0.06, 0.075, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 56)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_right", 56)
	margin.add_theme_constant_override("margin_bottom", 36)
	root.add_child(margin)

	var main := VBoxContainer.new()
	main.name = "Main"
	main.add_theme_constant_override("separation", 18)
	margin.add_child(main)

	var title := Label.new()
	title.text = "Select Stage"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	main.add_child(title)

	var content := HBoxContainer.new()
	content.name = "Content"
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 20)
	main.add_child(content)

	_cards_box = VBoxContainer.new()
	_cards_box.name = "StageList"
	_cards_box.custom_minimum_size = Vector2(360, 0)
	_cards_box.add_theme_constant_override("separation", 12)
	content.add_child(_cards_box)

	var details_panel := PanelContainer.new()
	details_panel.name = "DetailsPanel"
	details_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(details_panel)

	var details := VBoxContainer.new()
	details.name = "Details"
	details.add_theme_constant_override("separation", 12)
	details_panel.add_child(details)

	_color_swatch = ColorRect.new()
	_color_swatch.custom_minimum_size = Vector2(0, 18)
	details.add_child(_color_swatch)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 24)
	details.add_child(_name_label)

	_subtitle_label = Label.new()
	details.add_child(_subtitle_label)

	_difficulty_label = Label.new()
	details.add_child(_difficulty_label)

	_description_label = Label.new()
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(_description_label)

	_final_boss_label = Label.new()
	details.add_child(_final_boss_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details.add_child(spacer)

	var buttons := HBoxContainer.new()
	buttons.name = "Buttons"
	buttons.add_theme_constant_override("separation", 12)
	main.add_child(buttons)

	_back_button = Button.new()
	_back_button.custom_minimum_size = Vector2(180, 52)
	_back_button.text = "Back"
	_back_button.pressed.connect(_on_back_pressed)
	buttons.add_child(_back_button)

	var button_spacer := Control.new()
	button_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(button_spacer)

	_start_button = Button.new()
	_start_button.custom_minimum_size = Vector2(220, 52)
	_start_button.text = "Start Run"
	_start_button.pressed.connect(_on_start_pressed)
	buttons.add_child(_start_button)


func _reload_stages() -> void:
	if _cards_box == null:
		return

	for child in _cards_box.get_children():
		child.queue_free()
	_stage_buttons.clear()
	_stages.clear()

	if _stage_data_provider != null and _stage_data_provider.has_method("get_all_stages"):
		_stages = _stage_data_provider.get_all_stages()

	for stage in _stages:
		var button := Button.new()
		var stage_id := str(stage.get("id", ""))
		var diff := str(stage.get("difficulty_label", "Normal"))
		button.custom_minimum_size = Vector2(320, 72)
		button.text = "%s\n[%s]" % [stage.get("display_name", "Stage"), diff]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_select_stage.bind(stage_id))
		_cards_box.add_child(button)
		_stage_buttons[stage_id] = button

	if _selected_stage_id.is_empty() or not _has_stage(_selected_stage_id):
		if _stage_data_provider != null and _stage_data_provider.has_method("get_default_stage"):
			_selected_stage_id = str(_stage_data_provider.get_default_stage().get("id", ""))
		elif not _stages.is_empty():
			_selected_stage_id = str(_stages[0].get("id", ""))

	_select_stage(_selected_stage_id)


func _select_stage(stage_id: String) -> void:
	if not _has_stage(stage_id):
		return
	_selected_stage_id = stage_id
	_refresh_details()


func _refresh_details() -> void:
	var stage := _get_selected_stage()
	if stage.is_empty():
		return

	_name_label.text = str(stage.get("display_name", "Stage"))
	_subtitle_label.text = str(stage.get("subtitle", ""))
	_difficulty_label.text = "Difficulty: %s" % stage.get("difficulty_label", "Normal")
	_description_label.text = str(stage.get("description", ""))

	var boss_id := str(stage.get("final_boss_id", ""))
	_final_boss_label.text = "Final Boss: %s" % _format_boss_name(boss_id)

	var bg_colors: Dictionary = stage.get("background_colors", {})
	var ground_color: Color = bg_colors.get("ground", Color(0.08, 0.10, 0.14, 1.0))
	_color_swatch.color = ground_color

	for sid in _stage_buttons:
		var btn := _stage_buttons[sid] as Button
		btn.disabled = sid == _selected_stage_id


func _format_boss_name(boss_id: String) -> String:
	match boss_id:
		"titan_guardian": return "Titan Guardian"
		"prism_overlord": return "Prism Overlord"
		"molten_colossus": return "Molten Colossus"
		_:
			if boss_id.is_empty():
				return "Unknown"
			return boss_id.capitalize()


func _get_selected_stage() -> Dictionary:
	for stage in _stages:
		if str(stage.get("id", "")) == _selected_stage_id:
			return stage
	return {}


func _has_stage(stage_id: String) -> bool:
	for stage in _stages:
		if str(stage.get("id", "")) == stage_id:
			return true
	return false


func _on_start_pressed() -> void:
	if _selected_stage_id.is_empty():
		return
	stage_confirmed.emit(_selected_stage_id)


func _on_back_pressed() -> void:
	back_requested.emit()
