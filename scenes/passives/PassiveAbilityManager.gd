extends Node

signal passive_changed(passive_id: String, level: int)

const PASSIVE_DEFINITIONS := {
	"orbit_shields": {
		"display_name": "Orbit Shields",
		"upgrade_line_id": "orbit_shields",
		"slot_category": "passive",
		"source_type": "passive",
		"source_skill_id": "orbit_shields",
		"grid_index": 1,
		"evolution_role": "passive",
		"max_charges": [1, 1, 2],
		"regen_interval": [18.0, 14.0, 12.0],
	},
	"storm_relay": {
		"display_name": "Storm Relay",
		"upgrade_line_id": "storm_relay",
		"slot_category": "passive",
		"source_type": "passive",
		"source_skill_id": "storm_relay",
		"grid_index": 2,
		"evolution_role": "passive",
		"damage": [8, 12, 16],
		"interval": [5.5, 4.8, 4.2],
		"range": 520.0,
	},
	"guardian_drone": {
		"display_name": "Guardian Drone",
		"upgrade_line_id": "guardian_drone",
		"slot_category": "passive",
		"source_type": "passive",
		"source_skill_id": "guardian_drone",
		"grid_index": 3,
		"evolution_role": "passive",
		"damage": [5, 8, 11],
		"interval": [3.4, 3.0, 2.6],
		"range": 460.0,
	},
	"magnet_core": {
		"display_name": "Magnet Core",
		"upgrade_line_id": "magnet_core",
		"slot_category": "passive",
		"source_type": "passive",
		"source_skill_id": "magnet_core",
		"grid_index": 4,
		"evolution_role": "passive",
		"pickup_radius_bonus": [45.0, 85.0, 125.0],
	},
	"chain_lightning": {
		"display_name": "Chain Lightning",
		"upgrade_line_id": "chain_lightning",
		"slot_category": "passive",
		"source_type": "passive",
		"source_skill_id": "chain_lightning",
		"grid_index": 5,
		"evolution_role": "passive",
		"damage": [6, 9, 12],
		"interval": [6.6, 5.8, 5.0],
		"range": 500.0,
		"bounce_range": [210.0, 240.0, 270.0],
		"bounces": [2, 3, 4],
	},
	"recovery_field": {
		"display_name": "Recovery Field",
		"upgrade_line_id": "recovery_field",
		"slot_category": "passive",
		"source_type": "passive",
		"source_skill_id": "recovery_field",
		"grid_index": 6,
		"evolution_role": "passive",
		"heal": [4, 6, 8],
		"interval": [12.0, 10.5, 9.0],
		"radius": [80.0, 95.0, 110.0],
	},
	"battle_focus": {
		"display_name": "Battle Focus",
		"upgrade_line_id": "battle_focus",
		"slot_category": "passive",
		"source_type": "passive",
		"source_skill_id": "battle_focus",
		"grid_index": 7,
		"evolution_role": "passive",
		"damage": [4, 6, 8],
		"interval": [7.5, 6.5, 5.5],
		"range": 420.0,
		"attack_speed_multiplier": [1.12, 1.18, 1.24],
		"duration": [3.0, 3.5, 4.0],
	},
	"static_field": {
		"display_name": "Static Field",
		"upgrade_line_id": "static_field",
		"slot_category": "passive",
		"source_type": "passive",
		"source_skill_id": "static_field",
		"grid_index": 8,
		"evolution_role": "passive",
		"damage": [5, 7, 9],
		"interval": [4.8, 4.2, 3.6],
		"radius": [150.0, 175.0, 200.0],
	},
	"time_dilator": {
		"display_name": "Time Dilator",
		"upgrade_line_id": "time_dilator",
		"slot_category": "passive",
		"source_type": "passive",
		"source_skill_id": "time_dilator",
		"grid_index": 9,
		"evolution_role": "passive",
		"interval": [8.5, 7.5, 6.5],
		"radius": [190.0, 220.0, 250.0],
		"slow_multiplier": [0.72, 0.64, 0.56],
		"duration": [2.5, 3.0, 3.5],
	},
}
const STATUS_SENTINEL := Vector2(100000000.0, 100000000.0)
const SHIELD_VISUAL_RADIUS := 42.0
const SHIELD_VISUAL_SIZE := 8.0
const DRONE_VISUAL_RADIUS := 58.0
const ARC_DURATION := 0.16
const ARC_WIDTH := 4.0
const EVOLVED_PASSIVE_MIN_INTERVAL := 0.85
const GRAVITY_RAGE_MIN_INTERVAL := 2.4
const SOLAR_STORM_MAX_TARGETS := 5
const DRONE_SWARM_MAX_TARGETS := 4
const SHOCK_NET_MAX_BOUNCES := 8
const BERSERKER_FOCUS_MAX_TARGETS := 4

var player: Node2D = null
var enemy_container: Node = null
var projectile_container: Node = null
var pickup_container: Node = null
var feedback_manager: Node = null
var debug_logging: bool = false

var _passive_levels: Dictionary = {}
var _timers: Dictionary = {
	"orbit_shields": 0.0,
	"storm_relay": 0.0,
	"guardian_drone": 0.0,
	"chain_lightning": 0.0,
	"recovery_field": 0.0,
	"battle_focus": 0.0,
	"static_field": 0.0,
	"time_dilator": 0.0,
	"magnet_core": 0.0,
}
var _applied_pickup_radius_bonus: float = 0.0
var _visual_root: Node2D = null
var _shield_visuals_root: Node2D = null
var _drone_visual: Node2D = null
var _orbit_time: float = 0.0
var _last_shield_visual_count: int = -1
var _last_known_shield_charges: int = 0
var _last_event: String = "none"
var _selected_passive_evolutions: Array[String] = []
var _passive_evolution_targets: Dictionary = {}
var _radiant_reduction_time_left: float = 0.0
var _radiant_reduction_value: float = 0.0


func setup(new_player: Node, new_enemy_container: Node, new_projectile_container: Node, new_pickup_container: Node, new_feedback_manager: Node) -> void:
	player = new_player as Node2D
	enemy_container = new_enemy_container
	projectile_container = new_projectile_container
	pickup_container = new_pickup_container
	feedback_manager = new_feedback_manager
	_setup_visual_root()
	_connect_buff_manager()


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	if player.has_method("is_dead") and player.is_dead():
		return

	_orbit_time += delta
	_update_passive_visuals()

	if has_passive("orbit_shields"):
		_tick_orbit_shields(delta)
	if has_passive("storm_relay"):
		_tick_storm_relay(delta)
	if has_passive("guardian_drone"):
		_tick_guardian_drone(delta)
	if has_passive("chain_lightning"):
		_tick_chain_lightning(delta)
	if has_passive("recovery_field"):
		_tick_recovery_field(delta)
	if has_passive("battle_focus"):
		_tick_battle_focus(delta)
	if has_passive("static_field"):
		_tick_static_field(delta)
	if has_passive("time_dilator"):
		_tick_time_dilator(delta)
	if has_passive("magnet_core") and has_passive_evolution("rage_leap_final_impact"):
		_tick_gravity_rage(delta)
	_tick_radiant_reduction(delta)


