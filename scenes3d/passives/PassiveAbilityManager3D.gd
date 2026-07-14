class_name PassiveAbilityManager3D
extends Node

## Legacy pixels use the established 40 pixels = 1 world-unit migration rule.
const PIXELS_PER_WORLD_UNIT := 40.0
const LEGACY_BASE_MAGNET_RADIUS_PIXELS := 140.0
const LEGACY_MAGNET_SPEED_PIXELS_PER_SECOND := 420.0
const MAGNET_ATTRACTION_SPEED := LEGACY_MAGNET_SPEED_PIXELS_PER_SECOND / PIXELS_PER_WORLD_UNIT
const PICKUP_SCAN_INTERVAL := 0.25
const PASSIVE_PULSE_EFFECT := preload("res://scenes3d/effects/PassivePulseEffect3D.tscn")
const PASSIVE_ARC_EFFECT := preload("res://scenes3d/effects/PassiveArcEffect3D.tscn")
const GUARDIAN_DRONE_VISUAL := preload("res://scenes3d/passives/GuardianDroneVisual3D.tscn")
const ORBIT_SHIELD_VISUAL := preload("res://scenes3d/passives/OrbitShieldVisual3D.tscn")
const RAGE_FIELD_EVOLUTION_ID := "mighty_clap_rampage_impact"
const BERSERKER_FOCUS_EVOLUTION_ID := "rage_leap_blood_crater"
const GRAVITY_RAGE_EVOLUTION_ID := "rage_leap_final_impact"
const RAGE_FIELD_SLOW := {"movement_speed_multiplier": 0.55}
const RAGE_FIELD_SLOW_DURATION := 0.75
const RAGE_FIELD_MIN_INTERVAL := 0.85
const GUARDIAN_DRONE_NO_TARGET_RETRY := 0.35
const GRAVITY_RAGE_INTERVAL := 3.2
const GRAVITY_RAGE_PULL_FORCE := 3.0
const GRAVITY_RAGE_PULL_DURATION := 0.22
const GRAVITY_RAGE_SLOW_DURATION := 0.8
const GRAVITY_RAGE_BONUS_MULTIPLIER := 2.6
const GRAVITY_RAGE_SLOW := {"movement_speed_multiplier": 0.55}
const ORBIT_SHIELD_UI_REFRESH_INTERVAL := 0.25
const PASSIVE_DEFINITIONS: Dictionary = {
	"static_field": {"title": "Static Field", "max_level": 5, "damage": [5, 6, 7, 8, 9], "interval": [4.8, 4.5, 4.2, 3.9, 3.6], "radius": [150.0, 162.5, 175.0, 187.5, 200.0]},
	"battle_focus": {"title": "Battle Focus", "max_level": 5, "damage": [4, 5, 6, 7, 8], "interval": [7.5, 7.0, 6.5, 6.0, 5.5], "range": 420.0, "attack_speed_multiplier": [1.12, 1.15, 1.18, 1.21, 1.24], "duration": [3.0, 3.25, 3.5, 3.75, 4.0]},
	"recovery_field": {"title": "Recovery Field", "max_level": 5, "heal": [4, 5, 6, 7, 8], "interval": [12.0, 11.25, 10.5, 9.75, 9.0], "radius": [80.0, 87.5, 95.0, 102.5, 110.0]},
	"magnet_core": {"title": "Magnet Core", "max_level": 5, "pickup_radius_bonus": [45.0, 65.0, 85.0, 105.0, 125.0]},
	"guardian_drone": {"title": "Guardian Drone", "max_level": 5, "damage": [5, 6, 8, 9, 11], "interval": [3.4, 3.2, 3.0, 2.8, 2.6], "range": 460.0},
	"orbit_shields": {"title": "Orbit Shields", "max_level": 5, "maximum_charges": [1, 1, 1, 2, 2], "interval": [18.0, 16.5, 15.0, 13.5, 12.0]},
	"storm_relay": {"title": "Storm Relay", "max_level": 5, "damage": [8, 10, 12, 14, 16], "interval": [5.5, 5.15, 4.8, 4.5, 4.2], "range": 520.0},
	"chain_lightning": {"title": "Chain Lightning", "max_level": 5, "damage": [6, 7, 9, 10, 12], "interval": [6.6, 6.2, 5.8, 5.4, 5.0], "initial_range": 500.0, "bounce_range": [210.0, 225.0, 240.0, 255.0, 270.0], "maximum_targets": [2, 2, 3, 3, 4]},
	"time_dilator": {"title": "Time Dilator", "max_level": 5, "interval": [8.5, 8.0, 7.5, 7.0, 6.5], "radius": [190.0, 205.0, 220.0, 235.0, 250.0], "movement_speed_multiplier": [0.72, 0.68, 0.64, 0.60, 0.56], "duration": [2.5, 2.75, 3.0, 3.25, 3.5]},
}

signal passive_changed(passive_id: String, level: int)
signal passive_state_changed
signal passive_triggered(passive_id: String, data: Dictionary)

