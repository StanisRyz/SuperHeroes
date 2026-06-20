extends CanvasLayer

signal back_requested
signal buy_requested(hero_id: String, upgrade_id: String)

const UIStateColors = preload("res://scenes/ui/UIStateColors.gd")

var _meta_manager: Node
var _hero_data_provider: Node
var _selected_hero_id: String = ""
var _heroes: Array[Dictionary] = []
var _title_label: Label
var _hero_selector: HBoxContainer
var _currency_label: Label
var _goals_label: Label
var _back_button: Button
var _list_vbox: VBoxContainer

var _rows: Array[Dictionary] = []
var _hero_buttons: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 18
	_build_ui()
	hide()


func setup(meta_progression_manager: Node, hero_data_provider: Node = null) -> void:
	_meta_manager = meta_progression_manager
	_hero_data_provider = hero_data_provider
	_reload_heroes()
	if _meta_manager == null:
		return
	if _meta_manager.has_signal("currency_changed") and not _meta_manager.currency_changed.is_connected(_on_currency_changed):
		_meta_manager.currency_changed.connect(_on_currency_changed)
	if _meta_manager.has_signal("meta_upgrade_changed") and not _meta_manager.meta_upgrade_changed.is_connected(_on_meta_upgrade_changed):
		_meta_manager.meta_upgrade_changed.connect(_on_meta_upgrade_changed)
	if _meta_manager.has_method("ensure_training_data_for_all_heroes"):
		_meta_manager.ensure_training_data_for_all_heroes(_get_hero_ids())


func open(hero_id: String = "") -> void:
	set_selected_hero(hero_id)
	refresh()
	show()
	if _back_button != null:
		_back_button.grab_focus()


func close() -> void:
	hide()


func refresh() -> void:
	if _meta_manager == null:
		return
	if _selected_hero_id.is_empty():
		set_selected_hero("")
	if _title_label != null:
		_title_label.text = "Training: %s" % _get_selected_hero_display_name()
	if _currency_label != null:
		_currency_label.text = "Currency: %d" % _meta_manager.get_currency()
	_update_goals_label()
	_update_hero_buttons()
	_rebuild_rows_if_needed()
	_update_rows()


func set_selected_hero(hero_id: String) -> void:
	_reload_heroes()
	var resolved := _resolve_hero_id(hero_id)
	_selected_hero_id = resolved
	if _meta_manager != null and _meta_manager.has_method("ensure_training_data_for_hero"):
		_meta_manager.ensure_training_data_for_hero(_selected_hero_id)
	if visible:
		refresh()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.045, 0.06, 0.075, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 56)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_right", 56)
	margin.add_theme_constant_override("margin_bottom", 36)
	add_child(margin)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 14)
	margin.add_child(main_vbox)

	_title_label = Label.new()
	_title_label.text = "Training"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 28)
	main_vbox.add_child(_title_label)

	_currency_label = Label.new()
	_currency_label.text = "Currency: 0"
	_currency_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_currency_label.add_theme_font_size_override("font_size", 16)
	main_vbox.add_child(_currency_label)

	_hero_selector = HBoxContainer.new()
	_hero_selector.add_theme_constant_override("separation", 8)
	_hero_selector.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(_hero_selector)

	_goals_label = Label.new()
	_goals_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_goals_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_goals_label.add_theme_font_size_override("font_size", 12)
	_goals_label.modulate = Color(0.82, 0.86, 0.92, 1.0)
	main_vbox.add_child(_goals_label)

	main_vbox.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll)

	_list_vbox = VBoxContainer.new()
	_list_vbox.add_theme_constant_override("separation", 8)
	_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list_vbox)

	main_vbox.add_child(HSeparator.new())

	_back_button = Button.new()
	_back_button.text = "Back"
	_back_button.custom_minimum_size = Vector2(180, 48)
	_back_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_back_button.pressed.connect(_on_back_pressed)
	main_vbox.add_child(_back_button)