func add_or_upgrade_passive(passive_id: String) -> void:
	if not PASSIVE_DEFINITIONS.has(passive_id):
		push_warning("PassiveAbilityManager: unknown passive id '%s'." % passive_id)
		return

	var max_level := _get_max_level(passive_id)
	var next_level := mini(get_passive_level(passive_id) + 1, max_level)
	_passive_levels[passive_id] = next_level

	match passive_id:
		"orbit_shields":
			_fill_orbit_shields()
			_update_shield_visuals(true)
		"magnet_core":
			_apply_magnet_core_bonus()
			_show_magnet_feedback()
		"guardian_drone":
			_ensure_drone_visual()
		"recovery_field":
			_show_recovery_pulse()
		"battle_focus":
			_show_status("FOCUS READY")
		"static_field":
			_show_pulse_ring(player.global_position, _get_scaled_value("static_field", "radius", next_level), Color(0.25, 0.95, 1.0, 0.7), 0.28, 3.0)
		"time_dilator":
			_show_pulse_ring(player.global_position, _get_scaled_value("time_dilator", "radius", next_level), Color(0.65, 0.75, 1.0, 0.65), 0.32, 3.0)

	_last_event = "selected %s level %d" % [passive_id, next_level]
	if debug_logging:
		print("PASSIVE_SELECTED: id=%s level=%d" % [passive_id, next_level])
	passive_changed.emit(passive_id, next_level)
	_show_status("%s Lv %d" % [_get_display_name(passive_id), next_level])


func get_passive_level(passive_id: String) -> int:
	return int(_passive_levels.get(passive_id, 0))


func has_passive(passive_id: String) -> bool:
	return get_passive_level(passive_id) > 0


func get_passive_state() -> Dictionary:
	var state := {
		"levels": _passive_levels.duplicate(),
		"timers": _timers.duplicate(),
		"pickup_radius_bonus": _applied_pickup_radius_bonus,
		"last_event": _last_event,
		"passive_evolution_ids": _selected_passive_evolutions.duplicate(),
		"passive_evolution_targets": _passive_evolution_targets.duplicate(),
		"passive_evolution_titles": _get_passive_evolution_titles(),
	}
	var buff_manager := _get_buff_manager()
	if buff_manager != null and buff_manager.has_method("get_shield_charges"):
		state["shield_charges"] = buff_manager.get_shield_charges()
		state["shield_max_charges"] = _get_orbit_shield_max_charges()
	return state


func apply_passive_evolution(evolution_id: String, target_id: String) -> bool:
	if not PASSIVE_DEFINITIONS.has(target_id):
		push_warning("PassiveAbilityManager: unknown passive target '%s' for evolution '%s'." % [target_id, evolution_id])
		return false
	if not _is_known_passive_evolution(evolution_id, target_id):
		push_warning("PassiveAbilityManager: no passive evolution effect for '%s' -> '%s'." % [evolution_id, target_id])
		return false
	if _selected_passive_evolutions.has(evolution_id):
		return true

	_selected_passive_evolutions.append(evolution_id)
	_passive_evolution_targets[evolution_id] = target_id
	match target_id:
		"orbit_shields":
			_fill_orbit_shields()
			_trigger_solar_aegis_explosion(player.global_position if player != null else Vector2.ZERO)
		"magnet_core":
			_apply_magnet_core_bonus()
			_timers["magnet_core"] = 0.2
			_show_gravity_rage_pulse()
		"guardian_drone":
			_ensure_drone_visual()
			_show_drone_swarm_burst()
		"recovery_field":
			_trigger_radiant_renewal()
		"battle_focus":
			_show_status("BERSERKER FOCUS")
		"static_field":
			_show_rage_field_pulse()
		"time_dilator":
			_show_stasis_field_pulse()
		"storm_relay":
			_show_status("SOLAR STORM")
		"chain_lightning":
			_show_status("SHOCK NET")
	_last_event = "passive evolution %s" % evolution_id
	_show_status(_get_passive_evolution_status(evolution_id))
	return true


func has_passive_evolution(evolution_id: String) -> bool:
	return _selected_passive_evolutions.has(evolution_id)


func debug_get_passive_evolutions() -> Dictionary:
	return {
		"ids": _selected_passive_evolutions.duplicate(),
		"targets": _passive_evolution_targets.duplicate(),
		"titles": _get_passive_evolution_titles(),
	}


func cleanup() -> void:
	_clear_radiant_reduction()
	_reset_magnet_core_bonus()
	var buff_manager := _get_buff_manager()
	if buff_manager != null and buff_manager.has_method("clear_timed_buff"):
		buff_manager.clear_timed_buff("battle_focus")
	_passive_levels.clear()
	_selected_passive_evolutions.clear()
	_passive_evolution_targets.clear()
	for key in _timers.keys():
		_timers[key] = 0.0
	if _visual_root != null and is_instance_valid(_visual_root):
		_visual_root.queue_free()
	_visual_root = null
	_shield_visuals_root = null
	_drone_visual = null
	_last_shield_visual_count = -1


func _tick_orbit_shields(delta: float) -> void:
	var buff_manager := _get_buff_manager()
	if buff_manager == null or not buff_manager.has_method("get_shield_charges") or not buff_manager.has_method("add_shield_charges"):
		return

	var max_charges := _get_orbit_shield_max_charges()
	if int(buff_manager.get_shield_charges()) >= max_charges:
		_timers["orbit_shields"] = 0.0
		return

	_timers["orbit_shields"] = maxf(float(_timers.get("orbit_shields", 0.0)) - delta, 0.0)
	if float(_timers["orbit_shields"]) > 0.0:
		return

	buff_manager.add_shield_charges(1)
	_timers["orbit_shields"] = _get_orbit_shield_regen_interval()
	_show_status("SHIELD")
	_last_event = "orbit_shields regenerated"