var _player: Player3D
var _auto_attack: Node
var _ability_manager: Node
var _enemy_container: Node3D
var _pickup_container: Node3D
var _effect_container: Node3D
var _levels: Dictionary = {}
var _timers: Dictionary = {"static_field": 0.0, "battle_focus": 0.0, "recovery_field": 0.0, "guardian_drone": 0.0, "magnet_core": 0.0, "orbit_shields": 0.0, "storm_relay": 0.0, "chain_lightning": 0.0, "time_dilator": 0.0}
var _pickup_scan_remaining := 0.0
var _orbit_shield_ui_refresh_remaining := 0.0
var _stopped := false
var _selected_passive_evolutions: Array[String] = []
var _passive_evolution_targets: Dictionary = {}
var _guardian_drone_visual: Node3D
var _orbit_shield_visual: Node3D


func setup(player: Player3D, auto_attack: Node, ability_manager: Node, enemy_container: Node3D, pickup_container: Node3D, effect_container: Node3D) -> void:
	_disconnect_player_shield_signals()
	_player = player
	_auto_attack = auto_attack
	_ability_manager = ability_manager
	_enemy_container = enemy_container
	_pickup_container = pickup_container
	_effect_container = effect_container
	reset_run_state()
	if not _player.shield_changed.is_connected(_on_player_shield_changed):
		_player.shield_changed.connect(_on_player_shield_changed)
	if not _player.shield_blocked.is_connected(_on_player_shield_blocked):
		_player.shield_blocked.connect(_on_player_shield_blocked)


func _process(delta: float) -> void:
	if _stopped or get_tree().paused or _player == null or not is_instance_valid(_player) or _player.is_dead():
		if _player == null or not is_instance_valid(_player):
			_remove_guardian_drone_visual()
			_remove_orbit_shield_visual()
		return
	if has_passive("static_field"):
		_tick_static_field(delta)
	if has_passive("battle_focus"):
		_tick_battle_focus(delta)
	if has_passive("recovery_field"):
		_tick_recovery_field(delta)
	if has_passive("magnet_core"):
		_tick_magnet_core(delta)
		if has_passive_evolution(GRAVITY_RAGE_EVOLUTION_ID):
			_tick_gravity_rage(delta)
	if has_passive("guardian_drone"):
		_tick_guardian_drone(delta)
	if has_passive("orbit_shields"):
		_tick_orbit_shields(delta)
		_tick_orbit_shield_ui_refresh(delta)
	if has_passive("storm_relay"):
		_tick_storm_relay(delta)
	if has_passive("chain_lightning"):
		_tick_chain_lightning(delta)
	if has_passive("time_dilator"):
		_tick_time_dilator(delta)


func add_or_upgrade_passive(passive_id: String) -> bool:
	if not PASSIVE_DEFINITIONS.has(passive_id):
		return false
	var previous_level := get_passive_level(passive_id)
	if previous_level >= get_passive_max_level(passive_id):
		return false
	var next_level := previous_level + 1
	_levels[passive_id] = next_level
	if passive_id in _timers and previous_level == 0:
		_timers[passive_id] = 0.0
	if passive_id == "magnet_core":
		_spawn_pulse(_player.global_position, _get_effective_magnet_radius(next_level), 0.28, Color(0.34, 0.95, 0.62, 0.68), 0.76)
	elif passive_id == "static_field":
		_spawn_pulse(_player.global_position, _world_value("static_field", "radius", next_level), 0.24, Color(0.25, 0.95, 1.0, 0.72), 0.70)
	elif passive_id == "recovery_field":
		_spawn_pulse(_player.global_position, _world_value("recovery_field", "radius", next_level), 0.25, Color(0.24, 1.0, 0.48, 0.72), 0.68)
	elif passive_id == "guardian_drone":
		_ensure_guardian_drone_visual()
	elif passive_id == "orbit_shields":
		_configure_orbit_shields(previous_level, next_level)
	passive_changed.emit(passive_id, next_level)
	passive_state_changed.emit()
	return true


func get_passive_level(passive_id: String) -> int:
	return int(_levels.get(passive_id, 0))


func get_passive_max_level(passive_id: String) -> int:
	return int(PASSIVE_DEFINITIONS.get(passive_id, {}).get("max_level", 0))


func get_passive_level_summary(passive_id: String, level: int) -> String:
	return _format_passive_values(passive_id, 0, level)


func get_passive_level_comparison(passive_id: String, current_level: int, next_level: int) -> String:
	return _format_passive_values(passive_id, current_level, next_level)


func get_passive_definition_validation_errors() -> Array[String]:
	var errors: Array[String] = []
	for passive_id: String in PASSIVE_DEFINITIONS:
		var definition: Dictionary = PASSIVE_DEFINITIONS[passive_id]
		if int(definition.get("max_level", 0)) != 5:
			errors.append("%s must have max_level 5." % passive_id)
		for key: String in definition:
			var value = definition[key]
			if value is Array and value.size() != 5:
				errors.append("%s.%s must contain five values." % [passive_id, key])
	return errors


func has_passive(passive_id: String) -> bool:
	return get_passive_level(passive_id) > 0


