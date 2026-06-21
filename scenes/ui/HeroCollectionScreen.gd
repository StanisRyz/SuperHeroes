extends CanvasLayer

signal back_requested
signal hero_selected(hero_id: String)

var _meta_manager: Node = null
var _hero_data_provider: Node = null
var _selected_hero_id: String = ""
var _heroes: Array[Dictionary] = []

var _summary_label: Label
var _card_list: VBoxContainer
var _card_buttons: Dictionary = {}
var _detail_swatch: ColorRect
var _detail_name: Label
var _detail_status: Label
var _detail_subtitle: Label
var _detail_playstyle: Label
var _detail_passive: Label
var _detail_weapon: Label
var _detail_abilities: Label
var _detail_mastery: Label
var _detail_equipment: Label
var _detail_description: Label
var _back_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 17
	_build_ui()
	hide()


func setup(meta_progression_manager: Node, hero_data_provider: Node) -> void:
	_meta_manager = meta_progression_manager
	_hero_data_provider = hero_data_provider


func open() -> void:
	_refresh()
	show()
	if _back_button != null:
		_back_button.grab_focus()


func close() -> void:
	hide()


# ─── UI skeleton ──────────────────────────────────────────────────────────────

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var bg := ColorRect.new()
	bg.color = Color(0.045, 0.06, 0.075, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	var outer := MarginContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 48)
	outer.add_theme_constant_override("margin_top", 32)
	outer.add_theme_constant_override("margin_right", 48)
	outer.add_theme_constant_override("margin_bottom", 28)
	root.add_child(outer)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	outer.add_child(vbox)

	# ── top row ────────────────────────────────────────────────────────────────
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)
	vbox.add_child(top_row)

	var title := Label.new()
	title.text = "Collection"
	title.add_theme_font_size_override("font_size", 28)
	top_row.add_child(title)

	var top_spacer := Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(top_spacer)

	_summary_label = Label.new()
	_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_summary_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	top_row.add_child(_summary_label)

	# ── content row ────────────────────────────────────────────────────────────
	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 16)
	vbox.add_child(content)

	_build_card_panel(content)
	_build_detail_panel(content)

	# ── back button ────────────────────────────────────────────────────────────
	_back_button = Button.new()
	_back_button.text = "Back"
	_back_button.custom_minimum_size = Vector2(180, 52)
	_back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back_button.pressed.connect(_on_back_pressed)
	vbox.add_child(_back_button)


func _build_card_panel(parent: Control) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(330, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var inner := MarginContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("margin_left", 10)
	inner.add_theme_constant_override("margin_top", 10)
	inner.add_theme_constant_override("margin_right", 10)
	inner.add_theme_constant_override("margin_bottom", 10)
	scroll.add_child(inner)

	_card_list = VBoxContainer.new()
	_card_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_card_list.add_theme_constant_override("separation", 8)
	inner.add_child(_card_list)


func _build_detail_panel(parent: Control) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var inner := MarginContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("margin_left", 18)
	inner.add_theme_constant_override("margin_top", 14)
	inner.add_theme_constant_override("margin_right", 18)
	inner.add_theme_constant_override("margin_bottom", 14)
	scroll.add_child(inner)

	var dv := VBoxContainer.new()
	dv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dv.add_theme_constant_override("separation", 10)
	inner.add_child(dv)

	_detail_swatch = ColorRect.new()
	_detail_swatch.custom_minimum_size = Vector2(0, 12)
	dv.add_child(_detail_swatch)

	_detail_name = Label.new()
	_detail_name.add_theme_font_size_override("font_size", 22)
	dv.add_child(_detail_name)

	_detail_status = Label.new()
	_detail_status.add_theme_font_size_override("font_size", 13)
	dv.add_child(_detail_status)

	_detail_subtitle = Label.new()
	_detail_subtitle.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1.0))
	dv.add_child(_detail_subtitle)

	_detail_playstyle = Label.new()
	dv.add_child(_detail_playstyle)

	_detail_passive = Label.new()
	_detail_passive.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dv.add_child(_detail_passive)

	_detail_weapon = Label.new()
	dv.add_child(_detail_weapon)

	_detail_abilities = Label.new()
	_detail_abilities.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dv.add_child(_detail_abilities)

	_detail_mastery = Label.new()
	_detail_mastery.add_theme_color_override("font_color", Color(0.7, 0.8, 0.7, 1.0))
	dv.add_child(_detail_mastery)

	_detail_equipment = Label.new()
	_detail_equipment.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9, 1.0))
	dv.add_child(_detail_equipment)

	_detail_description = Label.new()
	_detail_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_description.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65, 1.0))
	dv.add_child(_detail_description)


