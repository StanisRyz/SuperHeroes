extends CanvasLayer

signal stage_confirmed(stage_id: String)
signal back_requested

const UIStateColors = preload("res://scenes/ui/UIStateColors.gd")

var _stage_data_provider: Node = null
var _user_preferences_manager: Node = null
var _stages: Array[Dictionary] = []
var _selected_stage_id: String = ""
var _preferred_stage_id: String = ""
var _stage_buttons: Dictionary = {}

var _cards_box: VBoxContainer
var _name_label: Label
var _subtitle_label: Label
var _last_selected_label: Label
var _description_label: Label
var _difficulty_label: Label
var _threat_label: Label
var _goal_label: Label
var _playstyle_label: Label
var _final_boss_label: Label
var _start_button: Button
var _back_button: Button
var _color_swatch: ColorRect
var _details_scroll: ScrollContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide()


func setup(stage_data_provider: Node, user_preferences_manager: Node = null) -> void:
	_stage_data_provider = stage_data_provider
	_user_preferences_manager = user_preferences_manager
	if _user_preferences_manager != null and _user_preferences_manager.has_method("get_last_stage_id"):
		set_preferred_stage_id(_user_preferences_manager.get_last_stage_id())
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


func set_preferred_stage_id(stage_id: String) -> void:
	_preferred_stage_id = stage_id


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

	var stage_list_panel := PanelContainer.new()
	stage_list_panel.name = "StageListPanel"
	stage_list_panel.custom_minimum_size = Vector2(380, 0)
	stage_list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(stage_list_panel)

	var stage_list_margin := MarginContainer.new()
	stage_list_margin.name = "StageListMargin"
	stage_list_margin.add_theme_constant_override("margin_left", 12)
	stage_list_margin.add_theme_constant_override("margin_top", 12)
	stage_list_margin.add_theme_constant_override("margin_right", 12)
	stage_list_margin.add_theme_constant_override("margin_bottom", 12)
	stage_list_panel.add_child(stage_list_margin)

	_cards_box = VBoxContainer.new()
	_cards_box.name = "StageList"
	_cards_box.add_theme_constant_override("separation", 12)
	stage_list_margin.add_child(_cards_box)

	var details_panel := PanelContainer.new()
	details_panel.name = "DetailsPanel"
	details_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(details_panel)

	_details_scroll = ScrollContainer.new()
	_details_scroll.name = "DetailsScroll"
	_details_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_details_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_details_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	details_panel.add_child(_details_scroll)

	var details_margin := MarginContainer.new()
	details_margin.name = "DetailsMargin"
	details_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details_margin.add_theme_constant_override("margin_left", 16)
	details_margin.add_theme_constant_override("margin_top", 16)
	details_margin.add_theme_constant_override("margin_right", 16)
	details_margin.add_theme_constant_override("margin_bottom", 16)
	_details_scroll.add_child(details_margin)

	var details := VBoxContainer.new()
	details.name = "Details"
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 12)
	details_margin.add_child(details)

	_color_swatch = ColorRect.new()
	_color_swatch.custom_minimum_size = Vector2(0, 18)
	details.add_child(_color_swatch)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 24)
	details.add_child(_name_label)

	_subtitle_label = Label.new()
	details.add_child(_subtitle_label)

	_last_selected_label = Label.new()
	_last_selected_label.text = "Last selected"
	_last_selected_label.visible = false
	details.add_child(_last_selected_label)

	_difficulty_label = Label.new()
	details.add_child(_difficulty_label)

	_description_label = Label.new()
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(_description_label)

	_threat_label = _create_detail_label()
	details.add_child(_threat_label)

	_goal_label = _create_detail_label()
	details.add_child(_goal_label)

	_playstyle_label = _create_detail_label()
	details.add_child(_playstyle_label)

	_final_boss_label = Label.new()
	_final_boss_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(_final_boss_label)

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
		var diff: String = str(stage.get("difficulty_label", "Normal"))
		var threat_line: String = str(stage.get("enemy_pressure", stage.get("subtitle", "")))
		var markers: Array[String] = []
		if not _preferred_stage_id.is_empty() and stage_id == _preferred_stage_id:
			markers.append("Last")
		if _is_stage_locked(stage):
			markers.append("Locked")
		var marker_text: String = ""
		if not markers.is_empty():
			marker_text = "  [%s]" % ", ".join(markers)
		button.custom_minimum_size = Vector2(320, 72)
		button.text = "%s%s\n%s - %s" % [stage.get("display_name", "Stage"), marker_text, diff, threat_line]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_select_stage.bind(stage_id))
		_cards_box.add_child(button)
		_stage_buttons[stage_id] = button

	_selected_stage_id = _get_initial_stage_id()

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
	if _last_selected_label != null:
		_last_selected_label.visible = not _preferred_stage_id.is_empty() and _selected_stage_id == _preferred_stage_id
	_difficulty_label.text = "Difficulty: %s" % stage.get("difficulty_label", "Normal")
	_description_label.text = str(stage.get("description", ""))
	_threat_label.text = "Threats\n%s\nPressure: %s" % [
		str(stage.get("threat_summary", "Stage pressure follows its selected event profile.")),
		str(stage.get("enemy_pressure", "Standard")),
	]
	_goal_label.text = "Run Objective\n%s" % str(stage.get("stage_goal", _build_default_stage_goal(stage)))
	_playstyle_label.text = "Recommended\n%s" % str(stage.get("recommended_playstyle", "Use the build that fits your selected hero."))

	var boss_id := str(stage.get("final_boss_id", ""))
	var boss_name: String = _format_boss_name(boss_id)
	_final_boss_label.text = "Final Boss\n%s\n%s" % [
		boss_name,
		str(stage.get("boss_preview", "%s waits at the end of the run." % boss_name)),
	]

	var bg_colors: Dictionary = stage.get("background_colors", {})
	var ground_color: Color = bg_colors.get("ground", Color(0.08, 0.10, 0.14, 1.0))
	_color_swatch.color = ground_color

	for sid in _stage_buttons:
		var btn := _stage_buttons[sid] as Button
		var is_selected: bool = sid == _selected_stage_id
		btn.disabled = is_selected
		btn.modulate = UIStateColors.positive_color() if is_selected else Color.WHITE