func _tick_storm_relay(delta: float) -> void:
	_timers["storm_relay"] = maxf(float(_timers.get("storm_relay", 0.0)) - delta, 0.0)
	if float(_timers["storm_relay"]) > 0.0:
		return

	var level := get_passive_level("storm_relay")
	if has_passive_evolution("death_dash_comet_path"):
		_tick_solar_storm(level)
		return

	var target := _find_nearest_enemy(_get_scaled_value("storm_relay", "range", level))
	if target == null:
		_timers["storm_relay"] = 0.35
		return

	var damage := int(_get_scaled_value("storm_relay", "damage", level))
	target.take_damage(damage)
	_spawn_arc(player.global_position, target.global_position, Color(0.35, 0.85, 1.0, 1.0), 5.0)
	_show_damage(damage, target.global_position)
	_show_status("STORM", target.global_position + Vector2.UP * 28.0)
	_timers["storm_relay"] = _get_scaled_value("storm_relay", "interval", level)
	_last_event = "storm_relay hit %s for %d" % [target.name, damage]


func _tick_guardian_drone(delta: float) -> void:
	_timers["guardian_drone"] = maxf(float(_timers.get("guardian_drone", 0.0)) - delta, 0.0)
	if float(_timers["guardian_drone"]) > 0.0:
		return

	var level := get_passive_level("guardian_drone")
	if has_passive_evolution("trap_marked_blast"):
		_tick_tactical_drone_swarm(level)
		return

	var target := _find_nearest_enemy(_get_scaled_value("guardian_drone", "range", level))
	if target == null:
		_timers["guardian_drone"] = 0.35
		return

	var damage := int(_get_scaled_value("guardian_drone", "damage", level))
	target.take_damage(damage)
	var origin := _get_drone_world_position()
	_spawn_arc(origin, target.global_position, Color(1.0, 0.9, 0.25, 1.0), 3.0)
	_show_damage(damage, target.global_position)
	_show_status("DRONE", target.global_position + Vector2.UP * 28.0)
	_timers["guardian_drone"] = _get_scaled_value("guardian_drone", "interval", level)
	_last_event = "guardian_drone hit %s for %d" % [target.name, damage]


func _tick_chain_lightning(delta: float) -> void:
	_timers["chain_lightning"] = maxf(float(_timers.get("chain_lightning", 0.0)) - delta, 0.0)
	if float(_timers["chain_lightning"]) > 0.0:
		return

	var level := get_passive_level("chain_lightning")
	if has_passive_evolution("hook_shadow_line"):
		_tick_shock_net(level)
		return

	var target := _find_nearest_enemy(_get_scaled_value("chain_lightning", "range", level))
	if target == null:
		_timers["chain_lightning"] = 0.35
		return

	var damage := int(_get_scaled_value("chain_lightning", "damage", level))
	var bounce_range := _get_scaled_value("chain_lightning", "bounce_range", level)
	var max_bounces := int(_get_scaled_value("chain_lightning", "bounces", level))
	var hit_targets: Array[Node2D] = []
	var origin := player.global_position
	var current := target

	for index in range(max_bounces):
		if current == null:
			break
		current.take_damage(damage)
		hit_targets.append(current)
		_spawn_arc(origin, current.global_position, Color(0.95, 0.95, 0.35, 1.0), 3.0)
		_show_damage(damage, current.global_position)
		origin = current.global_position
		current = _find_nearest_enemy_from(origin, bounce_range, hit_targets)

	_show_status("CHAIN x%d" % hit_targets.size(), target.global_position + Vector2.UP * 30.0)
	_timers["chain_lightning"] = _get_scaled_value("chain_lightning", "interval", level)
	_last_event = "chain_lightning bounced %d times" % hit_targets.size()


func _tick_recovery_field(delta: float) -> void:
	_timers["recovery_field"] = maxf(float(_timers.get("recovery_field", 0.0)) - delta, 0.0)
	if float(_timers["recovery_field"]) > 0.0:
		return

	var level := get_passive_level("recovery_field")
	if has_passive_evolution("death_dash_final_flash"):
		_tick_radiant_renewal(level)
		return

	var heal_amount := int(_get_scaled_value("recovery_field", "heal", level))
	if player != null and player.has_method("heal"):
		var previous_health := int(player.get("current_health") if player.get("current_health") != null else 0)
		player.heal(heal_amount)
		var current_health := int(player.get("current_health") if player.get("current_health") != null else previous_health)
		var actual_heal := maxi(current_health - previous_health, 0)
		if actual_heal > 0:
			_show_heal(actual_heal, player.global_position + Vector2.UP * 28.0)
			_last_event = "recovery_field healed %d" % actual_heal
		else:
			_last_event = "recovery_field pulsed"
	_show_recovery_pulse()
	_show_status("RECOVERY")
	_timers["recovery_field"] = _get_scaled_value("recovery_field", "interval", level)


func _tick_battle_focus(delta: float) -> void:
	_timers["battle_focus"] = maxf(float(_timers.get("battle_focus", 0.0)) - delta, 0.0)
	if float(_timers["battle_focus"]) > 0.0:
		return

	var level := get_passive_level("battle_focus")
	if has_passive_evolution("rage_leap_blood_crater"):
		_tick_berserker_focus(level)
		return

	var target := _find_nearest_enemy(_get_scaled_value("battle_focus", "range", level))
	if target == null:
		_timers["battle_focus"] = 0.35
		return

	var damage := int(_get_scaled_value("battle_focus", "damage", level))
	target.take_damage(damage)
	_show_damage(damage, target.global_position)
	_spawn_arc(player.global_position, target.global_position, Color(1.0, 0.45, 0.2, 1.0), 2.5)

	var buff_manager := _get_buff_manager()
	var duration := _get_scaled_value("battle_focus", "duration", level)
	if buff_manager != null and buff_manager.has_method("apply_named_attack_speed_boost"):
		buff_manager.apply_named_attack_speed_boost("battle_focus", _get_scaled_value("battle_focus", "attack_speed_multiplier", level), duration)
	_show_status("FOCUS %.0fs" % duration)
	_timers["battle_focus"] = _get_scaled_value("battle_focus", "interval", level)
	_last_event = "battle_focus hit %s and boosted speed" % target.name


func _tick_static_field(delta: float) -> void:
	_timers["static_field"] = maxf(float(_timers.get("static_field", 0.0)) - delta, 0.0)
	if float(_timers["static_field"]) > 0.0:
		return

	var level := get_passive_level("static_field")
	if has_passive_evolution("mighty_clap_rampage_impact"):
		_tick_rage_field(level)
		return

	var radius := _get_scaled_value("static_field", "radius", level)
	var damage := int(_get_scaled_value("static_field", "damage", level))
	var targets := _find_enemies_in_radius(player.global_position, radius)
	for enemy in targets:
		enemy.take_damage(damage)
		_show_damage(damage, enemy.global_position)
	_show_pulse_ring(player.global_position, radius, Color(0.25, 0.95, 1.0, 0.72), 0.24, 4.0)
	_show_status("STATIC %d" % targets.size())
	_timers["static_field"] = _get_scaled_value("static_field", "interval", level)
	_last_event = "static_field hit %d enemies" % targets.size()