func get_passive_state(passive_id: String) -> Dictionary:
	var definition: Dictionary = PASSIVE_DEFINITIONS.get(passive_id, {})
	if definition.is_empty():
		return {}
	var level := get_passive_level(passive_id)
	var state := {"id": passive_id, "title": _get_passive_display_title(passive_id), "level": level, "max_level": get_passive_max_level(passive_id), "selected": has_passive(passive_id), "timer_remaining": float(_timers.get(passive_id, 0.0)), "selected_passive_evolution_ids": get_selected_passive_evolution_ids(), "selected_passive_evolution_titles": get_selected_passive_evolution_titles()}
	if passive_id == "magnet_core":
		state["pickup_radius_bonus_pixels"] = _get_magnet_bonus_pixels(level)
		state["original_level_bonus_pixels"] = _get_magnet_bonus_pixels(level)
		state["evolved_bonus_multiplier"] = _get_magnet_bonus_multiplier()
		state["effective_bonus_pixels"] = _get_effective_magnet_bonus_pixels(level)
		state["base_magnet_radius_pixels"] = LEGACY_BASE_MAGNET_RADIUS_PIXELS
		state["effective_pickup_radius"] = _get_effective_magnet_radius(level)
		state["attraction_speed"] = MAGNET_ATTRACTION_SPEED
		state["gravity_rage_active"] = has_passive_evolution(GRAVITY_RAGE_EVOLUTION_ID)
	if passive_id == "orbit_shields":
		var current_charges := _player.get_shield_charges() if _player != null and is_instance_valid(_player) else 0
		var maximum_charges := _player.get_maximum_shield_charges() if _player != null and is_instance_valid(_player) else 0
		state["current_charges"] = current_charges
		state["maximum_charges"] = maximum_charges
		state["regeneration_interval"] = _value("orbit_shields", "interval", level)
		state["remaining_regeneration_time"] = float(_timers.get("orbit_shields", 0.0))
		state["is_full"] = current_charges >= maximum_charges
		state["blocked_hit_count"] = _player.get_shield_block_count() if _player != null and is_instance_valid(_player) else 0
	if passive_id == "storm_relay":
		state["damage"] = int(_value("storm_relay", "damage", level))
		state["interval"] = _value("storm_relay", "interval", level)
		state["range"] = _world_value("storm_relay", "range", level)
	if passive_id == "chain_lightning":
		state["damage"] = int(_value("chain_lightning", "damage", level))
		state["interval"] = _value("chain_lightning", "interval", level)
		state["initial_range"] = _world_value("chain_lightning", "initial_range", level)
		state["bounce_range"] = _world_value("chain_lightning", "bounce_range", level)
		state["maximum_targets"] = int(_value("chain_lightning", "maximum_targets", level))
	if passive_id == "time_dilator":
		state["interval"] = _value("time_dilator", "interval", level)
		state["radius"] = _world_value("time_dilator", "radius", level)
		state["movement_speed_multiplier"] = _value("time_dilator", "movement_speed_multiplier", level)
		state["duration"] = _value("time_dilator", "duration", level)
	return state


func get_all_passive_states() -> Dictionary:
	var states: Dictionary = {}
	for passive_id: String in PASSIVE_DEFINITIONS:
		states[passive_id] = get_passive_state(passive_id)
	return states


func get_selected_passive_ids() -> Array[String]:
	var selected: Array[String] = []
	for passive_id: String in PASSIVE_DEFINITIONS:
		if has_passive(passive_id):
			selected.append(passive_id)
	return selected


func get_selected_passive_titles() -> Array[String]:
	var titles: Array[String] = []
	for passive_id: String in get_selected_passive_ids():
		titles.append(_get_passive_display_title(passive_id))
	return titles


func can_apply_passive_evolution(evolution_id: String, target_passive_id: String) -> bool:
	return (evolution_id == RAGE_FIELD_EVOLUTION_ID and target_passive_id == "static_field" and has_passive("static_field")) or (evolution_id == BERSERKER_FOCUS_EVOLUTION_ID and target_passive_id == "battle_focus" and has_passive("battle_focus")) or (evolution_id == GRAVITY_RAGE_EVOLUTION_ID and target_passive_id == "magnet_core" and has_passive("magnet_core"))


func apply_passive_evolution(evolution_id: String, target_passive_id: String) -> bool:
	if not can_apply_passive_evolution(evolution_id, target_passive_id):
		return false
	if evolution_id in _selected_passive_evolutions:
		return true
	_selected_passive_evolutions.append(evolution_id)
	_passive_evolution_targets[evolution_id] = target_passive_id
	if evolution_id == RAGE_FIELD_EVOLUTION_ID:
		_spawn_pulse(_player.global_position, _world_value("static_field", "radius", get_passive_level("static_field")) * 1.35, 0.28, Color(1.0, 0.24, 0.05, 0.76), 0.52)
	elif evolution_id == BERSERKER_FOCUS_EVOLUTION_ID:
		_spawn_pulse(_player.global_position, 1.3, 0.22, Color(1.0, 0.16, 0.04, 0.78), 0.55)
	else:
		_timers["magnet_core"] = 0.2
		_spawn_pulse(_player.global_position, _get_effective_magnet_radius(get_passive_level("magnet_core")), 0.18, Color(0.72, 0.34, 1.0, 0.88), 0.35)
	passive_state_changed.emit()
	return true


func has_passive_evolution(evolution_id: String) -> bool:
	return evolution_id in _selected_passive_evolutions


func get_selected_passive_evolution_ids() -> Array[String]:
	return _selected_passive_evolutions.duplicate()


