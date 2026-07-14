extends CanvasLayer

const UIFormat = preload("res://scenes/ui/UIFormat.gd")
const UIStateColors = preload("res://scenes/ui/UIStateColors.gd")

var player: Node
var _run_manager: Node = null
var _target_run_time: float = 600.0
var _evolution_manager: Node = null
var _passive_manager: Node = null
var _objective_type: String = "survival"
var _final_boss_display_name: String = ""
var _ability_names: Dictionary = {
	1: "A1",
	2: "A2",
	3: "A3",
}
var _ability_states: Dictionary = {}

@onready var health_bar: ProgressBar = get_node_or_null("Root/HealthPanel/PlayerHealthBar")
@onready var health_label: Label = get_node_or_null("Root/HealthPanel/PlayerHealthLabel")
@onready var experience_bar: ProgressBar = get_node_or_null("Root/ExperiencePanel/ExperienceBar")
@onready var experience_title: Label = get_node_or_null("Root/ExperiencePanel/ExperienceTitle")
@onready var experience_label: Label = get_node_or_null("Root/ExperiencePanel/ExperienceLabel")
@onready var run_time_label: Label = get_node_or_null("Root/RunPanel/RunTimeLabel")
@onready var kill_count_label: Label = get_node_or_null("Root/RunPanel/KillCountLabel")
@onready var threat_label: Label = get_node_or_null("Root/RunPanel/ThreatLabel")
@onready var objective_label: Label = get_node_or_null("Root/RunPanel/ObjectiveLabel")
@onready var special_kills_label: Label = get_node_or_null("Root/RunPanel/SpecialKillsLabel")
@onready var final_phase_label: Label = get_node_or_null("Root/RunPanel/FinalPhaseLabel")
@onready var final_boss_label: Label = get_node_or_null("Root/RunPanel/FinalBossLabel")
@onready var ability_cooldown_label: Label = get_node_or_null("Root/AbilityPanel/AbilityCooldownLabel")
@onready var laser_cooldown_label: Label = get_node_or_null("Root/AbilityPanel/LaserCooldownLabel")
@onready var slam_cooldown_label: Label = get_node_or_null("Root/AbilityPanel/SlamCooldownLabel")
@onready var dash_cooldown_label: Label = get_node_or_null("Root/AbilityPanel/DashCooldownLabel")
@onready var shield_label: Label = get_node_or_null("Root/BuffPanel/ShieldLabel")
@onready var move_speed_label: Label = get_node_or_null("Root/BuffPanel/MoveSpeedLabel")
@onready var attack_speed_label: Label = get_node_or_null("Root/BuffPanel/AttackSpeedLabel")
@onready var build_label: Label = get_node_or_null("Root/BuildPanel/BuildLabel")
@onready var hero_label: Label = get_node_or_null("Root/BuildPanel/HeroLabel")
@onready var evolution_label: Label = get_node_or_null("Root/BuildPanel/EvolutionLabel")


func update_evolution_path_state(path: Dictionary) -> void:
	if evolution_label == null:
		return
	if path.is_empty():
		evolution_label.text = "Evolution progress: none"
		return
	var title := str(path.get("title", "Evolution"))
	if str(path.get("state", "")) == "ready":
		evolution_label.text = "READY: %s" % title
		return
	var lines: Array[String] = []
	for key in ["attack_line", "passive_line", "active_line"]:
		var line: Dictionary = path.get(key, {})
		lines.append("%s %d/%d" % [str(line.get("title", "")), int(line.get("current_level", 0)), int(line.get("required_level", 5))])
	evolution_label.text = "Closest evolution: %s — %d/15\n%s" % [title, int(path.get("total_progress", 0)), " | ".join(lines)]
@onready var passive_label: Label = get_node_or_null("Root/BuildPanel/PassiveLabel")
@onready var hero_resource_label: Label = get_node_or_null("Root/HeroResourcePanel/HeroResourceLabel")
@onready var hero_resource_bar: ProgressBar = get_node_or_null("Root/HeroResourcePanel/HeroResourceBar")