func _tick_time_dilator(delta: float) -> void:
	_timers["time_dilator"] = maxf(float(_timers.get("time_dilator", 0.0)) - delta, 0.0)
	if float(_timers["time_dilator"]) > 0.0:
		return

	var level := get_passive_level("time_dilator")
	if has_passive_evolution("hook_rapid_abduction"):
		_tick_stasis_field(level)
		return

	var radius := _get_scaled_value("time_dilator", "radius", level)
	var slow_multiplier := _get_scaled_value("time_dilator", "slow_multiplier", level)
	var duration := _get_scaled_value("time_dilator", "duration", level)
	var targets := _find_enemies_in_radius(player.global_position, radius)
	for enemy in targets:
		if enemy.has_method("apply_temporary_modifier"):
			enemy.apply_temporary_modifier("time_dilator", {"speed_multiplier": slow_multiplier}, duration)
	_show_pulse_ring(player.global_position, radius, Color(0.65, 0.75, 1.0, 0.68), 0.32, 3.0)
	_show_status("SLOW %d" % targets.size())
	_timers["time_dilator"] = _get_scaled_value("time_dilator", "interval", level)
	_last_event = "time_dilator slowed %d enemies" % targets.size()


func _tick_solar_storm(level: int) -> void:
	var range_ := _get_scaled_value("storm_relay", "range", level) * 1.25
	var damage := int(_get_scaled_value("storm_relay", "damage", level) * 2.2)
	if _is_solar_empowered():
		damage = int(float(damage) * 1.75)
	var targets := _find_enemies_in_radius(player.global_position, range_)
	var max_targets := mini(targets.size(), SOLAR_STORM_MAX_TARGETS)
	if max_targets <= 0:
		_timers["storm_relay"] = 0.28
		return
	for index in range(max_targets):
		var enemy := targets[index]
		enemy.take_damage(damage)
		_spawn_arc(player.global_position, enemy.global_position, Color(1.0, 0.82, 0.22, 1.0), 5.5)
		_show_damage(damage, enemy.global_position)
		if enemy.has_method("apply_temporary_modifier"):
			enemy.apply_temporary_modifier("solar_storm_stagger", {"speed_multiplier": 0.65}, 0.8)
	_show_status("SOLAR STORM x%d" % max_targets)
	_show_pulse_ring(player.global_position, range_ * 0.35, Color(1.0, 0.72, 0.16, 0.72), 0.25, 4.5)
	_timers["storm_relay"] = maxf(_get_scaled_value("storm_relay", "interval", level) * 0.52, EVOLVED_PASSIVE_MIN_INTERVAL)
	_last_event = "solar_storm hit %d enemies" % max_targets


func _tick_tactical_drone_swarm(level: int) -> void:
	var range_ := _get_scaled_value("guardian_drone", "range", level) * 1.35
	var damage := int(_get_scaled_value("guardian_drone", "damage", level) * 2.0)
	var targets := _find_enemies_in_radius(player.global_position, range_)
	var max_targets := mini(targets.size(), DRONE_SWARM_MAX_TARGETS)
	if max_targets <= 0:
		_timers["guardian_drone"] = 0.25
		return
	for index in range(max_targets):
		var enemy := targets[index]
		enemy.take_damage(damage)
		_apply_tactical_mark(enemy)
		var orbit_offset := Vector2(cos(_orbit_time * 2.4 + float(index)), sin(_orbit_time * 2.4 + float(index))) * DRONE_VISUAL_RADIUS
		_spawn_arc(player.global_position + orbit_offset, enemy.global_position, Color(0.55, 0.9, 1.0, 1.0), 3.5)
		_show_damage(damage, enemy.global_position)
	_show_status("DRONE SWARM x%d" % max_targets)
	_timers["guardian_drone"] = maxf(_get_scaled_value("guardian_drone", "interval", level) * 0.55, EVOLVED_PASSIVE_MIN_INTERVAL)
	_last_event = "drone_swarm hit %d enemies" % max_targets


func _tick_shock_net(level: int) -> void:
	var range_ := _get_scaled_value("chain_lightning", "range", level) * 1.2
	var target := _find_marked_enemy(range_)
	if target == null:
		target = _find_nearest_enemy(range_)
	if target == null:
		_timers["chain_lightning"] = 0.28
		return
	var damage := int(_get_scaled_value("chain_lightning", "damage", level) * 2.0)
	var bounce_range := _get_scaled_value("chain_lightning", "bounce_range", level) * 1.35
	var max_bounces := mini(int(_get_scaled_value("chain_lightning", "bounces", level)) + 4, SHOCK_NET_MAX_BOUNCES)
	var hit_targets: Array[Node2D] = []
	var origin := player.global_position
	var current := target
	for index in range(max_bounces):
		if current == null:
			break
		var hit_damage := int(float(damage) * (1.35 if _is_tactically_marked(current) else 1.0))
		current.take_damage(hit_damage)
		_apply_tactical_mark(current)
		hit_targets.append(current)
		_spawn_arc(origin, current.global_position, Color(0.55, 1.0, 0.95, 1.0), 4.2)
		_show_damage(hit_damage, current.global_position)
		origin = current.global_position
		current = _find_marked_or_nearest_enemy_from(origin, bounce_range, hit_targets)
	_show_status("SHOCK NET x%d" % hit_targets.size())
	_timers["chain_lightning"] = maxf(_get_scaled_value("chain_lightning", "interval", level) * 0.58, EVOLVED_PASSIVE_MIN_INTERVAL)
	_last_event = "shock_net bounced %d times" % hit_targets.size()


func _tick_radiant_renewal(level: int) -> void:
	_trigger_radiant_renewal(level)
	_timers["recovery_field"] = maxf(_get_scaled_value("recovery_field", "interval", level) * 0.68, EVOLVED_PASSIVE_MIN_INTERVAL)