func get_selected_passive_evolution_titles() -> Array[String]:
	var titles: Array[String] = []
	for evolution_id: String in _selected_passive_evolutions:
		if evolution_id == RAGE_FIELD_EVOLUTION_ID:
			titles.append("Rage Field")
		elif evolution_id == BERSERKER_FOCUS_EVOLUTION_ID:
			titles.append("Berserker Focus")
		elif evolution_id == GRAVITY_RAGE_EVOLUTION_ID:
			titles.append("Gravity Rage")
	return titles


func reset_run_state() -> void:
	if _auto_attack != null:
		_auto_attack.clear_temporary_attack_speed_modifier("battle_focus")
	_levels.clear()
	_selected_passive_evolutions.clear()
	_passive_evolution_targets.clear()
	_timers = {"static_field": 0.0, "battle_focus": 0.0, "recovery_field": 0.0, "guardian_drone": 0.0, "magnet_core": 0.0, "orbit_shields": 0.0, "storm_relay": 0.0, "chain_lightning": 0.0, "time_dilator": 0.0}
	_pickup_scan_remaining = 0.0
	_orbit_shield_ui_refresh_remaining = 0.0
	_remove_guardian_drone_visual()
	_remove_orbit_shield_visual()
	if _player != null and is_instance_valid(_player):
		_player.clear_shield_charges()
	_stopped = false
	passive_state_changed.emit()


func stop() -> void:
	_stopped = true
	if _auto_attack != null:
		_auto_attack.clear_temporary_attack_speed_modifier("battle_focus")
	_selected_passive_evolutions.clear()
	_passive_evolution_targets.clear()
	_timers["guardian_drone"] = 0.0
	_timers["magnet_core"] = 0.0
	_timers["orbit_shields"] = 0.0
	_timers["storm_relay"] = 0.0
	_timers["chain_lightning"] = 0.0
	_timers["time_dilator"] = 0.0
	_orbit_shield_ui_refresh_remaining = 0.0
	_remove_guardian_drone_visual()
	_remove_orbit_shield_visual()
	if _player != null and is_instance_valid(_player):
		_player.clear_shield_charges()
	passive_state_changed.emit()


func _tick_static_field(delta: float) -> void:
	_timers["static_field"] = maxf(float(_timers["static_field"]) - delta, 0.0)
	if float(_timers["static_field"]) > 0.0:
		return
	if has_passive_evolution(RAGE_FIELD_EVOLUTION_ID):
		_tick_rage_field()
		return
	var level := get_passive_level("static_field")
	var radius := _world_value("static_field", "radius", level)
	var damage := int(_value("static_field", "damage", level))
	var targets: Array[Enemy3D] = CombatQuery3D.enemies_in_radius(_enemy_container, _player.global_position, radius)
	for enemy: Enemy3D in targets:
		enemy.take_damage(damage)
	_spawn_pulse(_player.global_position, radius, 0.24, Color(0.25, 0.95, 1.0, 0.72), 0.70)
	_timers["static_field"] = _value("static_field", "interval", level)
	passive_triggered.emit("static_field", {"damage": damage, "radius": radius, "target_count": targets.size()})
	passive_state_changed.emit()


func _tick_rage_field() -> void:
	var level := get_passive_level("static_field")
	var rage_ratio: float = _ability_manager.get_rage_ratio() if _ability_manager != null and _ability_manager.has_method("get_rage_ratio") else 0.0
	var radius := _world_value("static_field", "radius", level) * (1.35 + rage_ratio * 0.55)
	var damage := maxi(int(_value("static_field", "damage", level) * (2.5 + rage_ratio * 4.0)), 1)
	var targets: Array[Enemy3D] = CombatQuery3D.enemies_in_radius(_enemy_container, _player.global_position, radius)
	for enemy: Enemy3D in targets:
		enemy.take_damage(damage)
		enemy.apply_temporary_modifier("rage_field_stagger", RAGE_FIELD_SLOW, RAGE_FIELD_SLOW_DURATION)
	_spawn_pulse(_player.global_position, radius, 0.24, Color(1.0, 0.24, 0.05, 0.86), 0.52)
	_timers["static_field"] = maxf(_value("static_field", "interval", level) * (0.62 - rage_ratio * 0.22), RAGE_FIELD_MIN_INTERVAL)
	passive_triggered.emit("static_field", {"title": "Rage Field", "damage": damage, "radius": radius, "rage_ratio": rage_ratio, "target_count": targets.size()})
	passive_state_changed.emit()


func _tick_battle_focus(delta: float) -> void:
	_timers["battle_focus"] = maxf(float(_timers["battle_focus"]) - delta, 0.0)
	if float(_timers["battle_focus"]) > 0.0:
		return
	if has_passive_evolution(BERSERKER_FOCUS_EVOLUTION_ID):
		_tick_berserker_focus()
		return
	var level := get_passive_level("battle_focus")
	var target := CombatQuery3D.nearest_living_enemy(_enemy_container, _player.global_position, _world_value("battle_focus", "range", level))
	if target == null:
		_timers["battle_focus"] = 0.35
		return
	var damage := int(_value("battle_focus", "damage", level))
	target.take_damage(damage)
	_spawn_arc(_player.global_position, target.global_position, 0.16, Color(1.0, 0.30, 0.08, 0.92), 0.06)
	var duration := _value("battle_focus", "duration", level)
	_auto_attack.set_temporary_attack_speed_modifier("battle_focus", _value("battle_focus", "attack_speed_multiplier", level), duration)
	_spawn_pulse(_player.global_position, 1.2, 0.18, Color(1.0, 0.45, 0.20, 0.75), 0.60)
	_timers["battle_focus"] = _value("battle_focus", "interval", level)
	passive_triggered.emit("battle_focus", {"damage": damage, "duration": duration, "target_id": target.get_instance_id()})
	passive_state_changed.emit()