func setup(new_player: Node, run_manager: Node = null, ability_manager: Node = null, buff_manager: Node = null) -> void:
	player = new_player
	if ability_manager != null and ability_manager.has_signal("hero_resource_changed") and not ability_manager.hero_resource_changed.is_connected(_on_hero_resource_changed):
		ability_manager.hero_resource_changed.connect(_on_hero_resource_changed)

	if player == null:
		push_warning("GameHUD setup called without a player.")
		return

	var current_health = player.get("current_health")
	var max_health = player.get("max_health")
	if current_health == null or max_health == null:
		push_warning("GameHUD player is missing current_health or max_health.")
		return

	_update_player_health(int(current_health), int(max_health))

	if player.has_signal("health_changed") and not player.health_changed.is_connected(_update_player_health):
		player.health_changed.connect(_update_player_health)

	var current_xp = player.get("current_xp")
	var xp_to_next_level = player.get("xp_to_next_level")
	var level = player.get("level")
	if current_xp != null and xp_to_next_level != null and level != null:
		_update_player_experience(int(current_xp), int(xp_to_next_level), int(level))
	elif experience_bar != null:
		push_warning("GameHUD player is missing current_xp, xp_to_next_level, or level.")

	if player.has_signal("experience_changed") and not player.experience_changed.is_connected(_update_player_experience):
		player.experience_changed.connect(_update_player_experience)
	if player.has_signal("dash_cooldown_changed") and not player.dash_cooldown_changed.is_connected(_update_dash_cooldown):
		player.dash_cooldown_changed.connect(_update_dash_cooldown)
	_update_dash_cooldown(0.0, 0.0)

	_setup_run_manager(run_manager)
	_setup_ability_manager(ability_manager)
	_setup_buff_manager(buff_manager)
	_setup_player_shield(player)


func _on_hero_resource_changed(resource_name: String, current: float, maximum: float) -> void:
	if hero_resource_label != null:
		hero_resource_label.text = "%s: %.0f / %.0f" % [resource_name, current, maximum]
		hero_resource_label.visible = true
	if hero_resource_bar != null:
		hero_resource_bar.max_value = maximum
		hero_resource_bar.value = current
		hero_resource_bar.visible = true


func _update_player_health(current_health: int, max_health: int) -> void:
	if health_bar != null:
		health_bar.max_value = max_health
		health_bar.value = current_health

	if health_label != null:
		var hp_ratio := float(current_health) / float(max_health) if max_health > 0 else 1.0
		var base_text := "%d / %d" % [current_health, max_health]
		if hp_ratio <= 0.15:
			health_label.text = "LOW  %s" % base_text
			health_label.modulate = UIStateColors.danger_color()
		elif hp_ratio <= 0.30:
			health_label.text = base_text
			health_label.modulate = UIStateColors.warning_color()
		else:
			health_label.text = base_text
			health_label.modulate = Color.WHITE


func _update_player_experience(current_xp: int, xp_to_next_level: int, level: int) -> void:
	if experience_bar != null:
		experience_bar.max_value = xp_to_next_level
		experience_bar.value = current_xp

	if experience_title != null:
		experience_title.text = "Lv %d" % level

	if experience_label != null:
		experience_label.text = "XP %d / %d" % [current_xp, xp_to_next_level]


func _setup_run_manager(run_manager: Node) -> void:
	_run_manager = run_manager
	if run_manager == null:
		_update_run_time(0.0)
		_update_kill_count(0)
		_update_objective(0.0)
		return

	var run_time = run_manager.get("run_time")
	var kill_count = run_manager.get("kill_count")
	_update_run_time(float(run_time) if run_time != null else 0.0)
	_update_kill_count(int(kill_count) if kill_count != null else 0)

	if run_manager.has_method("get_target_run_time"):
		_target_run_time = run_manager.get_target_run_time()
	_update_objective(float(run_time) if run_time != null else 0.0)

	if run_manager.has_signal("run_time_changed") and not run_manager.run_time_changed.is_connected(_update_run_time):
		run_manager.run_time_changed.connect(_update_run_time)
	if run_manager.has_signal("kill_count_changed") and not run_manager.kill_count_changed.is_connected(_update_kill_count):
		run_manager.kill_count_changed.connect(_update_kill_count)
	if run_manager.has_signal("final_phase_started") and not run_manager.final_phase_started.is_connected(_on_final_phase_started):
		run_manager.final_phase_started.connect(_on_final_phase_started)
	if run_manager.has_signal("special_kill_count_changed") and not run_manager.special_kill_count_changed.is_connected(update_special_kills):
		run_manager.special_kill_count_changed.connect(update_special_kills)


