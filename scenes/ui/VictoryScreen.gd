extends CanvasLayer

signal restart_requested
signal quit_to_menu_requested

const UIFormat = preload("res://scenes/ui/UIFormat.gd")
const UIStateColors = preload("res://scenes/ui/UIStateColors.gd")

@onready var title_label: Label = get_node_or_null("Root/Panel/VBoxContainer/Title")
@onready var time_label: Label = get_node_or_null("Root/Panel/VBoxContainer/TimeLabel")
@onready var kills_label: Label = get_node_or_null("Root/Panel/VBoxContainer/KillsLabel")
@onready var elite_kills_label: Label = get_node_or_null("Root/Panel/VBoxContainer/EliteKillsLabel")
@onready var miniboss_kills_label: Label = get_node_or_null("Root/Panel/VBoxContainer/MinibossKillsLabel")
@onready var level_label: Label = get_node_or_null("Root/Panel/VBoxContainer/LevelLabel")
@onready var hero_label: Label = get_node_or_null("Root/Panel/VBoxContainer/HeroLabel")
@onready var build_label: Label = get_node_or_null("Root/Panel/VBoxContainer/BuildLabel")
@onready var upgrades_label: Label = get_node_or_null("Root/Panel/VBoxContainer/UpgradesLabel")
@onready var evolutions_label: Label = get_node_or_null("Root/Panel/VBoxContainer/EvolutionsLabel")
@onready var restart_button: Button = get_node_or_null("Root/Panel/VBoxContainer/RestartButton")
@onready var menu_button: Button = get_node_or_null("Root/Panel/VBoxContainer/MenuButton")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	hide()

	if restart_button != null and not restart_button.pressed.is_connected(_on_restart_button_pressed):
		restart_button.pressed.connect(_on_restart_button_pressed)
	if menu_button != null and not menu_button.pressed.is_connected(_on_menu_button_pressed):
		menu_button.pressed.connect(_on_menu_button_pressed)

	if title_label != null:
		title_label.modulate = UIStateColors.positive_color()


func show_stats(stats: Dictionary) -> void:
	var run_time := float(stats.get("run_time", 0.0))
	var kill_count := int(stats.get("kill_count", 0))
	var elite_kills := int(stats.get("elite_kill_count", 0))
	var miniboss_kills := int(stats.get("miniboss_kill_count", 0))
	var level := int(stats.get("player_level", 1))
	var hero_name := str(stats.get("hero_display_name", "Guardian"))
	var dominant := str(stats.get("dominant_archetype", ""))
	var upgrade_count := int(stats.get("selected_upgrade_count", 0))
	var final_boss_defeated: bool = bool(stats.get("final_boss_defeated", false))
	var final_boss_id := str(stats.get("final_boss_id", ""))

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

	if not final_boss_id.is_empty():
		var vbox := get_node_or_null("Root/Panel/VBoxContainer")
		if vbox != null:
			var blabel := vbox.get_node_or_null("FinalBossLabel") as Label
			if blabel == null:
				blabel = Label.new()
				blabel.name = "FinalBossLabel"
				blabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				vbox.add_child(blabel)
				var ref_node := vbox.get_node_or_null("StageLabel") if not stage_display.is_empty() else hero_label
				if ref_node != null:
					vbox.move_child(blabel, ref_node.get_index() + 1)
			if final_boss_defeated:
				blabel.text = "Final Boss:  Defeated"
				blabel.modulate = UIStateColors.positive_color()
			else:
				blabel.text = "Final Boss:  Not defeated"
				blabel.modulate = UIStateColors.muted_color()

	if build_label != null:
		build_label.text = "Build:  %s" % (dominant.capitalize() if not dominant.is_empty() else "Mixed")
	if upgrades_label != null:
		upgrades_label.text = "Upgrades:  %d" % upgrade_count
	if evolutions_label != null:
		var titles: Array = stats.get("applied_evolution_titles", [])
		evolutions_label.text = "Evolutions:  %s" % UIFormat.format_list(titles)

	show()
	if restart_button != null:
		restart_button.grab_focus()


func hide_screen() -> void:
	hide()


func _on_restart_button_pressed() -> void:
	restart_requested.emit()


func _on_menu_button_pressed() -> void:
	quit_to_menu_requested.emit()
