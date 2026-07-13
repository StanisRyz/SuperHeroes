extends CanvasLayer

signal restart_requested
signal quit_to_menu_requested

const UIFormat = preload("res://scenes/ui/UIFormat.gd")
const UIStateColors = preload("res://scenes/ui/UIStateColors.gd")
const EquipmentFormat = preload("res://scenes/equipment/EquipmentFormat.gd")

var audio_manager: Node

@onready var title_label: Label = get_node_or_null("Root/Panel/VBoxContainer/Title")
@onready var time_label: Label = get_node_or_null("Root/Panel/VBoxContainer/TimeLabel")
@onready var kills_label: Label = get_node_or_null("Root/Panel/VBoxContainer/KillsLabel")
@onready var elite_kills_label: Label = get_node_or_null("Root/Panel/VBoxContainer/EliteKillsLabel")
@onready var miniboss_kills_label: Label = get_node_or_null("Root/Panel/VBoxContainer/MinibossKillsLabel")
@onready var level_label: Label = get_node_or_null("Root/Panel/VBoxContainer/LevelLabel")
@onready var hero_label: Label = get_node_or_null("Root/Panel/VBoxContainer/HeroLabel")
@onready var build_label: Label = get_node_or_null("Root/Panel/VBoxContainer/BuildLabel")
@onready var evolutions_label: Label = get_node_or_null("Root/Panel/VBoxContainer/EvolutionsLabel")
@onready var upgrades_label: Label = get_node_or_null("Root/Panel/VBoxContainer/UpgradesLabel")
@onready var restart_button: Button = get_node_or_null("Root/Panel/VBoxContainer/RestartButton")
@onready var menu_button: Button = get_node_or_null("Root/Panel/VBoxContainer/MenuButton")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	hide()

	if restart_button == null:
		push_warning("GameOverScreen could not find RestartButton.")
	elif not restart_button.pressed.is_connected(_on_restart_button_pressed):
		restart_button.pressed.connect(_on_restart_button_pressed)

	if menu_button != null and not menu_button.pressed.is_connected(_on_menu_button_pressed):
		menu_button.pressed.connect(_on_menu_button_pressed)

	if title_label != null:
		title_label.modulate = UIStateColors.danger_color()


func show_stats(stats: Dictionary) -> void:
	var run_time := float(stats.get("run_time", 0.0))
	var kill_count := int(stats.get("kill_count", 0))
	var elite_kills := int(stats.get("elite_kill_count", 0))
	var miniboss_kills := int(stats.get("miniboss_kill_count", 0))
	var level := int(stats.get("player_level", int(stats.get("level", 1))))
	var hero_name := str(stats.get("hero_display_name", "Guardian"))
	var dominant := str(stats.get("dominant_archetype", ""))
	var upgrade_count := int(stats.get("selected_upgrade_count", 0))

	if time_label != null:
		time_label.text = "Time:  %s" % UIFormat.format_time(run_time)
	if kills_label != null:
		kills_label.text = "Enemies:  %d" % kill_count
	if elite_kills_label != null:
		elite_kills_label.text = "Elites:  %d" % elite_kills
	if miniboss_kills_label != null:
		miniboss_kills_label.text = "Minibosses:  %d" % miniboss_kills
	if level_label != null:
		level_label.text = "Level:  %d" % level
	if hero_label != null:
		hero_label.text = "Hero:  %s" % hero_name
	_update_extra_label("GradeLabel", "Grade:  %s" % str(stats.get("run_grade", "C")), hero_label)

	var stage_display := str(stats.get("stage_display_name", ""))
	if not stage_display.is_empty():
		var vbox := get_node_or_null("Root/Panel/VBoxContainer")
		if vbox != null:
			var slabel := vbox.get_node_or_null("StageLabel") as Label
			if slabel == null:
				slabel = Label.new()
				slabel.name = "StageLabel"
				slabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				vbox.add_child(slabel)
				vbox.move_child(slabel, hero_label.get_index() + 1)
			slabel.text = "Stage:  %s" % stage_display
			_update_extra_label("ObjectiveLabel", _format_objective_line(stats), slabel)

	var final_boss_id := str(stats.get("final_boss_id", ""))
	if not final_boss_id.is_empty():
		var boss_text := "Final Boss:  Defeated" if bool(stats.get("final_boss_defeated", false)) else ("Final Boss:  Spawned" if bool(stats.get("final_boss_spawned", false)) else "Final Boss:  Not reached")
		_update_extra_label("FinalBossLabel", boss_text, get_node_or_null("Root/Panel/VBoxContainer/ObjectiveLabel"))

	if build_label != null:
		build_label.text = "Build:  %s  A%d / P%d / Act%d" % [
			dominant.capitalize() if not dominant.is_empty() else "Mixed",
			int(stats.get("selected_attack_line_count", 0)),
			int(stats.get("selected_passive_line_count", 0)),
			int(stats.get("selected_active_line_count", 0)),
		]
	if upgrades_label != null:
		upgrades_label.text = "Upgrades:  %d" % upgrade_count
	if evolutions_label != null:
		var titles: Array = stats.get("applied_evolution_titles", [])
		evolutions_label.text = _format_evolution_summary(stats, titles)

	_append_item_rewards(stats.get("item_rewards", []))
	show()
	if restart_button != null:
		restart_button.grab_focus()