func _setup_ability_manager(ability_manager: Node) -> void:
	_update_ability_cooldown(1, 0.0, 0.0)
	_update_ability_cooldown(2, 0.0, 0.0)
	_update_ability_cooldown(3, 0.0, 0.0)

	if ability_manager == null:
		return

	if ability_manager.has_signal("ability_cooldown_changed") and not ability_manager.ability_cooldown_changed.is_connected(_update_ability_cooldown):
		ability_manager.ability_cooldown_changed.connect(_update_ability_cooldown)
	if ability_manager.has_signal("ability_state_changed") and not ability_manager.ability_state_changed.is_connected(_on_ability_state_changed):
		ability_manager.ability_state_changed.connect(_on_ability_state_changed)

	if ability_manager.has_method("get_all_ability_states"):
		var states: Dictionary = ability_manager.get_all_ability_states()
		for slot: int in states.keys():
			var state: Dictionary = states[slot].duplicate()
			if not state.has("slot"):
				state["slot"] = slot
			if ability_manager.has_method("get_ability_name"):
				_ability_names[slot] = ability_manager.get_ability_name(slot, true)
			else:
				_ability_names[slot] = str(state.get("short_name", state.get("display_name", _ability_names.get(slot, "Ability"))))
			_on_ability_state_changed(state)


func _on_ability_state_changed(state: Dictionary) -> void:
	var slot := int(state.get("slot", 0))
	if slot < 1 or slot > 3:
		return
	_ability_states[slot] = state.duplicate()
	_ability_names[slot] = str(state.get("short_name", _ability_names.get(slot, "Ability")))
	_update_ability_cooldown(slot, float(state.get("cooldown_remaining", 0.0)), float(state.get("cooldown_total", 0.0)))


func _update_ability_cooldown(slot: int, cooldown_remaining: float, _cooldown_total: float) -> void:
	var cd_text := UIFormat.format_cooldown(cooldown_remaining)
	var state: Dictionary = _ability_states.get(slot, {})
	var is_ready := bool(state.get("is_ready", cooldown_remaining <= 0.0))
	var is_active := bool(state.get("is_active", false))
	var is_blocked := bool(state.get("is_blocked", not is_ready))
	var blocked_reason := str(state.get("blocked_reason", ""))
	var display_value := cd_text if cooldown_remaining > 0.0 or is_active else (blocked_reason.capitalize() if is_blocked else cd_text)
	var color := UIStateColors.ready_color() if is_ready else UIStateColors.cooldown_color()
	match slot:
		1:
			if ability_cooldown_label == null:
				return
			ability_cooldown_label.text = "J  %s: %s" % [_get_ability_name(1, "A1"), display_value]
			ability_cooldown_label.modulate = color
		2:
			if laser_cooldown_label == null:
				return
			laser_cooldown_label.text = "K  %s: %s" % [_get_ability_name(2, "A2"), display_value]
			laser_cooldown_label.modulate = color
		3:
			if slam_cooldown_label == null:
				return
			slam_cooldown_label.text = "L  %s: %s" % [_get_ability_name(3, "A3"), display_value]
			slam_cooldown_label.modulate = color


func _get_ability_name(slot: int, fallback: String) -> String:
	return str(_ability_names.get(slot, fallback))


func _update_dash_cooldown(cooldown_remaining: float, _cooldown_total: float) -> void:
	if dash_cooldown_label == null:
		return
	var cd_text := UIFormat.format_cooldown(cooldown_remaining)
	var is_ready := cooldown_remaining <= 0.0
	dash_cooldown_label.text = "Space  Dash: %s" % cd_text
	dash_cooldown_label.modulate = UIStateColors.ready_color() if is_ready else UIStateColors.cooldown_color()


func _update_run_time(seconds: float) -> void:
	if run_time_label != null:
		run_time_label.text = "Time  %s" % UIFormat.format_time(seconds)
	if threat_label != null:
		threat_label.text = "Threat  %d" % _get_threat_level(seconds)
	_update_objective(seconds)


