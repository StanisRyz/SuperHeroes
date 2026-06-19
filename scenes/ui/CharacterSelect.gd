extends CanvasLayer

signal hero_confirmed(hero_id: String)
signal back_requested

const UIStateColors = preload("res://scenes/ui/UIStateColors.gd")

var hero_data_provider: Node
var meta_progression_manager: Node = null
var user_preferences_manager: Node = null
var _heroes: Array[Dictionary] = []
var _selected_hero_id: String = ""
var _preferred_hero_id: String = ""
var _hero_buttons: Dictionary = {}

var _cards_box: VBoxContainer
var _name_label: Label
var _subtitle_label: Label
var _description_label: Label
var _last_selected_label: Label
var _playstyle_label: Label
var _stats_label: Label
var _start_button: Button
var _back_button: Button
var _color_swatch: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide()


func setup(new_hero_data_provider: Node, new_meta_progression_manager: Node = null, new_user_preferences_manager: Node = null) -> void:
	hero_data_provider = new_hero_data_provider
	meta_progression_manager = new_meta_progression_manager
	user_preferences_manager = new_user_preferences_manager
	if user_preferences_manager != null and user_preferences_manager.has_method("get_last_hero_id"):
		set_preferred_hero_id(user_preferences_manager.get_last_hero_id())
	_reload_heroes()


func open() -> void:
	_reload_heroes()
	show()
	if _start_button != null:
		_start_button.grab_focus()


func close() -> void:
	hide()


func get_selected_hero_id() -> String:
	return _selected_hero_id


func set_preferred_hero_id(hero_id: String) -> void:
	_preferred_hero_id = hero_id


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
	title.text = "Select Hero"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	main.add_child(title)

	var content := HBoxContainer.new()
	content.name = "Content"
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 20)
	main.add_child(content)

	_cards_box = VBoxContainer.new()
	_cards_box.name = "HeroList"
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

	_last_selected_label = Label.new()
	_last_selected_label.text = "Last selected"
	_last_selected_label.visible = false
	details.add_child(_last_selected_label)

	_playstyle_label = Label.new()
	details.add_child(_playstyle_label)

	_description_label = Label.new()
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(_description_label)

	_stats_label = Label.new()
	_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(_stats_label)

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


func _reload_heroes() -> void:
	if _cards_box == null:
		return

	for child in _cards_box.get_children():
		child.queue_free()
	_hero_buttons.clear()
	_heroes.clear()

	if hero_data_provider != null and hero_data_provider.has_method("get_all_heroes"):
		_heroes = hero_data_provider.get_all_heroes()

	for hero in _heroes:
		var button := Button.new()
		var hero_id := str(hero.get("id", ""))
		var locked := _is_hero_locked(hero)
		button.custom_minimum_size = Vector2(320, 72)
		if locked:
			var unlock_cost := int(hero.get("unlock_cost", 0))
			button.text = "%s\n[LOCKED — %d currency]" % [hero.get("display_name", "Hero"), unlock_cost]
			button.modulate = UIStateColors.muted_color()
		else:
			button.text = "%s\n%s" % [hero.get("display_name", "Hero"), hero.get("playstyle", "")]
			button.modulate = Color.WHITE
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_select_hero.bind(hero_id))
		_cards_box.add_child(button)
		_hero_buttons[hero_id] = button

	_selected_hero_id = _get_initial_hero_id()

	_select_hero(_selected_hero_id)


func _select_hero(hero_id: String) -> void:
	if not _has_hero(hero_id):
		return
	_selected_hero_id = hero_id
	_refresh_details()