func _tick_berserker_focus(level: int) -> void:
	var rage_ratio := _get_rage_ratio()
	var range_ := _get_scaled_value("battle_focus", "range", level) * (1.3 + rage_ratio * 0.35)
	var damage := int(_get_scaled_value("battle_focus", "damage", level) * (2.8 + rage_ratio * 2.0))
	var targets := _find_enemies_in_radius(player.global_position, range_)
	var max_targets := mini(targets.size(), mini(1 + int(roundi(rage_ratio * 3.0)), BERSERKER_FOCUS_MAX_TARGETS))
	if max_targets <= 0:
		_timers["battle_focus"] = 0.28
		return
	for index in range(max_targets):
		var enemy := targets[index]
		enemy.take_damage(damage)
		_show_damage(damage, enemy.global_position)
		_spawn_arc(player.global_position, enemy.global_position, Color(1.0, 0.26, 0.08, 1.0), 4.0)
	var buff_manager := _get_buff_manager()
	var duration := _get_scaled_value("battle_focus", "duration", level) * (1.7 + rage_ratio)
	var speed_multiplier := _get_scaled_value("battle_focus", "attack_speed_multiplier", level) + 0.55 + rage_ratio * 0.45
	if buff_manager != null and buff_manager.has_method("apply_named_attack_speed_boost"):
		buff_manager.apply_named_attack_speed_boost("battle_focus", speed_multiplier, duration)
	_show_status("BERSERKER FOCUS")
	_timers["battle_focus"] = maxf(_get_scaled_value("battle_focus", "interval", level) * 0.62, EVOLVED_PASSIVE_MIN_INTERVAL)
	_last_event = "berserker_focus hit %d enemies" % max_targets


func _tick_rage_field(level: int) -> void:
	var rage_ratio := _get_rage_ratio()
	var radius := _get_scaled_value("static_field", "radius", level) * (1.35 + rage_ratio * 0.55)
	var damage := int(_get_scaled_value("static_field", "damage", level) * (2.5 + rage_ratio * 4.0))
	var targets := _find_enemies_in_radius(player.global_position, radius)
	for enemy in targets:
		enemy.take_damage(damage)
		if enemy.has_method("apply_temporary_modifier"):
			enemy.apply_temporary_modifier("rage_field_stagger", {"speed_multiplier": 0.55}, 0.75)
		_show_damage(damage, enemy.global_position)
	_show_rage_field_pulse(radius)
	_show_status("RAGE FIELD %d" % targets.size())
	_timers["static_field"] = maxf(_get_scaled_value("static_field", "interval", level) * (0.62 - rage_ratio * 0.22), EVOLVED_PASSIVE_MIN_INTERVAL)
	_last_event = "rage_field hit %d enemies" % targets.size()


func _tick_stasis_field(level: int) -> void:
	var radius := _get_scaled_value("time_dilator", "radius", level) * 1.45
	var duration := _get_scaled_value("time_dilator", "duration", level) * 1.45
	var targets := _find_enemies_in_radius(player.global_position, radius)
	for enemy in targets:
		var marked := _is_tactically_marked(enemy)
		if enemy.has_method("apply_temporary_modifier"):
			enemy.apply_temporary_modifier("stasis_field", {"speed_multiplier": 0.06 if marked else 0.16}, duration)
		_apply_tactical_mark(enemy)
	_show_stasis_field_pulse(radius)
	_show_status("STASIS FIELD %d" % targets.size())
	_timers["time_dilator"] = maxf(_get_scaled_value("time_dilator", "interval", level) * 0.52, EVOLVED_PASSIVE_MIN_INTERVAL)
	_last_event = "stasis_field slowed %d enemies" % targets.size()


func _tick_gravity_rage(delta: float) -> void:
	_timers["magnet_core"] = maxf(float(_timers.get("magnet_core", 0.0)) - delta, 0.0)
	if float(_timers["magnet_core"]) > 0.0:
		return
	var radius := 220.0 + _applied_pickup_radius_bonus
	var targets := _find_enemies_in_radius(player.global_position, radius)
	for enemy in targets:
		var pull_dir := (player.global_position - enemy.global_position).normalized()
		if enemy.has_method("apply_knockback") and not pull_dir.is_zero_approx():
			enemy.apply_knockback(pull_dir, 120.0)
		if enemy.has_method("apply_temporary_modifier"):
			enemy.apply_temporary_modifier("gravity_rage_pull", {"speed_multiplier": 0.55}, 0.8)
	_show_gravity_rage_pulse(radius)
	_show_status("GRAVITY RAGE" if not targets.is_empty() else "GRAVITY")
	_timers["magnet_core"] = maxf(3.2, GRAVITY_RAGE_MIN_INTERVAL)
	_last_event = "gravity_rage pulled %d enemies" % targets.size()


func _fill_orbit_shields() -> void:
	var buff_manager := _get_buff_manager()
	if buff_manager == null or not buff_manager.has_method("get_shield_charges") or not buff_manager.has_method("add_shield_charges"):
		return
	var missing := _get_orbit_shield_max_charges() - int(buff_manager.get_shield_charges())
	if missing > 0:
		buff_manager.add_shield_charges(missing)
	_timers["orbit_shields"] = _get_orbit_shield_regen_interval()
	_update_shield_visuals(true)


func _apply_magnet_core_bonus() -> void:
	if player == null or player.get("pickup_radius_bonus") == null:
		return
	var level := get_passive_level("magnet_core")
	var new_bonus := _get_scaled_value("magnet_core", "pickup_radius_bonus", level)
	if has_passive_evolution("rage_leap_final_impact"):
		new_bonus *= 2.6
	player.set("pickup_radius_bonus", float(player.get("pickup_radius_bonus")) - _applied_pickup_radius_bonus + new_bonus)
	_applied_pickup_radius_bonus = new_bonus
	_last_event = "magnet_core bonus %.0f" % _applied_pickup_radius_bonus


func _reset_magnet_core_bonus() -> void:
	if player == null or not is_instance_valid(player) or player.get("pickup_radius_bonus") == null:
		return
	player.set("pickup_radius_bonus", float(player.get("pickup_radius_bonus")) - _applied_pickup_radius_bonus)
	_applied_pickup_radius_bonus = 0.0


func _find_nearest_enemy(max_range: float) -> Node2D:
	if enemy_container == null or not is_instance_valid(enemy_container) or player == null:
		return null

	return _find_nearest_enemy_from(player.global_position, max_range, [])


func _find_nearest_enemy_from(origin: Vector2, max_range: float, excluded: Array[Node2D]) -> Node2D:
	if enemy_container == null or not is_instance_valid(enemy_container):
		return null

	var best: Node2D = null
	var best_distance_sq := max_range * max_range
	for enemy in enemy_container.get_children():
		if not _is_valid_enemy(enemy):
			continue
		var enemy_node := enemy as Node2D
		if excluded.has(enemy_node):
			continue
		var distance_sq := origin.distance_squared_to(enemy_node.global_position)
		if distance_sq <= best_distance_sq:
			best_distance_sq = distance_sq
			best = enemy_node
	return best