func setup_objective_manager(obj_manager: Node, objective_type: String) -> void:
	_objective_type = objective_type
	if obj_manager == null:
		return
	if obj_manager.has_signal("objective_state_changed") and not obj_manager.objective_state_changed.is_connected(_on_objective_state_changed):
		obj_manager.objective_state_changed.connect(_on_objective_state_changed)
	if obj_manager.has_method("get_objective_state"):
		_on_objective_state_changed(obj_manager.get_objective_state())


func _on_objective_state_changed(state: Dictionary) -> void:
	update_objective_state(state)


func update_objective_state(state: Dictionary) -> void:
	if objective_label == null:
		return
	match _objective_type:
		"defense":
			var cur := int(state.get("defense_hp", 0))
			var max_hp := int(state.get("defense_max_hp", 1))
			var disp := str(state.get("defense_display_name", "Reactor"))
			if state.get("failed", false):
				objective_label.text = "%s: DESTROYED" % disp
				objective_label.modulate = Color(1.0, 0.2, 0.2)
			else:
				var ratio := float(cur) / float(max_hp) if max_hp > 0 else 0.0
				objective_label.text = "%s: %d / %d HP" % [disp, cur, max_hp]
				if ratio <= 0.30:
					objective_label.modulate = Color(1.0, 0.35, 0.1)
				elif ratio <= 0.60:
					objective_label.modulate = Color(1.0, 0.85, 0.2)
				else:
					objective_label.modulate = Color(0.4, 0.92, 1.0)
		"destroy_structures":
			var destroyed := int(state.get("portals_destroyed", 0))
			var total := int(state.get("portals_total", 0))
			if destroyed >= total and total > 0:
				objective_label.text = "Portals: ALL DESTROYED"
				objective_label.modulate = Color(0.2, 1.0, 0.35)
			else:
				objective_label.text = "Portals: %d / %d" % [destroyed, total]
				objective_label.modulate = Color(1.0, 0.55, 0.1)


func _update_objective(seconds: float) -> void:
	if _objective_type != "survival":
		return
	if objective_label != null:
		objective_label.text = "Survive: %s / %s" % [UIFormat.format_time(seconds), UIFormat.format_time(_target_run_time)]


func _update_kill_count(kills: int) -> void:
	if kill_count_label != null:
		kill_count_label.text = "Kills  %d" % kills


func update_special_kills(elites: int, minibosses: int) -> void:
	if special_kills_label != null:
		special_kills_label.text = "Elite %d  |  Boss %d" % [elites, minibosses]


func _on_final_phase_started() -> void:
	if final_phase_label != null:
		final_phase_label.visible = true
		final_phase_label.modulate = UIStateColors.final_phase_color()


func show_final_boss_info(boss_name: String) -> void:
	_final_boss_display_name = boss_name
	if final_boss_label == null:
		return
	final_boss_label.text = "Boss: %s  [P1]" % boss_name
	final_boss_label.modulate = UIStateColors.boss_color()
	final_boss_label.visible = true


func update_boss_phase(phase: int) -> void:
	if final_boss_label == null or _final_boss_display_name.is_empty():
		return
	var tag := "[P%d]" % phase
	final_boss_label.text = "Boss: %s  %s" % [_final_boss_display_name, tag]
	match phase:
		2: final_boss_label.modulate = Color(1.0, 0.7, 0.1)
		3: final_boss_label.modulate = Color(1.0, 0.3, 0.1)
		_: final_boss_label.modulate = UIStateColors.boss_color()


func show_final_boss_defeated() -> void:
	if final_boss_label == null:
		return
	final_boss_label.text = "Boss defeated"
	final_boss_label.modulate = UIStateColors.positive_color()


func _get_threat_level(seconds: float) -> int:
	return int(clampf(floor(seconds / 30.0) + 1.0, 1.0, 10.0))


func setup_upgrade_manager(upgrade_manager: Node) -> void:
	if upgrade_manager == null:
		return
	if build_label != null:
		build_label.text = "Build: Mixed"
	if upgrade_manager.has_signal("build_changed") and not upgrade_manager.build_changed.is_connected(_on_build_changed):
		upgrade_manager.build_changed.connect(_on_build_changed)