func _refresh_details() -> void:
	var hero := _get_selected_hero()
	if hero.is_empty():
		return

	_name_label.text = str(hero.get("display_name", "Hero"))
	_subtitle_label.text = str(hero.get("subtitle", ""))
	if _last_selected_label != null:
		_last_selected_label.visible = not _preferred_hero_id.is_empty() and _selected_hero_id == _preferred_hero_id
	_playstyle_label.text = "Playstyle: %s" % hero.get("playstyle", "")
	_description_label.text = str(hero.get("description", ""))
	_color_swatch.color = hero.get("color", Color.WHITE)

	var stats: Dictionary = hero.get("stats", {})
	var lines: PackedStringArray = []
	lines.append("HP: %s" % stats.get("max_health", "-"))
	lines.append("Speed: %s" % stats.get("speed", "-"))
	if int(stats.get("attack_damage_bonus", 0)) != 0:
		lines.append("Attack damage: +%d" % int(stats.get("attack_damage_bonus", 0)))
	if int(stats.get("projectile_count_bonus", 0)) != 0:
		lines.append("Projectiles: +%d" % int(stats.get("projectile_count_bonus", 0)))
	if stats.has("attack_interval_multiplier"):
		lines.append("Attack interval: x%.2f" % float(stats["attack_interval_multiplier"]))
	if stats.has("ability_cooldown_multiplier"):
		lines.append("Ability cooldowns: x%.2f" % float(stats["ability_cooldown_multiplier"]))
	if int(stats.get("nova_damage_bonus", 0)) != 0:
		lines.append("Nova damage: +%d" % int(stats.get("nova_damage_bonus", 0)))
	if int(stats.get("slam_damage_bonus", 0)) != 0:
		lines.append("Slam damage: +%d" % int(stats.get("slam_damage_bonus", 0)))
	_stats_label.text = "\n".join(lines)

	var selected_locked := _is_hero_locked(hero)
	if _start_button != null:
		_start_button.disabled = selected_locked
		_start_button.text = "Start Run" if not selected_locked else "Locked"

	for hero_id in _hero_buttons:
		var button := _hero_buttons[hero_id] as Button
		var is_selected: bool = hero_id == _selected_hero_id
		button.disabled = is_selected
		if is_selected:
			button.modulate = UIStateColors.positive_color()
		else:
			var locked := false
			for h: Dictionary in _heroes:
				if str(h.get("id", "")) == hero_id:
					locked = _is_hero_locked(h)
					break
			button.modulate = UIStateColors.muted_color() if locked else Color.WHITE


func _get_selected_hero() -> Dictionary:
	for hero in _heroes:
		if str(hero.get("id", "")) == _selected_hero_id:
			return hero
	return {}


func _has_hero(hero_id: String) -> bool:
	for hero in _heroes:
		if str(hero.get("id", "")) == hero_id:
			return true
	return false


func _get_initial_hero_id() -> String:
	if _is_hero_playable_id(_preferred_hero_id):
		return _preferred_hero_id

	if hero_data_provider != null and hero_data_provider.has_method("get_default_hero"):
		var default_hero: Dictionary = hero_data_provider.get_default_hero()
		var default_id := str(default_hero.get("id", ""))
		if _is_hero_playable_id(default_id):
			return default_id

	for hero: Dictionary in _heroes:
		var hero_id := str(hero.get("id", ""))
		if _is_hero_playable_id(hero_id):
			return hero_id
	return ""


func _is_hero_playable_id(hero_id: String) -> bool:
	if hero_id.is_empty():
		return false
	for hero: Dictionary in _heroes:
		if str(hero.get("id", "")) == hero_id:
			return not _is_hero_locked(hero)
	return false


func _is_hero_locked(hero: Dictionary) -> bool:
	if bool(hero.get("unlocked_by_default", true)):
		return false
	if meta_progression_manager == null or not meta_progression_manager.has_method("is_hero_unlocked"):
		return false
	return not meta_progression_manager.is_hero_unlocked(str(hero.get("id", "")))


func _on_start_pressed() -> void:
	if _selected_hero_id.is_empty():
		return
	var hero := _get_selected_hero()
	if not hero.is_empty() and _is_hero_locked(hero):
		return
	hero_confirmed.emit(_selected_hero_id)


func _on_back_pressed() -> void:
	back_requested.emit()