func _find_marked_enemy(max_range: float) -> Node2D:
	if enemy_container == null or not is_instance_valid(enemy_container) or player == null:
		return null
	var best: Node2D = null
	var best_distance_sq := max_range * max_range
	for enemy in enemy_container.get_children():
		if not _is_valid_enemy(enemy):
			continue
		var enemy_node := enemy as Node2D
		if not _is_tactically_marked(enemy_node):
			continue
		var distance_sq := player.global_position.distance_squared_to(enemy_node.global_position)
		if distance_sq <= best_distance_sq:
			best_distance_sq = distance_sq
			best = enemy_node
	return best


func _find_marked_or_nearest_enemy_from(origin: Vector2, max_range: float, excluded: Array[Node2D]) -> Node2D:
	if enemy_container == null or not is_instance_valid(enemy_container):
		return null
	var marked_best: Node2D = null
	var nearest_best: Node2D = null
	var marked_distance_sq := max_range * max_range
	var nearest_distance_sq := max_range * max_range
	for enemy in enemy_container.get_children():
		if not _is_valid_enemy(enemy):
			continue
		var enemy_node := enemy as Node2D
		if excluded.has(enemy_node):
			continue
		var distance_sq := origin.distance_squared_to(enemy_node.global_position)
		if distance_sq > max_range * max_range:
			continue
		if _is_tactically_marked(enemy_node) and distance_sq <= marked_distance_sq:
			marked_distance_sq = distance_sq
			marked_best = enemy_node
		if distance_sq <= nearest_distance_sq:
			nearest_distance_sq = distance_sq
			nearest_best = enemy_node
	return marked_best if marked_best != null else nearest_best


func _find_enemies_in_radius(origin: Vector2, radius: float) -> Array[Node2D]:
	var enemies: Array[Node2D] = []
	if enemy_container == null or not is_instance_valid(enemy_container):
		return enemies
	var radius_sq := radius * radius
	for enemy in enemy_container.get_children():
		if not _is_valid_enemy(enemy):
			continue
		var enemy_node := enemy as Node2D
		if origin.distance_squared_to(enemy_node.global_position) <= radius_sq:
			enemies.append(enemy_node)
	return enemies


func _setup_visual_root() -> void:
	if player == null or not is_instance_valid(player):
		return
	if _visual_root != null and is_instance_valid(_visual_root):
		return
	_visual_root = Node2D.new()
	_visual_root.name = "PassiveAbilityVisuals"
	_visual_root.z_index = 20
	player.add_child(_visual_root)

	_shield_visuals_root = Node2D.new()
	_shield_visuals_root.name = "OrbitShieldVisuals"
	_visual_root.add_child(_shield_visuals_root)


func _connect_buff_manager() -> void:
	var buff_manager := _get_buff_manager()
	if buff_manager == null or not buff_manager.has_signal("shield_changed"):
		return
	if not buff_manager.shield_changed.is_connected(_on_shield_changed):
		buff_manager.shield_changed.connect(_on_shield_changed)
	if buff_manager.has_method("get_shield_charges"):
		_last_known_shield_charges = int(buff_manager.get_shield_charges())


func _on_shield_changed(charges: int) -> void:
	if has_passive_evolution("frost_breath_permafrost") and charges < _last_known_shield_charges and player != null:
		_trigger_solar_aegis_explosion(player.global_position)
	_last_known_shield_charges = charges
	_update_shield_visuals(true)


func _update_passive_visuals() -> void:
	if _visual_root == null or not is_instance_valid(_visual_root):
		_setup_visual_root()
	_update_shield_visuals(false)
	_update_drone_visual()


func _update_shield_visuals(force: bool) -> void:
	if _shield_visuals_root == null or not is_instance_valid(_shield_visuals_root):
		return
	var charges := _get_current_shield_charges()
	if force or charges != _last_shield_visual_count:
		for child in _shield_visuals_root.get_children():
			child.queue_free()
		for index in range(charges):
			_shield_visuals_root.add_child(_create_orbit_marker("ShieldCharge%d" % index, Color(0.2, 0.7, 1.0, 0.9), SHIELD_VISUAL_SIZE))
		_last_shield_visual_count = charges

	var children := _shield_visuals_root.get_children()
	var count := children.size()
	if count <= 0:
		return
	for index in range(count):
		var marker := children[index] as Node2D
		if marker == null:
			continue
		var angle := _orbit_time * 2.4 + TAU * float(index) / float(count)
		marker.position = Vector2(cos(angle), sin(angle)) * SHIELD_VISUAL_RADIUS


func _ensure_drone_visual() -> void:
	if _visual_root == null or not is_instance_valid(_visual_root):
		_setup_visual_root()
	if _visual_root == null:
		return
	if _drone_visual != null and is_instance_valid(_drone_visual):
		return
	_drone_visual = _create_orbit_marker("GuardianDroneVisual", Color(1.0, 0.85, 0.25, 0.95), 10.0)
	_visual_root.add_child(_drone_visual)


func _update_drone_visual() -> void:
	if not has_passive("guardian_drone"):
		if _drone_visual != null and is_instance_valid(_drone_visual):
			_drone_visual.queue_free()
		_drone_visual = null
		return
	_ensure_drone_visual()
	if _drone_visual == null or not is_instance_valid(_drone_visual):
		return
	var angle := -_orbit_time * 1.8
	_drone_visual.position = Vector2(cos(angle), sin(angle)) * DRONE_VISUAL_RADIUS


func _create_orbit_marker(marker_name: String, color: Color, size: float) -> Node2D:
	var marker := Node2D.new()
	marker.name = marker_name
	var body := Polygon2D.new()
	body.polygon = _make_circle_polygon(size, 14)
	body.color = color
	marker.add_child(body)
	var ring := Line2D.new()
	ring.width = 1.5
	ring.default_color = Color(color.r, color.g, color.b, 0.55)
	for point in _make_circle_polygon(size + 3.0, 18):
		ring.add_point(point)
	ring.add_point(Vector2(size + 3.0, 0.0))
	marker.add_child(ring)
	return marker


func _make_circle_polygon(radius: float, sides: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(sides):
		var angle := TAU * float(index) / float(sides)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _spawn_arc(from_position: Vector2, to_position: Vector2, color: Color, width: float) -> void:
	var parent := _get_world_visual_parent()
	if parent == null:
		return
	var line := Line2D.new()
	line.name = "PassiveHitArc"
	line.width = width
	line.default_color = color
	line.z_index = 30
	var midpoint := from_position.lerp(to_position, 0.5)
	var normal := (to_position - from_position).orthogonal().normalized()
	if normal.is_zero_approx():
		normal = Vector2.UP
	line.add_point(from_position)
	line.add_point(midpoint + normal * 18.0)
	line.add_point(to_position)
	parent.add_child(line)
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, ARC_DURATION)
	tween.finished.connect(line.queue_free)