func _on_build_changed(dominant_archetype: String, _points: Dictionary) -> void:
	if build_label == null:
		return
	if dominant_archetype.is_empty():
		build_label.text = "Build: Mixed"
	else:
		build_label.text = "Build: %s" % dominant_archetype.capitalize()


func set_hero_name(hero_name: String) -> void:
	if hero_label == null:
		return
	var display_name := hero_name if not hero_name.is_empty() else "Guardian"
	hero_label.text = "Hero: %s" % display_name


func set_primary_weapon_name(weapon_display_name: String) -> void:
	if weapon_display_name.is_empty():
		return
	var build_panel := get_node_or_null("Root/BuildPanel")
	if build_panel == null:
		return
	var weapon_label := build_panel.get_node_or_null("WeaponLabel") as Label
	if weapon_label == null:
		weapon_label = Label.new()
		weapon_label.name = "WeaponLabel"
		build_panel.add_child(weapon_label)
	weapon_label.text = "Weapon: %s" % weapon_display_name


func set_stage_name(stage_name: String) -> void:
	if stage_name.is_empty():
		return
	var run_panel := get_node_or_null("Root/RunPanel")
	if run_panel == null:
		return
	var stage_label := run_panel.get_node_or_null("StageLabel") as Label
	if stage_label == null:
		stage_label = Label.new()
		stage_label.name = "StageLabel"
		run_panel.add_child(stage_label)
	stage_label.text = "Stage: %s" % stage_name


func setup_evolution_manager(evolution_manager: Node) -> void:
	_evolution_manager = evolution_manager
	_update_evolution_label(evolution_manager)
	if evolution_manager == null:
		return
	if evolution_manager.has_signal("evolution_applied") and not evolution_manager.evolution_applied.is_connected(_on_evolution_applied):
		evolution_manager.evolution_applied.connect(_on_evolution_applied)
	if evolution_manager.has_signal("evolution_state_changed") and not evolution_manager.evolution_state_changed.is_connected(_on_evolution_state_changed):
		evolution_manager.evolution_state_changed.connect(_on_evolution_state_changed)


func setup_passive_manager(passive_manager: Node) -> void:
	_passive_manager = passive_manager
	_update_passive_label(passive_manager)
	if passive_manager == null:
		return
	if passive_manager.has_signal("passive_changed") and not passive_manager.passive_changed.is_connected(_on_passive_changed):
		passive_manager.passive_changed.connect(_on_passive_changed)
	if passive_manager.has_signal("passive_state_changed") and not passive_manager.passive_state_changed.is_connected(_on_passive_state_changed):
		passive_manager.passive_state_changed.connect(_on_passive_state_changed)


func _on_passive_changed(_passive_id: String, _level: int) -> void:
	_update_passive_label(_passive_manager)


func _on_passive_state_changed() -> void:
	_update_passive_label(_passive_manager)


func _update_passive_label(passive_manager: Node) -> void:
	if passive_label == null:
		return
	if passive_manager == null or not passive_manager.has_method("get_selected_passive_ids"):
		passive_label.text = "Passives: None"
		passive_label.tooltip_text = ""
		return
	var passive_ids: Array[String] = passive_manager.get_selected_passive_ids()
	if passive_ids.is_empty():
		passive_label.text = "Passives: None"
		passive_label.tooltip_text = ""
		return
	var titles: Array[String] = []
	var tooltip_lines: PackedStringArray = []
	for passive_id: String in passive_ids:
		var state: Dictionary = passive_manager.get_passive_state(passive_id)
		var title := str(state.get("title", passive_id))
		titles.append(title)
		tooltip_lines.append("%s Lv %d" % [title, int(state.get("level", 0))])
		if passive_id == "orbit_shields":
			_update_orbit_shield_label(int(state.get("current_charges", 0)), int(state.get("maximum_charges", 0)), float(state.get("remaining_regeneration_time", 0.0)))
	passive_label.text = "Passives: %s" % titles[0] if titles.size() == 1 else "Passives: %s +%d" % [titles[0], titles.size() - 1]
	passive_label.tooltip_text = "\n".join(tooltip_lines)


func _on_evolution_applied(_evolution_id: String, _evolution_data: Dictionary) -> void:
	_update_evolution_label(_evolution_manager)