# ─── Refresh ──────────────────────────────────────────────────────────────────

func _refresh() -> void:
	_heroes = []
	if _hero_data_provider != null and _hero_data_provider.has_method("get_all_heroes"):
		_heroes = _hero_data_provider.get_all_heroes()

	_rebuild_card_list()
	_update_summary_label()

	var initial_id := _pick_initial_hero_id()
	if not initial_id.is_empty():
		_select_hero(initial_id)
	else:
		_clear_detail_panel()


func _rebuild_card_list() -> void:
	for child in _card_list.get_children():
		child.queue_free()
	_card_buttons.clear()

	for hero in _heroes:
		var hero_id := str(hero.get("id", ""))
		var is_owned := _check_owned(hero)
		var card := _build_hero_card(hero, is_owned)
		_card_list.add_child(card)
		_card_buttons[hero_id] = card

	for i in range(3):
		var placeholder := _build_locked_placeholder_card(i + 1)
		_card_list.add_child(placeholder)


func _build_hero_card(hero: Dictionary, is_owned: bool) -> Button:
	var hero_id := str(hero.get("id", ""))
	var display_name := str(hero.get("display_name", "Hero"))
	var playstyle := str(hero.get("playstyle", ""))
	var passive_name: String = ""
	var kit: Dictionary = hero.get("ability_kit", {})
	if kit is Dictionary:
		passive_name = str(kit.get("passive_name", ""))
	var status_text := "OWNED" if is_owned else "LOCKED"

	var card_text := "%s\n%s\nPassive: %s  |  %s" % [display_name, playstyle, passive_name, status_text]

	var btn := Button.new()
	btn.text = card_text
	btn.custom_minimum_size = Vector2(0, 80)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.clip_text = false
	if not is_owned:
		btn.modulate = Color(0.55, 0.55, 0.55, 1.0)
	btn.pressed.connect(_select_hero.bind(hero_id))
	return btn


func _build_locked_placeholder_card(_index: int) -> Button:
	var btn := Button.new()
	btn.text = "??? Locked Hero\nFuture hero  |  LOCKED"
	btn.custom_minimum_size = Vector2(0, 80)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.modulate = Color(0.4, 0.4, 0.45, 1.0)
	btn.disabled = true
	return btn


# ─── Selection ────────────────────────────────────────────────────────────────

func _select_hero(hero_id: String) -> void:
	var hero := _get_hero(hero_id)
	if hero.is_empty():
		return
	_selected_hero_id = hero_id
	_refresh_card_highlights()
	var is_owned := _check_owned(hero)
	_update_detail_panel(hero, is_owned)
	hero_selected.emit(hero_id)


func _refresh_card_highlights() -> void:
	for id in _card_buttons:
		var btn: Button = _card_buttons[id]
		if btn == null or not is_instance_valid(btn):
			continue
		var hero := _get_hero(str(id))
		var is_owned := _check_owned(hero)
		if str(id) == _selected_hero_id:
			btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
		else:
			btn.modulate = Color(0.55, 0.55, 0.55, 1.0) if not is_owned else Color(0.82, 0.82, 0.82, 1.0)