func _format_boss_name(boss_id: String) -> String:
	match boss_id:
		"titan_guardian": return "Titan Guardian"
		"prism_overlord": return "Prism Overlord"
		"molten_colossus": return "Molten Colossus"
		_:
			if boss_id.is_empty():
				return "Unknown"
			return boss_id.capitalize()


func _create_detail_label() -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _build_default_stage_goal(stage: Dictionary) -> String:
	var settings: Dictionary = stage.get("run_settings", {})
	var target_seconds: float = float(settings.get("target_run_time", 600.0))
	var minutes: int = int(round(target_seconds / 60.0))
	return "Survive %d:00, then defeat the final boss." % minutes


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


func _get_initial_stage_id() -> String:
	if _is_stage_playable_id(_preferred_stage_id):
		return _preferred_stage_id

	if _stage_data_provider != null and _stage_data_provider.has_method("get_default_stage"):
		var default_stage: Dictionary = _stage_data_provider.get_default_stage()
		var default_id := str(default_stage.get("id", ""))
		if _is_stage_playable_id(default_id):
			return default_id

	for stage: Dictionary in _stages:
		var stage_id := str(stage.get("id", ""))
		if _is_stage_playable_id(stage_id):
			return stage_id
	return ""


func _is_stage_playable_id(stage_id: String) -> bool:
	if stage_id.is_empty():
		return false
	for stage: Dictionary in _stages:
		if str(stage.get("id", "")) == stage_id:
			return not _is_stage_locked(stage)
	return false


func _is_stage_locked(stage: Dictionary) -> bool:
	if bool(stage.get("unlocked_by_default", true)):
		return false
	if _stage_data_provider != null and _stage_data_provider.has_method("is_stage_unlocked"):
		return not _stage_data_provider.is_stage_unlocked(str(stage.get("id", "")))
	return false


func _on_start_pressed() -> void:
	if _selected_stage_id.is_empty():
		return
	stage_confirmed.emit(_selected_stage_id)


func _on_back_pressed() -> void:
	back_requested.emit()
