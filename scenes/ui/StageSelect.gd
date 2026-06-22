extends CanvasLayer

signal stage_confirmed(stage_id: String, stage_level: int)
signal back_requested

const UIStateColors = preload("res://scenes/ui/UIStateColors.gd")

var _stage_data_provider: Node = null
var _user_preferences_manager: Node = null
var _meta_progression_manager: Node = null
var _stages: Array[Dictionary] = []
var _selected_stage_id: String = ""
var _selected_stage_level: int = 1
var _preferred_stage_id: String = ""

var _cards_container: HBoxContainer = null
var _back_button: Button = null

# Level modal elements
var _modal_root: Control = null
var _modal_zone_label: Label = null
var _modal_level_label: Label = null
var _modal_power_label: Label = null
var _modal_enemy_label: Label = null
var _modal_loot_label: Label = null
var _modal_start_button: Button = null
var _modal_stage_id: String = ""
var _modal_level: int = 1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide()


func setup(stage_data_provider: Node, user_preferences_manager: Node = null, meta_progression_manager: Node = null) -> void:
	_stage_data_provider = stage_data_provider
	_user_preferences_manager = user_preferences_manager
	_meta_progression_manager = meta_progression_manager
	if _user_preferences_manager != null and _user_preferences_manager.has_method("get_last_stage_id"):
		set_preferred_stage_id(_user_preferences_manager.get_last_stage_id())
	_reload_stages()


func open() -> void:
	_reload_stages()
	_hide_modal()
	show()
	if _back_button != null:
		_back_button.grab_focus()


func close() -> void:
	_hide_modal()
	hide()


func get_selected_stage_id() -> String:
	return _selected_stage_id


func get_selected_stage_level() -> int:
	return _selected_stage_level


func set_preferred_stage_id(stage_id: String) -> void:
	_preferred_stage_id = stage_id


func is_modal_open() -> bool:
	return _modal_root != null and _modal_root.visible


func close_modal() -> void:
	_hide_modal()


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
	main.add_theme_constant_override("separation", 20)
	margin.add_child(main)

	var title := Label.new()
	title.text = "Select Stage"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	main.add_child(title)

	_cards_container = HBoxContainer.new()
	_cards_container.name = "CardsContainer"
	_cards_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cards_container.add_theme_constant_override("separation", 20)
	main.add_child(_cards_container)

	var buttons := HBoxContainer.new()
	buttons.name = "Buttons"
	buttons.add_theme_constant_override("separation", 12)
	main.add_child(buttons)

	_back_button = Button.new()
	_back_button.custom_minimum_size = Vector2(180, 52)
	_back_button.text = "Back"
	_back_button.pressed.connect(_on_back_pressed)
	buttons.add_child(_back_button)

	_build_modal(root)