func _update_detail_panel(hero: Dictionary, is_owned: bool) -> void:
	if _detail_name == null:
		return

	var hero_id := str(hero.get("id", ""))
	var display_name := str(hero.get("display_name", "Hero"))
	var subtitle := str(hero.get("subtitle", ""))
	var playstyle := str(hero.get("playstyle", ""))
	var description := str(hero.get("description", ""))
	var hero_color: Color = hero.get("color", Color(0.6, 0.6, 0.6, 1.0))

	var kit: Dictionary = hero.get("ability_kit", {})
	var passive_name := str(kit.get("passive_name", "")) if kit is Dictionary else ""
	var passive_desc := str(kit.get("passive_description", "")) if kit is Dictionary else ""

	var primary_weapon: Dictionary = hero.get("primary_weapon", {})
	var weapon_name := str(primary_weapon.get("display_name", "")) if primary_weapon is Dictionary else ""

	var ability_names: Dictionary = hero.get("ability_names", {})
	var ability_lines: Array[String] = []
	for slot in [1, 2, 3]:
		var slot_data: Dictionary = ability_names.get(slot, {}) if ability_names is Dictionary else {}
		var aname := str(slot_data.get("display_name", "Ability %d" % slot))
		ability_lines.append("Slot %d: %s" % [slot, aname])

	_detail_swatch.color = hero_color
	_detail_name.text = display_name
	_detail_status.text = "OWNED" if is_owned else "LOCKED"
	_detail_status.add_theme_color_override("font_color",
		Color(0.4, 0.85, 0.5, 1.0) if is_owned else Color(0.7, 0.4, 0.4, 1.0))
	_detail_subtitle.text = subtitle
	_detail_playstyle.text = "Playstyle: %s" % playstyle
	_detail_passive.text = "Passive: %s\n%s" % [passive_name, passive_desc]
	_detail_weapon.text = "Weapon: %s" % weapon_name
	_detail_abilities.text = "Abilities\n%s" % "\n".join(ability_lines)
	_detail_mastery.text = _build_mastery_text(hero_id)
	_detail_equipment.text = _build_equipment_text(hero_id)
	_detail_description.text = description


func _clear_detail_panel() -> void:
	if _detail_name == null:
		return
	_detail_swatch.color = Color(0.2, 0.2, 0.2, 1.0)
	_detail_name.text = "Select a hero"
	_detail_status.text = ""
	_detail_subtitle.text = ""
	_detail_playstyle.text = ""
	_detail_passive.text = ""
	_detail_weapon.text = ""
	_detail_abilities.text = ""
	_detail_mastery.text = ""
	_detail_equipment.text = ""
	_detail_description.text = ""


# ─── Helpers ──────────────────────────────────────────────────────────────────

func _check_owned(hero: Dictionary) -> bool:
	if hero.is_empty():
		return false
	var hero_id := str(hero.get("id", ""))
	if _meta_manager != null and _meta_manager.has_method("is_hero_unlocked"):
		return _meta_manager.is_hero_unlocked(hero_id)
	return bool(hero.get("unlocked_by_default", false))


func _get_hero(hero_id: String) -> Dictionary:
	for h in _heroes:
		if str(h.get("id", "")) == hero_id:
			return h
	return {}


func _pick_initial_hero_id() -> String:
	for hero in _heroes:
		if _check_owned(hero):
			return str(hero.get("id", ""))
	if not _heroes.is_empty():
		return str(_heroes[0].get("id", ""))
	return ""


func _build_mastery_text(hero_id: String) -> String:
	if _meta_manager == null or not _meta_manager.has_method("get_hero_mastery_summary"):
		return ""
	var mastery_all: Dictionary = _meta_manager.get_hero_mastery_summary()
	if not mastery_all.has(hero_id):
		return ""
	var entry: Dictionary = mastery_all.get(hero_id, {})
	if not entry is Dictionary:
		return ""
	var level := int(entry.get("highest_mastery_level", 1))
	var runs := int(entry.get("runs_played", 0))
	var wins := int(entry.get("victories", 0))
	return "Mastery Lv.%d  |  Runs: %d  |  Victories: %d" % [level, runs, wins]


func _build_equipment_text(hero_id: String) -> String:
	if _meta_manager == null or not _meta_manager.has_method("get_equipment_summary_for_hero"):
		return ""
	var summary: Dictionary = _meta_manager.get_equipment_summary_for_hero(hero_id)
	var upgraded := int(summary.get("upgraded_count", 0))
	var count := int(summary.get("equipment_count", 0))
	var total_levels := int(summary.get("total_levels", 0))
	var max_total := int(summary.get("max_total_levels", 0))
	var highest := int(summary.get("highest_level", 0))
	return "Equipment: %d / %d upgraded  |  Levels: %d / %d  |  Highest: %d" % [upgraded, count, total_levels, max_total, highest]


func _update_summary_label() -> void:
	if _summary_label == null:
		return
	var owned_count := 0
	for hero in _heroes:
		if _check_owned(hero):
			owned_count += 1
	var total := _heroes.size()
	var currency_text := ""
	if _meta_manager != null and _meta_manager.has_method("get_currency"):
		currency_text = "  |  Currency: %d" % _meta_manager.get_currency()
	_summary_label.text = "Owned: %d / %d%s" % [owned_count, total, currency_text]


# ─── Signals ──────────────────────────────────────────────────────────────────

func _on_back_pressed() -> void:
	back_requested.emit()