func _tick_recovery_field(delta: float) -> void:
	_timers["recovery_field"] = maxf(float(_timers["recovery_field"]) - delta, 0.0)
	if float(_timers["recovery_field"]) > 0.0:
		return
	var level := get_passive_level("recovery_field")
	var requested_healing := int(_value("recovery_field", "heal", level))
	var health_before := _player.current_health
	_player.heal(requested_healing)
	var actual_healing := _player.current_health - health_before
	var radius := _world_value("recovery_field", "radius", level)
	var interval := _value("recovery_field", "interval", level)
	_spawn_pulse(_player.global_position, radius, 0.25, Color(0.24, 1.0, 0.48, 0.72), 0.68)
	_timers["recovery_field"] = interval
	passive_triggered.emit("recovery_field", {"requested_healing": requested_healing, "actual_healing": actual_healing, "radius": radius, "interval": interval})
	passive_state_changed.emit()


func _tick_berserker_focus() -> void:
	var level := get_passive_level("battle_focus")
	var rage_ratio: float = _ability_manager.get_rage_ratio() if _ability_manager != null and _ability_manager.has_method("get_rage_ratio") else 0.0
	var range_ := _world_value("battle_focus", "range", level) * (1.3 + rage_ratio * 0.35)
	var damage := maxi(int(_value("battle_focus", "damage", level) * (2.8 + rage_ratio * 2.0)), 1)
	var targets: Array[Enemy3D] = CombatQuery3D.enemies_in_radius(_enemy_container, _player.global_position, range_)
	var maximum_targets := mini(targets.size(), mini(1 + roundi(rage_ratio * 3.0), 4))
	if maximum_targets <= 0:
		_timers["battle_focus"] = 0.28
		return
	for index in range(maximum_targets):
		var target := targets[index]
		target.take_damage(damage)
		_spawn_arc(_player.global_position, target.global_position, 0.16, Color(1.0, 0.16, 0.04, 0.96), 0.075)
	var speed_multiplier := _value("battle_focus", "attack_speed_multiplier", level) + 0.55 + rage_ratio * 0.45
	var duration := _value("battle_focus", "duration", level) * (1.7 + rage_ratio)
	_auto_attack.set_temporary_attack_speed_modifier("battle_focus", speed_multiplier, duration)
	_spawn_pulse(_player.global_position, 1.4, 0.20, Color(1.0, 0.16, 0.04, 0.82), 0.52)
	var interval := maxf(_value("battle_focus", "interval", level) * 0.62, 0.85)
	_timers["battle_focus"] = interval
	passive_triggered.emit("battle_focus", {"title": "Berserker Focus", "rage_ratio": rage_ratio, "damage": damage, "range": range_, "target_count": maximum_targets, "speed_multiplier": speed_multiplier, "buff_duration": duration, "interval": interval})
	passive_state_changed.emit()


func _tick_magnet_core(delta: float) -> void:
	_pickup_scan_remaining = maxf(_pickup_scan_remaining - delta, 0.0)
	if _pickup_scan_remaining > 0.0 or _pickup_container == null:
		return
	_pickup_scan_remaining = PICKUP_SCAN_INTERVAL
	var radius := _get_effective_magnet_radius(get_passive_level("magnet_core"))
	var attracted_count := 0
	for child: Node in _pickup_container.get_children():
		if child is ExperiencePickup3D:
			var pickup := child as ExperiencePickup3D
			if pickup.is_attracted_to(_player) or pickup.global_position.distance_to(_player.global_position) > radius:
				continue
			pickup.set_attraction_target(_player, MAGNET_ATTRACTION_SPEED)
			attracted_count += 1
	if attracted_count > 0:
		passive_triggered.emit("magnet_core", {"radius": radius, "pickup_count": attracted_count})


func _tick_guardian_drone(delta: float) -> void:
	_timers["guardian_drone"] = maxf(float(_timers["guardian_drone"]) - delta, 0.0)
	if float(_timers["guardian_drone"]) > 0.0:
		return
	_ensure_guardian_drone_visual()
	var level := get_passive_level("guardian_drone")
	var target: Enemy3D = CombatQuery3D.nearest_living_enemy(_enemy_container, _player.global_position, _world_value("guardian_drone", "range", level))
	if target == null:
		_timers["guardian_drone"] = GUARDIAN_DRONE_NO_TARGET_RETRY
		return
	var damage := int(_value("guardian_drone", "damage", level))
	target.take_damage(damage)
	var origin: Vector3 = _guardian_drone_visual.global_position if _guardian_drone_visual != null and is_instance_valid(_guardian_drone_visual) else _player.global_position
	_spawn_arc(origin, target.global_position, 0.16, Color(1.0, 0.80, 0.18, 0.94), 0.055)
	var interval := _value("guardian_drone", "interval", level)
	_timers["guardian_drone"] = interval
	passive_triggered.emit("guardian_drone", {"damage": damage, "range": _world_value("guardian_drone", "range", level), "target_id": target.get_instance_id(), "interval": interval})
	passive_state_changed.emit()


