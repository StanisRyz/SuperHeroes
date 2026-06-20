extends CanvasLayer

signal start_requested
signal back_requested

const TRAINING_TITLES := {
	"meta_max_health": "Vitality",
	"meta_attack_damage": "Power",
	"meta_pickup_radius": "Awareness",
	"meta_move_speed": "Mobility",
	"meta_starting_currency_bonus": "Rewards",
}

var _hero: Dictionary = {}
var _stage: Dictionary = {}
var _meta_progression_manager: Node = null

var _hero_label: Label
var _abilities_label: Label
var _training_label: Label
var _stage_label: Label
var _objective_label: Label
var _boss_label: Label
var _start_button: Button
var _back_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide()


func setup(hero: Dictionary, stage: Dictionary, meta_progression_manager: Node = null) -> void:
	_hero = hero.duplicate(true)
	_stage = stage.duplicate(true)
	_meta_progression_manager = meta_progression_manager
	_refresh_content()


func open() -> void:
	_refresh_content()
	show()
	if _start_button != null:
		_start_button.grab_focus()


func close() -> void:
	hide()


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
	title.text = "Run Briefing"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	main.add_child(title)

	var panel := PanelContainer.new()
	panel.name = "BriefingPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.name = "BriefingScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var content_margin := MarginContainer.new()
	content_margin.name = "ContentMargin"
	content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_margin.add_theme_constant_override("margin_left", 18)
	content_margin.add_theme_constant_override("margin_top", 16)
	content_margin.add_theme_constant_override("margin_right", 18)
	content_margin.add_theme_constant_override("margin_bottom", 16)
	scroll.add_child(content_margin)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	content_margin.add_child(content)

	_hero_label = _create_section_label(content, "Hero")
	_abilities_label = _create_section_label(content, "Abilities")
	_training_label = _create_section_label(content, "Training")
	_stage_label = _create_section_label(content, "Stage")
	_objective_label = _create_section_label(content, "Objective")
	_boss_label = _create_section_label(content, "Final Boss")

	var buttons := HBoxContainer.new()
	buttons.name = "Buttons"
	buttons.add_theme_constant_override("separation", 12)
	main.add_child(buttons)

	_back_button = Button.new()
	_back_button.custom_minimum_size = Vector2(180, 52)
	_back_button.text = "Back"
	_back_button.pressed.connect(_on_back_pressed)
	buttons.add_child(_back_button)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(spacer)

	_start_button = Button.new()
	_start_button.custom_minimum_size = Vector2(220, 52)
	_start_button.text = "Start Run"
	_start_button.pressed.connect(_on_start_pressed)
	buttons.add_child(_start_button)


func _create_section_label(parent: Control, title: String) -> Label:
	var label := Label.new()
	label.name = "%sLabel" % title.replace(" ", "")
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text = "%s\n-" % title
	label.add_theme_font_size_override("font_size", 16)
	parent.add_child(label)
	return label


func _refresh_content() -> void:
	if _hero_label == null:
		return

	_hero_label.text = "Hero\n%s\n%s\n%s" % [
		str(_hero.get("display_name", "Hero")),
		str(_hero.get("subtitle", "")),
		str(_hero.get("playstyle", "")),
	]

	var ability_names: Dictionary = _hero.get("ability_names", {})
	_abilities_label.text = "Abilities\n%s" % "\n".join(_build_ability_lines(ability_names))

	var hero_id: String = str(_hero.get("id", ""))
	_training_label.text = "Training\n%s" % _build_training_summary(hero_id)

	_stage_label.text = "Stage\n%s\nDifficulty: %s" % [
		str(_stage.get("display_name", "Stage")),
		str(_stage.get("difficulty_label", "Normal")),
	]

	var _obj_type_raw := str(_stage.get("objective_type", "survival"))
	_objective_label.text = "Objective  [%s]\n%s" % [_format_objective_type(_obj_type_raw), str(_stage.get("stage_goal", _build_default_stage_goal(_stage)))]

	var boss_id: String = str(_stage.get("final_boss_id", ""))
	var boss_name: String = _format_boss_name(boss_id)
	_boss_label.text = "Final Boss\n%s\n%s" % [
		boss_name,
		str(_stage.get("boss_preview", "%s waits at the end of the run." % boss_name)),
	]


func _build_ability_lines(ability_names: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = []
	lines.append("1. %s" % _get_ability_display_name(ability_names, 1, "Ability 1"))
	lines.append("2. %s" % _get_ability_display_name(ability_names, 2, "Ability 2"))
	lines.append("3. %s" % _get_ability_display_name(ability_names, 3, "Ability 3"))
	return lines


func _get_ability_display_name(ability_names: Dictionary, slot: int, fallback: String) -> String:
	var raw = ability_names.get(slot, {})
	var data: Dictionary = {}
	if raw is Dictionary:
		data = raw
	return str(data.get("display_name", fallback))


func _build_training_summary(hero_id: String) -> String:
	if _meta_progression_manager == null or not _meta_progression_manager.has_method("get_training_levels_for_hero"):
		return "Training data unavailable."
	var levels: Dictionary = _meta_progression_manager.get_training_levels_for_hero(hero_id)
	var total: int = 0
	var strongest_id: String = ""
	var strongest_level: int = 0
	for upgrade_id in levels.keys():
		var level: int = int(levels[upgrade_id])
		total += level
		if level > strongest_level:
			strongest_level = level
			strongest_id = str(upgrade_id)
	if total <= 0:
		return "0 total levels\nNo purchased Training for this hero yet."
	var strongest_name: String = str(TRAINING_TITLES.get(strongest_id, strongest_id))
	return "%d total levels\nStrongest: %s %d" % [total, strongest_name, strongest_level]


func _format_objective_type(objective_type: String) -> String:
	match objective_type:
		"survival": return "Survival"
		"defense": return "Defense"
		"destroy_structures": return "Destroy Structures"
		_: return objective_type.capitalize()


func _build_default_stage_goal(stage: Dictionary) -> String:
	var settings: Dictionary = stage.get("run_settings", {})
	var target_seconds: float = float(settings.get("target_run_time", 600.0))
	var minutes: int = int(round(target_seconds / 60.0))
	return "Survive %d:00, then defeat the final boss." % minutes


func _format_boss_name(boss_id: String) -> String:
	match boss_id:
		"titan_guardian": return "Titan Guardian"
		"prism_overlord": return "Prism Overlord"
		"molten_colossus": return "Molten Colossus"
		_:
			if boss_id.is_empty():
				return "Unknown"
			return boss_id.capitalize()


func _on_start_pressed() -> void:
	start_requested.emit()


func _on_back_pressed() -> void:
	back_requested.emit()