func _show_magnet_feedback() -> void:
	if player == null:
		return
	_show_status("MAGNET +%.0f" % _applied_pickup_radius_bonus)
	var parent := _get_world_visual_parent()
	if parent == null:
		return
	var ring := Line2D.new()
	ring.name = "MagnetCorePulse"
	ring.width = 3.0
	ring.default_color = Color(0.75, 0.25, 1.0, 0.7)
	ring.z_index = 25
	var radius := 55.0 + _applied_pickup_radius_bonus * 0.25
	for point in _make_circle_polygon(radius, 36):
		ring.add_point(player.global_position + point)
	ring.add_point(player.global_position + Vector2(radius, 0.0))
	parent.add_child(ring)
	var tween := ring.create_tween()
	tween.parallel().tween_property(ring, "scale", Vector2(1.25, 1.25), 0.25)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.25)
	tween.finished.connect(ring.queue_free)


func _show_recovery_pulse() -> void:
	if player == null:
		return
	var level := maxi(get_passive_level("recovery_field"), 1)
	_show_pulse_ring(player.global_position, _get_scaled_value("recovery_field", "radius", level), Color(0.35, 1.0, 0.55, 0.75), 0.3, 3.0)


func _trigger_solar_aegis_explosion(world_position: Vector2) -> void:
	if world_position == Vector2.ZERO and player != null:
		world_position = player.global_position
	var level := maxi(get_passive_level("orbit_shields"), 1)
	var radius := 175.0 + level * 35.0
	var damage := 28 + level * 18
	var targets := _find_enemies_in_radius(world_position, radius)
	for enemy in targets:
		enemy.take_damage(damage)
		if enemy.has_method("apply_temporary_modifier"):
			enemy.apply_temporary_modifier("solar_aegis_slow", {"speed_multiplier": 0.42}, 1.15)
		if enemy.has_method("apply_knockback"):
			var knock_dir := (enemy.global_position - world_position).normalized()
			if not knock_dir.is_zero_approx():
				enemy.apply_knockback(knock_dir, 150.0)
		_show_damage(damage, enemy.global_position)
	_show_pulse_ring(world_position, radius, Color(1.0, 0.78, 0.18, 0.86), 0.34, 5.5)
	_show_status("SOLAR AEGIS", world_position + Vector2.UP * 46.0)
	_last_event = "solar_aegis exploded on %d enemies" % targets.size()


func _trigger_radiant_renewal(level: int = 0) -> void:
	if player == null:
		return
	if level <= 0:
		level = maxi(get_passive_level("recovery_field"), 1)
	var heal_amount := int(_get_scaled_value("recovery_field", "heal", level) * 2.4)
	if player.has_method("heal"):
		var previous_health := int(player.get("current_health") if player.get("current_health") != null else 0)
		player.heal(heal_amount)
		var current_health := int(player.get("current_health") if player.get("current_health") != null else previous_health)
		var actual_heal := maxi(current_health - previous_health, 0)
		if actual_heal > 0:
			_show_heal(actual_heal, player.global_position + Vector2.UP * 28.0)
	var radius := _get_scaled_value("recovery_field", "radius", level) * 2.0
	var damage := heal_amount * 2
	var targets := _find_enemies_in_radius(player.global_position, radius)
	for enemy in targets:
		enemy.take_damage(damage)
		_show_damage(damage, enemy.global_position)
	_apply_radiant_reduction(0.35, 3.5)
	_show_pulse_ring(player.global_position, radius, Color(0.9, 1.0, 0.36, 0.84), 0.38, 5.0)
	_show_status("RADIANT RENEWAL")
	_last_event = "radiant_renewal hit %d enemies" % targets.size()


func _apply_radiant_reduction(value: float, duration: float) -> void:
	_radiant_reduction_value = value
	_radiant_reduction_time_left = duration
	if player != null and player.get("damage_reduction") != null:
		player.set("damage_reduction", maxf(float(player.get("damage_reduction")), value))


func _tick_radiant_reduction(delta: float) -> void:
	if _radiant_reduction_time_left <= 0.0:
		return
	_radiant_reduction_time_left = maxf(_radiant_reduction_time_left - delta, 0.0)
	if _radiant_reduction_time_left <= 0.0:
		_clear_radiant_reduction()


func _clear_radiant_reduction() -> void:
	if player != null and is_instance_valid(player) and player.get("damage_reduction") != null:
		if float(player.get("damage_reduction")) <= _radiant_reduction_value + 0.01:
			player.set("damage_reduction", 0.0)
	_radiant_reduction_time_left = 0.0
	_radiant_reduction_value = 0.0


func _show_drone_swarm_burst() -> void:
	if player == null:
		return
	for index in range(3):
		var angle := TAU * float(index) / 3.0
		_show_pulse_ring(player.global_position + Vector2(cos(angle), sin(angle)) * 38.0, 24.0, Color(0.55, 0.9, 1.0, 0.76), 0.24, 2.5)
	_show_status("DRONE SWARM")


func _show_rage_field_pulse(radius: float = 0.0) -> void:
	if player == null:
		return
	if radius <= 0.0:
		radius = _get_scaled_value("static_field", "radius", maxi(get_passive_level("static_field"), 1)) * 1.4
	_show_pulse_ring(player.global_position, radius, Color(1.0, 0.22, 0.08, 0.78), 0.30, 5.0)


func _show_stasis_field_pulse(radius: float = 0.0) -> void:
	if player == null:
		return
	if radius <= 0.0:
		radius = _get_scaled_value("time_dilator", "radius", maxi(get_passive_level("time_dilator"), 1)) * 1.45
	_show_pulse_ring(player.global_position, radius, Color(0.42, 0.85, 1.0, 0.76), 0.36, 4.5)


func _show_gravity_rage_pulse(radius: float = 0.0) -> void:
	if player == null:
		return
	if radius <= 0.0:
		radius = 120.0 + _applied_pickup_radius_bonus
	_show_pulse_ring(player.global_position, radius, Color(0.78, 0.24, 1.0, 0.78), 0.34, 4.5)


func _show_pulse_ring(center: Vector2, radius: float, color: Color, duration: float, width: float) -> void:
	var parent := _get_world_visual_parent()
	if parent == null:
		return
	var ring := Line2D.new()
	ring.name = "PassivePulse"
	ring.width = width
	ring.default_color = color
	ring.z_index = 24
	ring.global_position = center
	for point in _make_circle_polygon(radius, 40):
		ring.add_point(point)
	ring.add_point(Vector2(radius, 0.0))
	parent.add_child(ring)
	var tween := ring.create_tween()
	tween.parallel().tween_property(ring, "scale", Vector2(1.18, 1.18), duration)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, duration)
	tween.finished.connect(ring.queue_free)