func _tick_time_dilator(delta: float) -> void:
	_timers["time_dilator"] = maxf(float(_timers["time_dilator"]) - delta, 0.0)
	if float(_timers["time_dilator"]) > 0.0:
		return
	var level := get_passive_level("time_dilator")
	var radius := _world_value("time_dilator", "radius", level)
	var movement_speed_multiplier := _value("time_dilator", "movement_speed_multiplier", level)
	var duration := _value("time_dilator", "duration", level)
	var interval := _value("time_dilator", "interval", level)
	var targets: Array[Enemy3D] = CombatQuery3D.enemies_in_radius(_enemy_container, _player.global_position, radius)
	var affected_target_ids: Array[int] = []
	for enemy: Enemy3D in targets:
		affected_target_ids.append(enemy.get_instance_id())
		enemy.apply_temporary_modifier("time_dilator", {"movement_speed_multiplier": movement_speed_multiplier}, duration)
	_spawn_pulse(_player.global_position, radius, 0.34, Color(0.56, 0.56, 1.0, 0.76), 0.64)
	_timers["time_dilator"] = interval
	passive_triggered.emit("time_dilator", {"level": level, "radius": radius, "movement_speed_multiplier": movement_speed_multiplier, "duration": duration, "interval": interval, "target_count": affected_target_ids.size(), "affected_target_ids": affected_target_ids})
	passive_state_changed.emit()


func _tick_storm_relay(delta: float) -> void:
	_timers["storm_relay"] = maxf(float(_timers["storm_relay"]) - delta, 0.0)
	if float(_timers["storm_relay"]) > 0.0:
		return
	var level := get_passive_level("storm_relay")
	var range_ := _world_value("storm_relay", "range", level)
	var target: Enemy3D = CombatQuery3D.nearest_living_enemy(_enemy_container, _player.global_position, range_)
	if target == null:
		_timers["storm_relay"] = 0.35
		return
	var target_id := target.get_instance_id()
	var target_position := target.global_position
	var damage := int(_value("storm_relay", "damage", level))
	target.take_damage(damage)
	_spawn_arc(_player.global_position, target_position, 0.16, Color(0.22, 0.86, 1.0, 0.94), 0.075)
	var interval := _value("storm_relay", "interval", level)
	_timers["storm_relay"] = interval
	passive_triggered.emit("storm_relay", {"damage": damage, "range": range_, "target_id": target_id, "interval": interval})
	passive_state_changed.emit()


func _tick_chain_lightning(delta: float) -> void:
	_timers["chain_lightning"] = maxf(float(_timers["chain_lightning"]) - delta, 0.0)
	if float(_timers["chain_lightning"]) > 0.0:
		return
	var level := get_passive_level("chain_lightning")
	var initial_range := _world_value("chain_lightning", "initial_range", level)
	var bounce_range := _world_value("chain_lightning", "bounce_range", level)
	var maximum_targets := int(_value("chain_lightning", "maximum_targets", level))
	var target: Enemy3D = CombatQuery3D.nearest_living_enemy(_enemy_container, _player.global_position, initial_range)
	if target == null:
		_timers["chain_lightning"] = 0.35
		return
	var damage := int(_value("chain_lightning", "damage", level))
	var excluded_instance_ids: Dictionary = {}
	var affected_target_ids: Array[int] = []
	var arc_origin := _player.global_position
	while target != null and affected_target_ids.size() < maximum_targets:
		var target_id := target.get_instance_id()
		var target_position := target.global_position
		target.take_damage(damage)
		excluded_instance_ids[target_id] = true
		affected_target_ids.append(target_id)
		_spawn_arc(arc_origin, target_position, 0.14, Color(1.0, 0.91, 0.34, 0.96), 0.052)
		arc_origin = target_position
		if affected_target_ids.size() >= maximum_targets:
			break
		target = CombatQuery3D.nearest_living_enemy_excluding(_enemy_container, arc_origin, bounce_range, excluded_instance_ids)
	var interval := _value("chain_lightning", "interval", level)
	_timers["chain_lightning"] = interval
	passive_triggered.emit("chain_lightning", {"damage_per_target": damage, "initial_range": initial_range, "bounce_range": bounce_range, "maximum_targets": maximum_targets, "target_count": affected_target_ids.size(), "affected_target_ids": affected_target_ids, "interval": interval})
	passive_state_changed.emit()


func _configure_orbit_shields(previous_level: int, next_level: int) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var maximum_charges := int(_value("orbit_shields", "maximum_charges", next_level))
	var previous_maximum := int(_value("orbit_shields", "maximum_charges", previous_level)) if previous_level > 0 else 0
	var refill := previous_level == 0 or maximum_charges > previous_maximum
	_player.configure_shield_charges(maximum_charges, refill)
	if previous_level == 0:
		_timers["orbit_shields"] = _value("orbit_shields", "interval", next_level)
	elif _player.get_shield_charges() >= _player.get_maximum_shield_charges():
		_timers["orbit_shields"] = 0.0
	_ensure_orbit_shield_visual()