func _on_evolution_state_changed() -> void:
	_update_evolution_label(_evolution_manager)


func _update_evolution_label(evolution_manager: Node) -> void:
	if evolution_label == null:
		return
	if evolution_manager == null or not evolution_manager.has_method("get_applied_evolution_titles"):
		evolution_label.text = "Evolved: None"
		evolution_label.tooltip_text = ""
		return
	var titles: Array = evolution_manager.get_applied_evolution_titles()
	evolution_label.tooltip_text = "\n".join(PackedStringArray(titles))
	if titles.is_empty():
		evolution_label.text = "Evolved: None"
	elif titles.size() == 1:
		evolution_label.text = "Evolved: %s" % titles[0]
	else:
		evolution_label.text = "Evolved: %s +%d" % [titles[0], titles.size() - 1]


func _setup_buff_manager(buff_manager: Node) -> void:
	if shield_label != null:
		shield_label.visible = false
	if move_speed_label != null:
		move_speed_label.visible = false
	if attack_speed_label != null:
		attack_speed_label.visible = false

	if buff_manager == null:
		return

	if buff_manager.has_signal("buff_started") and not buff_manager.buff_started.is_connected(_on_buff_started):
		buff_manager.buff_started.connect(_on_buff_started)
	if buff_manager.has_signal("buff_updated") and not buff_manager.buff_updated.is_connected(_on_buff_updated):
		buff_manager.buff_updated.connect(_on_buff_updated)
	if buff_manager.has_signal("buff_finished") and not buff_manager.buff_finished.is_connected(_on_buff_finished):
		buff_manager.buff_finished.connect(_on_buff_finished)
	if buff_manager.has_signal("shield_changed") and not buff_manager.shield_changed.is_connected(_on_shield_changed):
		buff_manager.shield_changed.connect(_on_shield_changed)


func _setup_player_shield(shield_player: Node) -> void:
	if shield_player == null or not shield_player.has_signal("shield_changed") or not shield_player.has_method("get_shield_charges"):
		return
	if not shield_player.shield_changed.is_connected(_on_player_shield_changed):
		shield_player.shield_changed.connect(_on_player_shield_changed)
	_on_player_shield_changed(int(shield_player.get_shield_charges()), int(shield_player.get_maximum_shield_charges()))


func _on_player_shield_changed(current: int, maximum: int) -> void:
	_update_orbit_shield_label(current, maximum, 0.0)


func _update_orbit_shield_label(current: int, maximum: int, remaining_time: float) -> void:
	if shield_label == null:
		return
	if maximum <= 0:
		shield_label.text = "Shield: None"
		shield_label.tooltip_text = ""
		shield_label.modulate = Color.WHITE
		shield_label.visible = true
		return
	shield_label.text = "Shield: %d / %d" % [current, maximum]
	shield_label.tooltip_text = "Next charge: %.1fs" % remaining_time if current < maximum and remaining_time > 0.0 else ""
	shield_label.modulate = UIStateColors.positive_color() if current > 0 else UIStateColors.warning_color()
	shield_label.visible = true


func _on_buff_started(buff_id: String, duration: float) -> void:
	_on_buff_updated(buff_id, duration, duration)


func _on_buff_updated(buff_id: String, time_left: float, _duration: float) -> void:
	match buff_id:
		"move_speed_boost":
			if move_speed_label != null:
				move_speed_label.text = "Speed: %.1fs" % time_left
				move_speed_label.modulate = UIStateColors.positive_color()
				move_speed_label.visible = true
		"attack_speed_boost":
			if attack_speed_label != null:
				attack_speed_label.text = "Haste: %.1fs" % time_left
				attack_speed_label.modulate = UIStateColors.positive_color()
				attack_speed_label.visible = true


func _on_buff_finished(buff_id: String) -> void:
	match buff_id:
		"move_speed_boost":
			if move_speed_label != null:
				move_speed_label.visible = false
		"attack_speed_boost":
			if attack_speed_label != null:
				attack_speed_label.visible = false


func _on_shield_changed(charges: int) -> void:
	if shield_label == null:
		return
	if charges > 0:
		shield_label.text = "Shield: %d" % charges
		shield_label.modulate = UIStateColors.positive_color()
		shield_label.visible = true
	else:
		shield_label.visible = false
