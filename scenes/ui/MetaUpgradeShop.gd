extends CanvasLayer

signal back_requested
signal buy_requested(hero_id: String, upgrade_id: String)
signal equipment_buy_requested(hero_id: String, equipment_id: String)

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

# Equipment panel references
var _equip_hero_name_label: Label
var _equip_hero_subtitle_label: Label
var _equip_hero_swatch: ColorRect
var _equip_hero_status_label: Label
var _equipment_slot_rows: Dictionary = {}


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
	if _meta_manager.has_signal("equipment_upgrade_changed") and not _meta_manager.equipment_upgrade_changed.is_connected(_on_equipment_upgrade_changed):
		_meta_manager.equipment_upgrade_changed.connect(_on_equipment_upgrade_changed)
	if _meta_manager.has_method("ensure_training_data_for_all_heroes"):
		_meta_manager.ensure_training_data_for_all_heroes(_get_hero_ids())
	if _meta_manager.has_method("ensure_equipment_data_for_all_heroes"):
		_meta_manager.ensure_equipment_data_for_all_heroes(_get_hero_ids())


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
		_title_label.text = "Training"
	if _currency_label != null:
		_currency_label.text = "Currency: %d" % _meta_manager.get_currency()
	_update_goals_label()
	_update_hero_buttons()
	_rebuild_rows_if_needed()
	_update_rows()
	_refresh_equipment_panel()


func set_selected_hero(hero_id: String) -> void:
	_reload_heroes()
	var resolved := _resolve_hero_id(hero_id)
	_selected_hero_id = resolved
	if _meta_manager != null and _meta_manager.has_method("ensure_training_data_for_hero"):
		_meta_manager.ensure_training_data_for_hero(_selected_hero_id)
	if _meta_manager != null and _meta_manager.has_method("ensure_equipment_data_for_hero"):
		_meta_manager.ensure_equipment_data_for_hero(_selected_hero_id)
	if visible:
		refresh()


# ─── UI skeleton ──────────────────────────────────────────────────────────────

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.045, 0.06, 0.075, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(main_vbox)

	# ── header ────────────────────────────────────────────────────────────────
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

	# ── two-panel content area ────────────────────────────────────────────────
	var content_hbox := HBoxContainer.new()
	content_hbox.add_theme_constant_override("separation", 16)
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content_hbox)

	var equip_panel := _build_equipment_panel()
	equip_panel.custom_minimum_size = Vector2(340, 0)
	equip_panel.size_flags_horizontal = Control.SIZE_FILL
	content_hbox.add_child(equip_panel)

	var vsep := VSeparator.new()
	content_hbox.add_child(vsep)

	var training_panel := _build_training_panel()
	training_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_hbox.add_child(training_panel)

	# ── footer ────────────────────────────────────────────────────────────────
	main_vbox.add_child(HSeparator.new())

	_back_button = Button.new()
	_back_button.text = "Back"
	_back_button.custom_minimum_size = Vector2(180, 48)
	_back_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_back_button.pressed.connect(_on_back_pressed)
	main_vbox.add_child(_back_button)


func _build_training_panel() -> Control:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	var section_title := Label.new()
	section_title.text = "Training Upgrades"
	section_title.add_theme_font_size_override("font_size", 16)
	section_title.modulate = Color(0.9, 0.9, 0.7, 1.0)
	vbox.add_child(section_title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_list_vbox = VBoxContainer.new()
	_list_vbox.add_theme_constant_override("separation", 8)
	_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list_vbox)

	return vbox