func setup_audio_manager(new_audio_manager: Node) -> void:
	audio_manager = new_audio_manager


func _format_evolution_summary(stats: Dictionary, titles: Array) -> String:
	var total := int(stats.get("applied_evolution_count", titles.size()))
	var category_lines: PackedStringArray = []
	var active_count := int(stats.get("active_evolution_count", 0))
	var attack_count := int(stats.get("attack_evolution_count", 0))
	var passive_count := int(stats.get("passive_evolution_count", 0))
	if active_count > 0:
		category_lines.append("Active %d" % active_count)
	if attack_count > 0:
		category_lines.append("Attack %d" % attack_count)
	if passive_count > 0:
		category_lines.append("Passive %d" % passive_count)
	var result := "Evolutions:  %d" % total
	if not category_lines.is_empty():
		result += " (%s)" % ", ".join(category_lines)
	var title_list := UIFormat.format_list(titles)
	if not title_list.is_empty():
		result += " - %s" % title_list
	return result


func _append_item_rewards(item_rewards: Array) -> void:
	var vbox := get_node_or_null("Root/Panel/VBoxContainer")
	if vbox == null:
		return
	var lbl := vbox.get_node_or_null("ItemRewardsLabel") as Label
	if lbl == null:
		var sep := HSeparator.new()
		sep.name = "ItemRewardsSep"
		vbox.add_child(sep)
		var btn_node: Node = restart_button if restart_button != null else menu_button
		if btn_node != null:
			vbox.move_child(sep, btn_node.get_index())
		lbl = Label.new()
		lbl.name = "ItemRewardsLabel"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(lbl)
		if btn_node != null:
			vbox.move_child(lbl, btn_node.get_index())
	if item_rewards.is_empty():
		lbl.text = "Item Rewards:  No items found."
		lbl.modulate = UIStateColors.muted_color()
	else:
		var lines: PackedStringArray = ["Item Rewards:"]
		for item in item_rewards:
			lines.append("  + %s" % EquipmentFormat.item_display_line(item))
		lbl.text = "\n".join(lines)
		lbl.modulate = UIStateColors.positive_color()


func _format_objective_line(stats: Dictionary) -> String:
	var objective_type := str(stats.get("objective_type", "survival"))
	match objective_type:
		"defense":
			return "Objective:  Reactor %d / %d HP" % [int(stats.get("defense_hp_remaining", 0)), int(stats.get("defense_max_hp", 0))]
		"destroy_structures":
			return "Objective:  Portals %d / %d" % [int(stats.get("portals_destroyed", 0)), int(stats.get("portals_total", 0))]
		_:
			return "Objective:  Survival %s" % ("complete" if bool(stats.get("objective_completed", false)) else "failed")


func _update_extra_label(label_name: String, text: String, after_node: Node) -> Label:
	var vbox := get_node_or_null("Root/Panel/VBoxContainer")
	if vbox == null:
		return null
	var label := vbox.get_node_or_null(label_name) as Label
	if label == null:
		label = Label.new()
		label.name = label_name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(label)
		if after_node != null:
			vbox.move_child(label, after_node.get_index() + 1)
	label.text = text
	return label


func _on_restart_button_pressed() -> void:
	if audio_manager != null and audio_manager.has_method("play_ui_click"):
		audio_manager.play_ui_click()
	restart_requested.emit()


func _on_menu_button_pressed() -> void:
	if audio_manager != null and audio_manager.has_method("play_ui_click"):
		audio_manager.play_ui_click()
	quit_to_menu_requested.emit()