func _build_modal(root: Control) -> void:
	_modal_root = Control.new()
	_modal_root.name = "ModalRoot"
	_modal_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_root.visible = false
	root.add_child(_modal_root)

	var dim := ColorRect.new()
	dim.name = "ModalDim"
	dim.color = Color(0.0, 0.0, 0.0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_root.add_child(center)

	var modal_panel := PanelContainer.new()
	modal_panel.name = "ModalPanel"
	modal_panel.custom_minimum_size = Vector2(480, 0)
	center.add_child(modal_panel)

	var modal_margin := MarginContainer.new()
	modal_margin.add_theme_constant_override("margin_left", 28)
	modal_margin.add_theme_constant_override("margin_top", 28)
	modal_margin.add_theme_constant_override("margin_right", 28)
	modal_margin.add_theme_constant_override("margin_bottom", 28)
	modal_panel.add_child(modal_margin)

	var modal_vbox := VBoxContainer.new()
	modal_vbox.add_theme_constant_override("separation", 16)
	modal_margin.add_child(modal_vbox)

	_modal_zone_label = Label.new()
	_modal_zone_label.name = "ModalZoneLabel"
	_modal_zone_label.add_theme_font_size_override("font_size", 22)
	_modal_zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_vbox.add_child(_modal_zone_label)

	modal_vbox.add_child(HSeparator.new())

	var level_row := HBoxContainer.new()
	level_row.add_theme_constant_override("separation", 8)
	level_row.alignment = BoxContainer.ALIGNMENT_CENTER
	modal_vbox.add_child(level_row)

	var lvl_title := Label.new()
	lvl_title.text = "Level:"
	lvl_title.add_theme_font_size_override("font_size", 18)
	level_row.add_child(lvl_title)

	var btn_prev := Button.new()
	btn_prev.text = "<"
	btn_prev.custom_minimum_size = Vector2(44, 44)
	btn_prev.pressed.connect(_modal_prev_level)
	level_row.add_child(btn_prev)

	_modal_level_label = Label.new()
	_modal_level_label.custom_minimum_size = Vector2(52, 0)
	_modal_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_modal_level_label.add_theme_font_size_override("font_size", 24)
	level_row.add_child(_modal_level_label)

	var btn_next := Button.new()
	btn_next.text = ">"
	btn_next.custom_minimum_size = Vector2(44, 44)
	btn_next.pressed.connect(_modal_next_level)
	level_row.add_child(btn_next)

	var preview_panel := PanelContainer.new()
	modal_vbox.add_child(preview_panel)

	var preview_margin := MarginContainer.new()
	preview_margin.add_theme_constant_override("margin_left", 16)
	preview_margin.add_theme_constant_override("margin_top", 14)
	preview_margin.add_theme_constant_override("margin_right", 16)
	preview_margin.add_theme_constant_override("margin_bottom", 14)
	preview_panel.add_child(preview_margin)

	var preview_vbox := VBoxContainer.new()
	preview_vbox.add_theme_constant_override("separation", 8)
	preview_margin.add_child(preview_vbox)

	_modal_power_label = Label.new()
	_modal_power_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_vbox.add_child(_modal_power_label)

	_modal_enemy_label = Label.new()
	_modal_enemy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_vbox.add_child(_modal_enemy_label)

	_modal_loot_label = Label.new()
	_modal_loot_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_vbox.add_child(_modal_loot_label)

	var modal_buttons := HBoxContainer.new()
	modal_buttons.add_theme_constant_override("separation", 12)
	modal_vbox.add_child(modal_buttons)

	var close_btn := Button.new()
	close_btn.text = "Back"
	close_btn.custom_minimum_size = Vector2(150, 50)
	close_btn.pressed.connect(_hide_modal)
	modal_buttons.add_child(close_btn)

	var btn_spacer := Control.new()
	btn_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_buttons.add_child(btn_spacer)

	_modal_start_button = Button.new()
	_modal_start_button.text = "Start Run"
	_modal_start_button.custom_minimum_size = Vector2(170, 50)
	_modal_start_button.pressed.connect(_on_modal_start_pressed)
	modal_buttons.add_child(_modal_start_button)


func _reload_stages() -> void:
	if _cards_container == null:
		return
	for child in _cards_container.get_children():
		child.queue_free()
	_stages.clear()

	if _stage_data_provider != null and _stage_data_provider.has_method("get_all_stages"):
		_stages = _stage_data_provider.get_all_stages()

	for stage in _stages:
		var card := _build_zone_card(stage)
		_cards_container.add_child(card)


func _build_zone_card(stage: Dictionary) -> Control:
	var stage_id := str(stage.get("id", ""))
	var is_locked := _is_zone_locked(stage_id)
	var bg_colors: Dictionary = stage.get("background_colors", {})
	var ground_color: Color = bg_colors.get("ground", Color(0.08, 0.10, 0.14, 1.0))
	var highest := _get_highest_cleared_level(stage_id)
	var next_level := _get_next_level(stage_id)

	var card_panel := PanelContainer.new()
	card_panel.name = "Card_%s" % stage_id
	card_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var card_margin := MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 14)
	card_margin.add_theme_constant_override("margin_top", 14)
	card_margin.add_theme_constant_override("margin_right", 14)
	card_margin.add_theme_constant_override("margin_bottom", 14)
	card_panel.add_child(card_margin)

	var card_vbox := VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 8)
	card_margin.add_child(card_vbox)

	var image_rect := ColorRect.new()
	image_rect.color = ground_color
	image_rect.custom_minimum_size = Vector2(0, 110)
	image_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if is_locked:
		image_rect.modulate = Color(0.45, 0.45, 0.45, 1.0)
	card_vbox.add_child(image_rect)

	var name_label := Label.new()
	name_label.text = str(stage.get("display_name", "Stage"))
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_vbox.add_child(name_label)

	var subtitle_label := Label.new()
	subtitle_label.text = str(stage.get("subtitle", ""))
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1.0))
	card_vbox.add_child(subtitle_label)

	var difficulty_label := Label.new()
	difficulty_label.text = "Difficulty: %s" % str(stage.get("difficulty_label", "Normal"))
	difficulty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	difficulty_label.add_theme_font_size_override("font_size", 13)
	card_vbox.add_child(difficulty_label)

	card_vbox.add_child(HSeparator.new())

	var status_label := Label.new()
	if is_locked:
		status_label.text = "LOCKED"
		status_label.add_theme_color_override("font_color", Color(0.85, 0.30, 0.30, 1.0))
	else:
		status_label.text = "UNLOCKED"
		status_label.add_theme_color_override("font_color", Color(0.30, 0.85, 0.40, 1.0))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 14)
	card_vbox.add_child(status_label)

	var level_info_label := Label.new()
	if is_locked:
		level_info_label.text = ""
	elif highest > 0:
		level_info_label.text = "Best Clear: Level %d\nNext: Level %d" % [highest, next_level]
	else:
		level_info_label.text = "No clears yet\nStart at Level 1"
	level_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_info_label.add_theme_font_size_override("font_size", 13)
	card_vbox.add_child(level_info_label)

	if is_locked:
		var lock_reason := _get_lock_reason(stage_id)
		if not lock_reason.is_empty():
			var lock_label := Label.new()
			lock_label.text = lock_reason
			lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lock_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lock_label.add_theme_color_override("font_color", Color(0.85, 0.65, 0.30, 1.0))
			lock_label.add_theme_font_size_override("font_size", 12)
			card_vbox.add_child(lock_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_vbox.add_child(spacer)

	var select_btn := Button.new()
	select_btn.text = "Select" if not is_locked else "Locked"
	select_btn.disabled = is_locked
	select_btn.custom_minimum_size = Vector2(0, 50)
	select_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not is_locked:
		select_btn.pressed.connect(_open_level_modal.bind(stage_id))
	card_vbox.add_child(select_btn)

	return card_panel


func _is_zone_locked(stage_id: String) -> bool:
	if _meta_progression_manager != null and _meta_progression_manager.has_method("is_stage_unlocked"):
		return not _meta_progression_manager.is_stage_unlocked(stage_id)
	for stage in _stages:
		if str(stage.get("id", "")) == stage_id:
			return not bool(stage.get("unlocked_by_default", true))
	return true


func _get_highest_cleared_level(stage_id: String) -> int:
	if _meta_progression_manager != null and _meta_progression_manager.has_method("get_highest_cleared_stage_level"):
		return _meta_progression_manager.get_highest_cleared_stage_level(stage_id)
	return 0


func _get_next_level(stage_id: String) -> int:
	if _meta_progression_manager != null and _meta_progression_manager.has_method("get_next_available_stage_level"):
		return _meta_progression_manager.get_next_available_stage_level(stage_id)
	return 1


func _get_lock_reason(stage_id: String) -> String:
	if _stage_data_provider != null and _stage_data_provider.has_method("get_stage_unlock_requirement"):
		var req: Dictionary = _stage_data_provider.get_stage_unlock_requirement(stage_id)
		if req.is_empty():
			return ""
		var req_stage_id := str(req.get("required_stage_id", ""))
		var req_level := int(req.get("required_level", 1))
		if req_stage_id.is_empty():
			return ""
		var req_name := _get_stage_display_name(req_stage_id)
		return "Clear %s Level %d to unlock" % [req_name, req_level]
	return "Locked"


func _get_stage_display_name(stage_id: String) -> String:
	for stage in _stages:
		if str(stage.get("id", "")) == stage_id:
			return str(stage.get("display_name", stage_id.capitalize()))
	return stage_id.capitalize()


func _open_level_modal(stage_id: String) -> void:
	_modal_stage_id = stage_id
	_modal_level = _get_next_level(stage_id)
	for stage in _stages:
		if str(stage.get("id", "")) == stage_id:
			if _modal_zone_label != null:
				_modal_zone_label.text = str(stage.get("display_name", stage_id))
			break
	_refresh_modal_preview()
	if _modal_root != null:
		_modal_root.visible = true
	if _modal_start_button != null:
		_modal_start_button.grab_focus()


func _hide_modal() -> void:
	if _modal_root != null:
		_modal_root.visible = false
	_modal_stage_id = ""


func _modal_prev_level() -> void:
	if _modal_level > 1:
		_modal_level -= 1
		_refresh_modal_preview()


func _modal_next_level() -> void:
	if _modal_level < _get_modal_max_level():
		_modal_level += 1
		_refresh_modal_preview()


func _get_modal_max_level() -> int:
	if _modal_stage_id.is_empty():
		return 5
	for stage in _stages:
		if str(stage.get("id", "")) == _modal_stage_id:
			var max_preview := int(stage.get("max_preview_level", 5))
			var highest := _get_highest_cleared_level(_modal_stage_id)
			return mini(maxi(highest + 1, 1), max_preview)
	return 5


func _refresh_modal_preview() -> void:
	if _modal_level_label == null:
		return
	_modal_level_label.text = str(_modal_level)

	var preview: Dictionary = {}
	if _stage_data_provider != null and _stage_data_provider.has_method("get_stage_level_preview"):
		preview = _stage_data_provider.get_stage_level_preview(_modal_stage_id, _modal_level)

	var power := int(preview.get("recommended_power", 100))
	var enemy := float(preview.get("enemy_strength", 1.0))
	var loot := float(preview.get("loot_value", 1.0))

	if _modal_power_label != null:
		_modal_power_label.text = "Recommended Power:  %d" % power
	if _modal_enemy_label != null:
		var enemy_pct := int(round((enemy - 1.0) * 100.0))
		_modal_enemy_label.text = "Enemy Strength:  %s" % ("Standard" if enemy_pct <= 0 else "+%d%% stronger" % enemy_pct)
	if _modal_loot_label != null:
		var loot_pct := int(round((loot - 1.0) * 100.0))
		_modal_loot_label.text = "Loot Value:  %s" % ("Standard" if loot_pct <= 0 else "+%d%% better" % loot_pct)


func _on_modal_start_pressed() -> void:
	if _modal_stage_id.is_empty():
		return
	_selected_stage_id = _modal_stage_id
	_selected_stage_level = _modal_level
	stage_confirmed.emit(_selected_stage_id, _selected_stage_level)


func _on_back_pressed() -> void:
	back_requested.emit()