func _tick_orbit_shields(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var maximum_charges := _player.get_maximum_shield_charges()
	if maximum_charges <= 0 or _player.get_shield_charges() >= maximum_charges:
		_timers["orbit_shields"] = 0.0
		return
	if float(_timers["orbit_shields"]) <= 0.0:
		_timers["orbit_shields"] = _value("orbit_shields", "interval", get_passive_level("orbit_shields"))
		passive_state_changed.emit()
		return
	_timers["orbit_shields"] = maxf(float(_timers["orbit_shields"]) - delta, 0.0)
	if float(_timers["orbit_shields"]) > 0.0:
		return
	var restored := _player.add_shield_charges(1)
	if restored > 0:
		passive_triggered.emit("orbit_shields", {"event": "charge_regenerated", "current_charges": _player.get_shield_charges(), "maximum_charges": maximum_charges})
	if _player.get_shield_charges() < maximum_charges:
		_timers["orbit_shields"] = _value("orbit_shields", "interval", get_passive_level("orbit_shields"))
	else:
		_timers["orbit_shields"] = 0.0
	passive_state_changed.emit()


func _tick_orbit_shield_ui_refresh(delta: float) -> void:
	if _player == null or not is_instance_valid(_player) or _player.get_shield_charges() >= _player.get_maximum_shield_charges() or float(_timers.get("orbit_shields", 0.0)) <= 0.0:
		_orbit_shield_ui_refresh_remaining = 0.0
		return
	_orbit_shield_ui_refresh_remaining = maxf(_orbit_shield_ui_refresh_remaining - delta, 0.0)
	if _orbit_shield_ui_refresh_remaining > 0.0:
		return
	_orbit_shield_ui_refresh_remaining = ORBIT_SHIELD_UI_REFRESH_INTERVAL
	passive_state_changed.emit()


func _on_player_shield_changed(current: int, maximum: int) -> void:
	if not has_passive("orbit_shields"):
		return
	if current < maximum and float(_timers.get("orbit_shields", 0.0)) <= 0.0:
		_timers["orbit_shields"] = _value("orbit_shields", "interval", get_passive_level("orbit_shields"))
	elif current >= maximum:
		_timers["orbit_shields"] = 0.0
	_ensure_orbit_shield_visual()
	passive_state_changed.emit()


func _on_player_shield_blocked(blocked_damage: int, remaining: int, maximum: int) -> void:
	if not has_passive("orbit_shields"):
		return
	_spawn_pulse(_player.global_position, 1.2, 0.18, Color(0.18, 0.90, 1.0, 0.86), 0.66)
	passive_triggered.emit("orbit_shields", {"event": "blocked", "blocked_damage": blocked_damage, "remaining_charges": remaining, "maximum_charges": maximum})
	passive_state_changed.emit()


func _tick_gravity_rage(delta: float) -> void:
	_timers["magnet_core"] = maxf(float(_timers["magnet_core"]) - delta, 0.0)
	if float(_timers["magnet_core"]) > 0.0:
		return
	var level := get_passive_level("magnet_core")
	var radius := _get_gravity_rage_radius(level)
	var targets: Array[Enemy3D] = CombatQuery3D.enemies_in_radius(_enemy_container, _player.global_position, radius)
	for enemy: Enemy3D in targets:
		var direction := _player.global_position - enemy.global_position
		direction.y = 0.0
		if not direction.is_zero_approx():
			enemy.apply_knockback(direction.normalized(), GRAVITY_RAGE_PULL_FORCE, GRAVITY_RAGE_PULL_DURATION)
		enemy.apply_temporary_modifier("gravity_rage_pull", GRAVITY_RAGE_SLOW, GRAVITY_RAGE_SLOW_DURATION)
	_spawn_pulse(_player.global_position, radius, 0.26, Color(0.70, 0.30, 1.0, 0.90), 0.72)
	_timers["magnet_core"] = GRAVITY_RAGE_INTERVAL
	passive_triggered.emit("magnet_core", {"title": "Gravity Rage", "radius": radius, "target_count": targets.size(), "pull_force": GRAVITY_RAGE_PULL_FORCE, "pull_duration": GRAVITY_RAGE_PULL_DURATION, "slow_multiplier": 0.55, "slow_duration": GRAVITY_RAGE_SLOW_DURATION, "interval": GRAVITY_RAGE_INTERVAL})
	passive_state_changed.emit()


func _format_passive_values(passive_id: String, from_level: int, to_level: int) -> String:
	var definition: Dictionary = PASSIVE_DEFINITIONS.get(passive_id, {})
	if definition.is_empty() or to_level < 1:
		return ""
	var lines: PackedStringArray = []
	for key: String in definition:
		if key in ["title", "max_level"]:
			continue
		var raw = definition[key]
		if not raw is Array:
			continue
		var next_value := _display_passive_value(key, _value(passive_id, key, to_level))
		if from_level <= 0:
			lines.append("%s: %s" % [_passive_value_label(key), next_value])
		else:
			var current_value := _display_passive_value(key, _value(passive_id, key, from_level))
			if current_value != next_value:
				lines.append("%s: %s -> %s" % [_passive_value_label(key), current_value, next_value])
	return "\n".join(lines)


func _passive_value_label(key: String) -> String:
	return {"damage": "Damage", "heal": "Healing", "interval": "Interval", "radius": "Radius", "range": "Range", "pickup_radius_bonus": "Pickup radius bonus", "attack_speed_multiplier": "Attack speed bonus", "duration": "Duration", "maximum_charges": "Charges", "initial_range": "Initial range", "bounce_range": "Bounce range", "maximum_targets": "Targets", "movement_speed_multiplier": "Enemy speed"}.get(key, key.capitalize())


func _display_passive_value(key: String, value: float) -> String:
	if key in ["radius", "range", "pickup_radius_bonus", "initial_range", "bounce_range"]:
		return "%.2f" % (value / PIXELS_PER_WORLD_UNIT)
	if key in ["interval", "duration"]:
		return "%.2fs" % value
	if key == "attack_speed_multiplier":
		return "+%d%%" % roundi((value - 1.0) * 100.0)
	if key == "movement_speed_multiplier":
		return "%d%% reduction" % roundi((1.0 - value) * 100.0)
	return "%d" % roundi(value)


func _value(passive_id: String, key: String, level: int) -> float:
	var value: Variant = PASSIVE_DEFINITIONS[passive_id].get(key, 0.0)
	if value is Array:
		var values: Array = value
		return float(values[clampi(level - 1, 0, values.size() - 1)])
	return float(value)


func _world_value(passive_id: String, key: String, level: int) -> float:
	return _value(passive_id, key, level) / PIXELS_PER_WORLD_UNIT


func _get_effective_magnet_radius(level: int) -> float:
	return (LEGACY_BASE_MAGNET_RADIUS_PIXELS + _get_effective_magnet_bonus_pixels(level)) / PIXELS_PER_WORLD_UNIT


func _get_magnet_bonus_pixels(level: int) -> float:
	return _value("magnet_core", "pickup_radius_bonus", level) if level > 0 else 0.0


func _get_effective_magnet_bonus_pixels(level: int) -> float:
	return _get_magnet_bonus_pixels(level) * _get_magnet_bonus_multiplier()


func _get_magnet_bonus_multiplier() -> float:
	return GRAVITY_RAGE_BONUS_MULTIPLIER if has_passive_evolution(GRAVITY_RAGE_EVOLUTION_ID) else 1.0


func _get_gravity_rage_radius(level: int) -> float:
	return (220.0 + _get_effective_magnet_bonus_pixels(level)) / PIXELS_PER_WORLD_UNIT


func _get_passive_display_title(passive_id: String) -> String:
	if passive_id == "static_field" and has_passive_evolution(RAGE_FIELD_EVOLUTION_ID):
		return "Rage Field"
	if passive_id == "battle_focus" and has_passive_evolution(BERSERKER_FOCUS_EVOLUTION_ID):
		return "Berserker Focus"
	if passive_id == "magnet_core" and has_passive_evolution(GRAVITY_RAGE_EVOLUTION_ID):
		return "Gravity Rage"
	return str(PASSIVE_DEFINITIONS.get(passive_id, {}).get("title", passive_id))


func _ensure_guardian_drone_visual() -> void:
	if _guardian_drone_visual != null and is_instance_valid(_guardian_drone_visual):
		return
	if _effect_container == null or _player == null or not is_instance_valid(_player):
		return
	_guardian_drone_visual = GUARDIAN_DRONE_VISUAL.instantiate()
	_effect_container.add_child(_guardian_drone_visual)
	if _guardian_drone_visual.has_method("setup"):
		_guardian_drone_visual.call("setup", _player)


func _remove_guardian_drone_visual() -> void:
	if _guardian_drone_visual != null and is_instance_valid(_guardian_drone_visual):
		_guardian_drone_visual.queue_free()
	_guardian_drone_visual = null


func _ensure_orbit_shield_visual() -> void:
	if _orbit_shield_visual != null and is_instance_valid(_orbit_shield_visual):
		return
	if _effect_container == null or _player == null or not is_instance_valid(_player):
		return
	_orbit_shield_visual = ORBIT_SHIELD_VISUAL.instantiate()
	_effect_container.add_child(_orbit_shield_visual)
	if _orbit_shield_visual.has_method("setup"):
		_orbit_shield_visual.call("setup", _player)


func _remove_orbit_shield_visual() -> void:
	if _orbit_shield_visual != null and is_instance_valid(_orbit_shield_visual):
		_orbit_shield_visual.queue_free()
	_orbit_shield_visual = null


func _spawn_pulse(position: Vector3, radius: float, duration: float, color: Color, inner_radius_ratio: float) -> void:
	if _effect_container == null:
		return
	var effect := PASSIVE_PULSE_EFFECT.instantiate()
	_effect_container.add_child(effect)
	effect.setup(position, radius, duration, color, inner_radius_ratio)


func _spawn_arc(start_position: Vector3, end_position: Vector3, duration: float, color: Color, thickness: float) -> void:
	if _effect_container == null:
		return
	var effect := PASSIVE_ARC_EFFECT.instantiate()
	_effect_container.add_child(effect)
	effect.setup(start_position, end_position, duration, color, thickness)


func _exit_tree() -> void:
	_remove_guardian_drone_visual()
	_remove_orbit_shield_visual()
	if _player != null and is_instance_valid(_player):
		_player.clear_shield_charges()
	_disconnect_player_shield_signals()


func _disconnect_player_shield_signals() -> void:
	if _player != null and is_instance_valid(_player):
		if _player.shield_changed.is_connected(_on_player_shield_changed):
			_player.shield_changed.disconnect(_on_player_shield_changed)
		if _player.shield_blocked.is_connected(_on_player_shield_blocked):
			_player.shield_blocked.disconnect(_on_player_shield_blocked)