func _build_equipment_panel() -> Control:
	var outer_vbox := VBoxContainer.new()
	outer_vbox.add_theme_constant_override("separation", 8)

	var section_title := Label.new()
	section_title.text = "Equipment"
	section_title.add_theme_font_size_override("font_size", 16)
	section_title.modulate = Color(0.7, 0.85, 1.0, 1.0)
	outer_vbox.add_child(section_title)

	# ── hero preview ──────────────────────────────────────────────────────────
	var hero_panel := PanelContainer.new()
	hero_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_vbox.add_child(hero_panel)

	var hero_vbox := VBoxContainer.new()
	hero_vbox.add_theme_constant_override("separation", 4)
	hero_panel.add_child(hero_vbox)

	_equip_hero_swatch = ColorRect.new()
	_equip_hero_swatch.custom_minimum_size = Vector2(0, 6)
	_equip_hero_swatch.color = Color(0.5, 0.5, 0.5, 1.0)
	hero_vbox.add_child(_equip_hero_swatch)

	_equip_hero_name_label = Label.new()
	_equip_hero_name_label.text = "—"
	_equip_hero_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_equip_hero_name_label.add_theme_font_size_override("font_size", 15)
	hero_vbox.add_child(_equip_hero_name_label)

	_equip_hero_subtitle_label = Label.new()
	_equip_hero_subtitle_label.text = ""
	_equip_hero_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_equip_hero_subtitle_label.add_theme_font_size_override("font_size", 11)
	_equip_hero_subtitle_label.modulate = Color(0.75, 0.82, 0.92, 1.0)
	hero_vbox.add_child(_equip_hero_subtitle_label)

	_equip_hero_status_label = Label.new()
	_equip_hero_status_label.text = ""
	_equip_hero_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_equip_hero_status_label.add_theme_font_size_override("font_size", 10)
	_equip_hero_status_label.modulate = Color(0.6, 0.9, 0.6, 1.0)
	hero_vbox.add_child(_equip_hero_status_label)

	# ── slot grid ─────────────────────────────────────────────────────────────
	# Layout:
	#   [Core]          [Gauntlets]
	#   [Suit]   HERO   [Boots]
	#   [Emblem]        [Artifact]
	var slot_hbox := HBoxContainer.new()
	slot_hbox.add_theme_constant_override("separation", 8)
	slot_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_vbox.add_child(slot_hbox)

	var left_col := VBoxContainer.new()
	left_col.add_theme_constant_override("separation", 6)
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_hbox.add_child(left_col)
	left_col.add_child(_build_equipment_slot("core", "Core"))
	left_col.add_child(_build_equipment_slot("suit", "Suit"))
	left_col.add_child(_build_equipment_slot("emblem", "Emblem"))

	var center_spacer := Control.new()
	center_spacer.custom_minimum_size = Vector2(32, 0)
	center_spacer.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slot_hbox.add_child(center_spacer)

	var right_col := VBoxContainer.new()
	right_col.add_theme_constant_override("separation", 6)
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_hbox.add_child(right_col)
	right_col.add_child(_build_equipment_slot("gauntlets", "Gauntlets"))
	right_col.add_child(_build_equipment_slot("boots", "Boots"))
	right_col.add_child(_build_equipment_slot("artifact", "Artifact"))

	var note := Label.new()
	note.text = "Fixed hero gear. Uses shared currency. No inventory or swapping."
	note.add_theme_font_size_override("font_size", 10)
	note.modulate = Color(0.55, 0.6, 0.65, 1.0)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer_vbox.add_child(note)

	return outer_vbox


func _build_equipment_slot(slot_id: String, slot_name: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 1)
	panel.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = slot_name
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	var item_lbl := Label.new()
	item_lbl.text = "Equipment"
	item_lbl.add_theme_font_size_override("font_size", 10)
	item_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(item_lbl)

	var level_lbl := Label.new()
	level_lbl.text = "Level 0 / 0"
	level_lbl.add_theme_font_size_override("font_size", 10)
	level_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_lbl.modulate = Color(0.7, 0.7, 0.7, 1.0)
	vbox.add_child(level_lbl)

	var hint_lbl := Label.new()
	hint_lbl.text = ""
	hint_lbl.add_theme_font_size_override("font_size", 9)
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_lbl.modulate = Color(0.5, 0.55, 0.6, 1.0)
	vbox.add_child(hint_lbl)

	var buy_btn := Button.new()
	buy_btn.text = "Upgrade"
	buy_btn.disabled = true
	buy_btn.custom_minimum_size = Vector2(0, 28)
	buy_btn.add_theme_font_size_override("font_size", 9)
	buy_btn.pressed.connect(_on_equipment_buy_pressed.bind(slot_id))
	vbox.add_child(buy_btn)

	_equipment_slot_rows[slot_id] = {
		"slot_name": name_lbl,
		"display_name": item_lbl,
		"level": level_lbl,
		"bonus": hint_lbl,
		"button": buy_btn,
		"panel": panel,
	}
	return panel


func _refresh_equipment_panel() -> void:
	var hero := _get_selected_hero_data()
	if _equip_hero_name_label == null:
		return
	var display_name := str(hero.get("display_name", _selected_hero_id.capitalize()))
	var subtitle := str(hero.get("subtitle", str(hero.get("playstyle", ""))))
	var color: Color = hero.get("color", Color(0.5, 0.5, 0.5, 1.0))
	var unlocked: bool = hero.get("unlocked_by_default", true)

	_equip_hero_name_label.text = display_name
	_equip_hero_subtitle_label.text = subtitle
	if _equip_hero_swatch != null:
		_equip_hero_swatch.color = color
	if _equip_hero_status_label != null:
		_equip_hero_status_label.text = "Owned" if unlocked else "Locked"
		_equip_hero_status_label.modulate = Color(0.6, 0.9, 0.6, 1.0) if unlocked else Color(0.8, 0.5, 0.3, 1.0)
	_update_equipment_slots()


