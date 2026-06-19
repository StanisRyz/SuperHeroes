extends CanvasLayer

var player: Node
var _run_manager: Node = null
var _target_run_time: float = 600.0
var _evolution_manager: Node = null

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

func setup(new_player: Node, run_manager: Node = null, ability_manager: Node = null, buff_manager: Node = null) -> void:
	player = new_player

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


func _update_player_health(current_health: int, max_health: int) -> void:
	if health_bar != null:
		health_bar.max_value = max_health
		health_bar.value = current_health

	if health_label != null:
		health_label.text = "%d / %d" % [current_health, max_health]


func _update_player_experience(current_xp: int, xp_to_next_level: int, level: int) -> void:
	if experience_bar != null:
		experience_bar.max_value = xp_to_next_level
		experience_bar.value = current_xp

	if experience_title != null:
		experience_title.text = "Level %d" % level

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

	if ability_manager.has_method("get_all_ability_states"):
		var states: Dictionary = ability_manager.get_all_ability_states()
		for slot: int in states.keys():
			var state: Dictionary = states[slot]
			_update_ability_cooldown(slot, float(state.get("cooldown_remaining", 0.0)), float(state.get("cooldown_total", 0.0)))


func _update_ability_cooldown(slot: int, cooldown_remaining: float, _cooldown_total: float) -> void:
	match slot:
		1:
			if ability_cooldown_label == null:
				return
			ability_cooldown_label.text = "Nova Pulse (J): Ready" if cooldown_remaining <= 0.0 else "Nova Pulse (J): %.1fs" % cooldown_remaining
		2:
			if laser_cooldown_label == null:
				return
			laser_cooldown_label.text = "Laser Beam (K): Ready" if cooldown_remaining <= 0.0 else "Laser Beam (K): %.1fs" % cooldown_remaining
		3:
			if slam_cooldown_label == null:
				return
			slam_cooldown_label.text = "Hero Slam (L): Ready" if cooldown_remaining <= 0.0 else "Hero Slam (L): %.1fs" % cooldown_remaining


func _update_dash_cooldown(cooldown_remaining: float, _cooldown_total: float) -> void:
	if dash_cooldown_label == null:
		return

	if cooldown_remaining <= 0.0:
		dash_cooldown_label.text = "Dash: Ready"
	else:
		dash_cooldown_label.text = "Dash: %.1fs" % cooldown_remaining


func _update_run_time(seconds: float) -> void:
	if run_time_label != null:
		run_time_label.text = "Time %s" % _format_time(seconds)
	if threat_label != null:
		threat_label.text = "Threat %d" % _get_threat_level(seconds)
	_update_objective(seconds)


func _update_objective(seconds: float) -> void:
	if objective_label != null:
		objective_label.text = "Survive: %s / %s" % [_format_time(seconds), _format_time(_target_run_time)]


func _update_kill_count(kills: int) -> void:
	if kill_count_label != null:
		kill_count_label.text = "Enemies defeated %d" % kills


func update_special_kills(elites: int, minibosses: int) -> void:
	if special_kills_label != null:
		special_kills_label.text = "Elite %d | Boss %d" % [elites, minibosses]


func _on_final_phase_started() -> void:
	if final_phase_label != null:
		final_phase_label.visible = true


func _format_time(seconds: float) -> String:
	var total_seconds := int(floor(seconds))
	var minutes := int(total_seconds / 60.0)
	var remaining_seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, remaining_seconds]


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


func setup_evolution_manager(evolution_manager: Node) -> void:
	_evolution_manager = evolution_manager
	_update_evolution_label(evolution_manager)
	if evolution_manager == null:
		return
	if evolution_manager.has_signal("evolution_applied") and not evolution_manager.evolution_applied.is_connected(_on_evolution_applied):
		evolution_manager.evolution_applied.connect(_on_evolution_applied)
	if evolution_manager.has_signal("evolution_state_changed") and not evolution_manager.evolution_state_changed.is_connected(_on_evolution_state_changed):
		evolution_manager.evolution_state_changed.connect(_on_evolution_state_changed)


func _on_evolution_applied(_evolution_id: String, _evolution_data: Dictionary) -> void:
	_update_evolution_label(_evolution_manager)


func _on_evolution_state_changed() -> void:
	_update_evolution_label(_evolution_manager)


func _update_evolution_label(evolution_manager: Node) -> void:
	if evolution_label == null:
		return
	if evolution_manager == null or not evolution_manager.has_method("get_applied_evolution_titles"):
		evolution_label.text = "Evolution: None"
		return
	var titles: Array = evolution_manager.get_applied_evolution_titles()
	if titles.is_empty():
		evolution_label.text = "Evolution: None"
	elif titles.size() == 1:
		evolution_label.text = "Evolved: %s" % titles[0]
	else:
		evolution_label.text = "Evolved: %d" % titles.size()


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


func _on_buff_started(buff_id: String, duration: float) -> void:
	_on_buff_updated(buff_id, duration, duration)


func _on_buff_updated(buff_id: String, time_left: float, _duration: float) -> void:
	match buff_id:
		"move_speed_boost":
			if move_speed_label != null:
				move_speed_label.text = "Speed: %.1fs" % time_left
				move_speed_label.visible = true
		"attack_speed_boost":
			if attack_speed_label != null:
				attack_speed_label.text = "Haste: %.1fs" % time_left
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
		shield_label.visible = true
	else:
		shield_label.visible = false