func _get_current_shield_charges() -> int:
	var buff_manager := _get_buff_manager()
	if buff_manager != null and buff_manager.has_method("get_shield_charges"):
		return int(buff_manager.get_shield_charges())
	return 0


func _get_drone_world_position() -> Vector2:
	if _drone_visual != null and is_instance_valid(_drone_visual):
		return _drone_visual.global_position
	if player != null:
		return player.global_position
	return Vector2.ZERO


func _get_world_visual_parent() -> Node:
	if player != null and is_instance_valid(player) and player.get_parent() != null:
		return player.get_parent()
	if get_parent() != null:
		return get_parent()
	return get_tree().current_scene


func _is_valid_enemy(node: Node) -> bool:
	return (
		node is Node2D
		and is_instance_valid(node)
		and not node.is_queued_for_deletion()
		and node.has_method("take_damage")
	)


func _get_buff_manager() -> Node:
	if player == null or not is_instance_valid(player):
		return null
	return player.get_node_or_null("PlayerBuffManager")


func _get_orbit_shield_max_charges() -> int:
	var charges := int(_get_scaled_value("orbit_shields", "max_charges", get_passive_level("orbit_shields")))
	if has_passive_evolution("frost_breath_permafrost"):
		charges += 2
	return charges


func _get_orbit_shield_regen_interval() -> float:
	var interval := _get_scaled_value("orbit_shields", "regen_interval", get_passive_level("orbit_shields"))
	if has_passive_evolution("frost_breath_permafrost"):
		interval *= 0.45
	return interval


func _get_scaled_value(passive_id: String, key: String, level: int) -> float:
	var definition: Dictionary = PASSIVE_DEFINITIONS.get(passive_id, {})
	var value = definition.get(key, 0.0)
	if value is Array:
		var values := value as Array
		if values.is_empty():
			return 0.0
		return float(values[clampi(level - 1, 0, values.size() - 1)])
	return float(value)


func _get_max_level(passive_id: String) -> int:
	var definition: Dictionary = PASSIVE_DEFINITIONS.get(passive_id, {})
	var max_level := 1
	for value in definition.values():
		if value is Array:
			max_level = maxi(max_level, (value as Array).size())
	return max_level


func _get_display_name(passive_id: String) -> String:
	var definition: Dictionary = PASSIVE_DEFINITIONS.get(passive_id, {})
	return str(definition.get("display_name", passive_id))


func _get_ability_manager() -> Node:
	if player != null and is_instance_valid(player):
		var player_ability_manager := player.get_node_or_null("AbilityManager")
		if player_ability_manager != null:
			return player_ability_manager
	if get_parent() == null:
		return null
	return get_parent().get_node_or_null("AbilityManager")


func _is_solar_empowered() -> bool:
	var ability_manager := _get_ability_manager()
	return ability_manager != null and ability_manager.has_method("is_solar_empowered") and bool(ability_manager.is_solar_empowered())


func _get_rage_ratio() -> float:
	var ability_manager := _get_ability_manager()
	if ability_manager != null and ability_manager.has_method("get_rage_state"):
		var rage_state: Dictionary = ability_manager.get_rage_state()
		if rage_state.has("rage_ratio"):
			return clampf(float(rage_state.get("rage_ratio", 0.0)), 0.0, 1.0)
		var max_rage := float(rage_state.get("rage_max", 0.0))
		if max_rage > 0.0:
			return clampf(float(rage_state.get("rage", 0.0)) / max_rage, 0.0, 1.0)
	return 0.0


func _apply_tactical_mark(enemy: Node) -> void:
	var ability_manager := _get_ability_manager()
	if ability_manager != null and ability_manager.has_method("apply_tactical_mark"):
		ability_manager.apply_tactical_mark(enemy)


func _is_tactically_marked(enemy: Node) -> bool:
	var ability_manager := _get_ability_manager()
	return ability_manager != null and ability_manager.has_method("is_tactically_marked") and bool(ability_manager.is_tactically_marked(enemy))


func _is_known_passive_evolution(evolution_id: String, target_id: String) -> bool:
	return _get_passive_evolution_target(evolution_id) == target_id


func _get_passive_evolution_target(evolution_id: String) -> String:
	match evolution_id:
		"frost_breath_permafrost":
			return "orbit_shields"
		"death_dash_comet_path":
			return "storm_relay"
		"death_dash_final_flash":
			return "recovery_field"
		"trap_marked_blast":
			return "guardian_drone"
		"hook_shadow_line":
			return "chain_lightning"
		"hook_rapid_abduction":
			return "time_dilator"
		"mighty_clap_rampage_impact":
			return "static_field"
		"rage_leap_blood_crater":
			return "battle_focus"
		"rage_leap_final_impact":
			return "magnet_core"
	return ""


func _get_passive_evolution_status(evolution_id: String) -> String:
	match evolution_id:
		"frost_breath_permafrost":
			return "SOLAR AEGIS"
		"death_dash_comet_path":
			return "SOLAR STORM"
		"death_dash_final_flash":
			return "RADIANT RENEWAL"
		"trap_marked_blast":
			return "DRONE SWARM"
		"hook_shadow_line":
			return "SHOCK NET"
		"hook_rapid_abduction":
			return "STASIS FIELD"
		"mighty_clap_rampage_impact":
			return "RAGE FIELD"
		"rage_leap_blood_crater":
			return "BERSERKER FOCUS"
		"rage_leap_final_impact":
			return "GRAVITY RAGE"
	return "PASSIVE EVOLUTION"


func _get_passive_evolution_titles() -> Array[String]:
	var titles: Array[String] = []
	for evolution_id in _selected_passive_evolutions:
		titles.append(_get_passive_evolution_status(evolution_id).capitalize())
	return titles


func _show_damage(amount: int, world_position: Vector2) -> void:
	if feedback_manager != null and feedback_manager.has_method("show_damage"):
		feedback_manager.show_damage(amount, world_position)


func _show_heal(amount: int, world_position: Vector2) -> void:
	if feedback_manager != null and feedback_manager.has_method("show_heal"):
		feedback_manager.show_heal(amount, world_position)


func _show_status(text: String, world_position: Vector2 = STATUS_SENTINEL) -> void:
	if feedback_manager == null or not feedback_manager.has_method("show_status"):
		return
	var position := world_position
	if position == STATUS_SENTINEL and player != null:
		position = player.global_position + Vector2.UP * 42.0
	feedback_manager.show_status(text, position)