func _get_selected_hero_data() -> Dictionary:
	for hero in _heroes:
		if str(hero.get("id", "")) == _selected_hero_id:
			return hero
	if _hero_data_provider != null and _hero_data_provider.has_method("get_hero"):
		var d: Dictionary = _hero_data_provider.get_hero(_selected_hero_id)
		if not d.is_empty():
			return d
	return {}


func _update_equipment_slots() -> void:
	var defs_by_slot := _get_equipment_definitions_by_slot()
	for slot_id in _equipment_slot_rows:
		var row: Dictionary = _equipment_slot_rows.get(slot_id, {})
		var def: Dictionary = defs_by_slot.get(slot_id, {})
		var slot_name_lbl := row.get("slot_name") as Label
		var display_name_lbl := row.get("display_name") as Label
		var level_lbl := row.get("level") as Label
		var bonus_lbl := row.get("bonus") as Label
		var button := row.get("button") as Button

		var slot_name := _format_slot_name(str(slot_id))
		var display_name := "Equipment"
		var level_text := "Level 0 / 0"
		var bonus_text := "No equipment data"
		var equipment_id := ""
		var level := 0
		var max_level := 0
		var cost := 0
		var can_buy := false
		if not def.is_empty():
			slot_name = str(def.get("slot_name", slot_name))
			display_name = str(def.get("display_name", display_name))
			equipment_id = str(def.get("equipment_id", ""))
			level = _get_equipment_level(equipment_id)
			max_level = int(def.get("max_level", 0))
			cost = _get_equipment_cost(equipment_id)
			can_buy = _can_buy_equipment(equipment_id)
			level_text = "Level %d / %d" % [level, max_level]
			bonus_text = "%s\nCurrent: %s\nNext: %s" % [
				_format_equipment_bonus(def),
				_format_equipment_total_bonus(def, level),
				_format_equipment_total_bonus(def, level + 1) if level < max_level else "MAX",
			]

		if slot_name_lbl != null:
			slot_name_lbl.text = slot_name
		if display_name_lbl != null:
			display_name_lbl.text = display_name
		if level_lbl != null:
			level_lbl.text = level_text
		if bonus_lbl != null:
			bonus_lbl.text = bonus_text
		if button != null:
			if def.is_empty():
				button.text = "Unavailable"
				button.disabled = true
				button.modulate = UIStateColors.muted_color()
			elif level >= max_level:
				button.text = "MAX"
				button.disabled = true
				button.modulate = UIStateColors.muted_color()
			elif can_buy:
				button.text = "Upgrade %d" % cost
				button.disabled = false
				button.modulate = UIStateColors.positive_color()
			else:
				button.text = "Need %d" % cost
				button.disabled = true
				button.modulate = UIStateColors.muted_color()


func _get_equipment_definitions_by_slot() -> Dictionary:
	var result := {}
	if _meta_manager == null or not _meta_manager.has_method("get_equipment_definitions"):
		return result
	var defs: Array = _meta_manager.get_equipment_definitions(_selected_hero_id)
	for def in defs:
		if not def is Dictionary:
			continue
		var slot_id := str(def.get("slot_id", ""))
		if not slot_id.is_empty():
			result[slot_id] = def
	return result


func _get_equipment_level(equipment_id: String) -> int:
	if equipment_id.is_empty():
		return 0
	if _meta_manager != null and _meta_manager.has_method("get_equipment_level"):
		return int(_meta_manager.get_equipment_level(_selected_hero_id, equipment_id))
	return 0


func _get_equipment_cost(equipment_id: String) -> int:
	if equipment_id.is_empty():
		return 0
	if _meta_manager != null and _meta_manager.has_method("get_equipment_upgrade_cost"):
		return int(_meta_manager.get_equipment_upgrade_cost(_selected_hero_id, equipment_id))
	return 0


func _can_buy_equipment(equipment_id: String) -> bool:
	if equipment_id.is_empty():
		return false
	if _meta_manager != null and _meta_manager.has_method("can_purchase_equipment_upgrade"):
		return bool(_meta_manager.can_purchase_equipment_upgrade(_selected_hero_id, equipment_id))
	return false