func _rebuild_rows_if_needed() -> void:
	if _meta_manager == null or _list_vbox == null:
		return
	var defs: Array[Dictionary] = _meta_manager.get_meta_upgrade_definitions()
	if _rows.size() == defs.size():
		return

	for child in _list_vbox.get_children():
		child.queue_free()
	_rows.clear()

	for def in defs:
		var upgrade_id := str(def.get("id", ""))
		var row := _build_row(upgrade_id, def)
		_list_vbox.add_child(row)


func _build_row(upgrade_id: String, def: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)
	hbox.add_child(info)

	var title_lbl := Label.new()
	title_lbl.text = str(def.get("title", ""))
	title_lbl.add_theme_font_size_override("font_size", 14)
	info.add_child(title_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = str(def.get("description", ""))
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.modulate = Color(0.8, 0.8, 0.8, 1.0)
	info.add_child(desc_lbl)

	var level_lbl := Label.new()
	level_lbl.add_theme_font_size_override("font_size", 11)
	info.add_child(level_lbl)

	var buy_btn := Button.new()
	buy_btn.custom_minimum_size = Vector2(110, 44)
	buy_btn.pressed.connect(_on_buy_pressed.bind(upgrade_id))
	hbox.add_child(buy_btn)

	var row_data := {
		"id": upgrade_id,
		"max_level": int(def.get("max_level", 1)),
		"level_lbl": level_lbl,
		"buy_btn": buy_btn,
		"panel": panel,
	}
	_rows.append(row_data)
	return panel


func _update_rows() -> void:
	if _meta_manager == null:
		return
	for row in _rows:
		var upgrade_id := str(row.get("id", ""))
		var max_level := int(row.get("max_level", 1))
		var level: int = _meta_manager.get_training_level(_selected_hero_id, upgrade_id) if _meta_manager.has_method("get_training_level") else _meta_manager.get_meta_upgrade_level(upgrade_id)
		var cost: int = _meta_manager.get_training_upgrade_cost(_selected_hero_id, upgrade_id) if _meta_manager.has_method("get_training_upgrade_cost") else _meta_manager.get_meta_upgrade_cost(upgrade_id)
		var can_buy: bool = _meta_manager.can_purchase_training_upgrade(_selected_hero_id, upgrade_id) if _meta_manager.has_method("can_purchase_training_upgrade") else _meta_manager.can_buy_meta_upgrade(upgrade_id)

		var level_lbl := row.get("level_lbl") as Label
		if level_lbl != null:
			level_lbl.text = "Level %d / %d" % [level, max_level]

		var buy_btn := row.get("buy_btn") as Button
		if buy_btn != null:
			if level >= max_level:
				buy_btn.text = "MAX"
				buy_btn.disabled = true
				buy_btn.modulate = UIStateColors.muted_color()
			elif can_buy:
				buy_btn.text = "Buy  %d" % cost
				buy_btn.disabled = false
				buy_btn.modulate = UIStateColors.positive_color()
			else:
				buy_btn.text = "Buy  %d" % cost
				buy_btn.disabled = true
				buy_btn.modulate = UIStateColors.muted_color()


func _update_goals_label() -> void:
	if _goals_label == null:
		return
	if _meta_manager == null or not _meta_manager.has_method("get_goal_progress"):
		_goals_label.text = ""
		return
	var goals: Array = _meta_manager.get_goal_progress()
	var completed := 0
	var next_lines: PackedStringArray = []
	for goal in goals:
		if bool(goal.get("completed", false)):
			completed += 1
		elif next_lines.size() < 3:
			next_lines.append("%s %d/%d" % [
				str(goal.get("title", goal.get("id", ""))),
				int(goal.get("progress_current", 0)),
				int(goal.get("progress_target", 1)),
			])
	var text := "Goals: %d / %d complete" % [completed, goals.size()]
	if not next_lines.is_empty():
		text += "   Next: %s" % " | ".join(next_lines)
	_goals_label.text = text


func _on_buy_pressed(upgrade_id: String) -> void:
	if _selected_hero_id.is_empty():
		push_warning("MetaUpgradeShop: cannot buy training upgrade without selected hero.")
		return
	buy_requested.emit(_selected_hero_id, upgrade_id)


func _on_back_pressed() -> void:
	back_requested.emit()


func _on_currency_changed(_amount: int) -> void:
	if visible:
		refresh()


func _on_meta_upgrade_changed(upgrade_id: String, _level: int) -> void:
	if visible:
		refresh()
		_flash_row(upgrade_id)


func _reload_heroes() -> void:
	_heroes.clear()
	if _hero_data_provider != null and _hero_data_provider.has_method("get_all_heroes"):
		_heroes = _hero_data_provider.get_all_heroes()
	if _heroes.is_empty():
		_heroes = [
			{"id": "guardian", "display_name": "Guardian"},
			{"id": "blaster", "display_name": "Blaster"},
			{"id": "vanguard", "display_name": "Vanguard"},
		]
	_rebuild_hero_selector()


func _rebuild_hero_selector() -> void:
	if _hero_selector == null:
		return
	for child in _hero_selector.get_children():
		child.queue_free()
	_hero_buttons.clear()
	for hero in _heroes:
		var hero_id := str(hero.get("id", ""))
		if hero_id.is_empty():
			continue
		var button := Button.new()
		button.text = str(hero.get("display_name", hero_id.capitalize()))
		button.custom_minimum_size = Vector2(150, 42)
		button.pressed.connect(_on_hero_button_pressed.bind(hero_id))
		_hero_selector.add_child(button)
		_hero_buttons[hero_id] = button
	_update_hero_buttons()


func _update_hero_buttons() -> void:
	for hero_id in _hero_buttons:
		var button := _hero_buttons[hero_id] as Button
		if button == null:
			continue
		var selected: bool = hero_id == _selected_hero_id
		button.disabled = selected
		button.modulate = UIStateColors.positive_color() if selected else Color.WHITE


func _on_hero_button_pressed(hero_id: String) -> void:
	set_selected_hero(hero_id)


func _resolve_hero_id(hero_id: String) -> String:
	if _has_hero(hero_id):
		return hero_id
	if _hero_data_provider != null and _hero_data_provider.has_method("get_default_hero"):
		var default_hero: Dictionary = _hero_data_provider.get_default_hero()
		var default_id := str(default_hero.get("id", ""))
		if _has_hero(default_id):
			return default_id
	return str(_heroes[0].get("id", "guardian")) if not _heroes.is_empty() else "guardian"


func _has_hero(hero_id: String) -> bool:
	if hero_id.is_empty():
		return false
	for hero in _heroes:
		if str(hero.get("id", "")) == hero_id:
			return true
	return false


func _get_selected_hero_display_name() -> String:
	for hero in _heroes:
		if str(hero.get("id", "")) == _selected_hero_id:
			return str(hero.get("display_name", _selected_hero_id.capitalize()))
	return _selected_hero_id.capitalize()


func _get_hero_ids() -> Array[String]:
	var ids: Array[String] = []
	for hero in _heroes:
		var hero_id := str(hero.get("id", ""))
		if not hero_id.is_empty():
			ids.append(hero_id)
	return ids


func _flash_row(upgrade_id: String) -> void:
	for row in _rows:
		if str(row.get("id", "")) != upgrade_id:
			continue
		var panel := row.get("panel") as CanvasItem
		if panel == null or not is_instance_valid(panel):
			return
		var tween := panel.create_tween()
		tween.tween_property(panel, "modulate", Color(0.6, 1.0, 0.6, 1.0), 0.0)
		tween.tween_property(panel, "modulate", Color.WHITE, 0.35)
		return