func _format_equipment_bonus(def: Dictionary) -> String:
	var bonus_type := str(def.get("stat_bonus_type", ""))
	var value = def.get("stat_bonus_per_level", 0)
	var label := _format_bonus_type(bonus_type)
	if value is float and abs(float(value)) < 1.0:
		return "+%d%% %s / level" % [int(round(float(value) * 100.0)), label]
	return "+%s %s / level" % [str(value), label]


func _format_equipment_total_bonus(def: Dictionary, level: int) -> String:
	var bonus_type := str(def.get("stat_bonus_type", ""))
	var value := float(def.get("stat_bonus_per_level", 0.0)) * float(level)
	var label := _format_bonus_type(bonus_type)
	if abs(value) < 1.0 and not is_zero_approx(value):
		return "+%d%% %s" % [int(round(value * 100.0)), label]
	return "+%s %s" % [_format_number(value), label]


func _format_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundi(value)))
	return "%.2f" % value


func _format_bonus_type(bonus_type: String) -> String:
	match bonus_type:
		"ability_damage":
			return "ability damage"
		"max_health":
			return "max HP"
		"xp_gain":
			return "XP gain"
		"attack_damage":
			return "attack damage"
		"move_speed":
			return "move speed"
		"shield_capacity":
			return "shield capacity"
		"ability_cooldown":
			return "ability cooldown"
		"mark_damage":
			return "marked damage"
		"support_damage":
			return "support damage"
		"rage_gain":
			return "Rage gain"
		"impact_damage":
			return "impact damage"
		"knockback_resist":
			return "knockback resist"
		"low_health_damage":
			return "low-health damage"
		_:
			return bonus_type.replace("_", " ")


func _format_slot_name(slot_id: String) -> String:
	match slot_id:
		"core":
			return "Core"
		"suit":
			return "Suit"
		"emblem":
			return "Emblem"
		"gauntlets":
			return "Gauntlets"
		"boots":
			return "Boots"
		"artifact":
			return "Artifact"
		_:
			return slot_id.capitalize()


# ─── Training rows ────────────────────────────────────────────────────────────

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


# ─── Signal handlers ──────────────────────────────────────────────────────────

func _on_buy_pressed(upgrade_id: String) -> void:
	if _selected_hero_id.is_empty():
		push_warning("MetaUpgradeShop: cannot buy training upgrade without selected hero.")
		return
	buy_requested.emit(_selected_hero_id, upgrade_id)


func _on_equipment_buy_pressed(slot_id: String) -> void:
	if _selected_hero_id.is_empty():
		push_warning("MetaUpgradeShop: cannot buy equipment without selected hero.")
		return
	var defs_by_slot := _get_equipment_definitions_by_slot()
	var def: Dictionary = defs_by_slot.get(slot_id, {})
	var equipment_id := str(def.get("equipment_id", ""))
	if equipment_id.is_empty():
		push_warning("MetaUpgradeShop: cannot buy missing equipment slot %s." % slot_id)
		return
	equipment_buy_requested.emit(_selected_hero_id, equipment_id)


func _on_back_pressed() -> void:
	back_requested.emit()


func _on_currency_changed(_amount: int) -> void:
	if visible:
		refresh()


func _on_meta_upgrade_changed(upgrade_id: String, _level: int) -> void:
	if visible:
		refresh()
		_flash_row(upgrade_id)


func _on_equipment_upgrade_changed(hero_id: String, equipment_id: String, _level: int) -> void:
	if visible:
		refresh()
		if hero_id == _selected_hero_id:
			_flash_equipment_slot(equipment_id)


# ─── Hero selector ────────────────────────────────────────────────────────────

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


# ─── Helpers ──────────────────────────────────────────────────────────────────

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


func _flash_equipment_slot(equipment_id: String) -> void:
	var defs_by_slot := _get_equipment_definitions_by_slot()
	for slot_id in defs_by_slot:
		var def: Dictionary = defs_by_slot.get(slot_id, {})
		if str(def.get("equipment_id", "")) != equipment_id:
			continue
		var row: Dictionary = _equipment_slot_rows.get(slot_id, {})
		var panel := row.get("panel") as CanvasItem
		if panel == null or not is_instance_valid(panel):
			return
		var tween := panel.create_tween()
		tween.tween_property(panel, "modulate", Color(0.6, 1.0, 0.6, 1.0), 0.0)
		tween.tween_property(panel, "modulate", Color.WHITE, 0.35)
		return
