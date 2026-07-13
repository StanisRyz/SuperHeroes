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
const RAGE_FIELD_EVOLUTION_ID := "mighty_clap_rampage_impact"
const BERSERKER_FOCUS_EVOLUTION_ID := "rage_leap_blood_crater"
const RAGE_FIELD_SLOW := {"movement_speed_multiplier": 0.55}
const RAGE_FIELD_SLOW_DURATION := 0.75
const RAGE_FIELD_MIN_INTERVAL := 0.85
const PASSIVE_DEFINITIONS: Dictionary = {
	"static_field": {"title": "Static Field", "max_level": 3, "damage": [5, 7, 9], "interval": [4.8, 4.2, 3.6], "radius": [150.0, 175.0, 200.0]},
	"battle_focus": {"title": "Battle Focus", "max_level": 3, "damage": [4, 6, 8], "interval": [7.5, 6.5, 5.5], "range": 420.0, "attack_speed_multiplier": [1.12, 1.18, 1.24], "duration": [3.0, 3.5, 4.0]},
	"recovery_field": {"title": "Recovery Field", "max_level": 3, "heal": [4, 6, 8], "interval": [12.0, 10.5, 9.0], "radius": [80.0, 95.0, 110.0]},
	"magnet_core": {"title": "Magnet Core", "max_level": 3, "pickup_radius_bonus": [45.0, 85.0, 125.0]},
}

signal passive_changed(passive_id: String, level: int)
signal passive_state_changed
signal passive_triggered(passive_id: String, data: Dictionary)

var _player: Player3D
var _auto_attack: KnightMeleeAutoAttack3D
var _ability_manager: KnightAbilityManager3D
var _enemy_container: Node3D
var _pickup_container: Node3D
var _effect_container: Node3D
var _levels: Dictionary = {}
var _timers: Dictionary = {"static_field": 0.0, "battle_focus": 0.0, "recovery_field": 0.0}
var _pickup_scan_remaining := 0.0
var _stopped := false
var _selected_passive_evolutions: Array[String] = []
var _passive_evolution_targets: Dictionary = {}


func setup(player: Player3D, auto_attack: KnightMeleeAutoAttack3D, ability_manager: KnightAbilityManager3D, enemy_container: Node3D, pickup_container: Node3D, effect_container: Node3D) -> void:
	_player = player
	_auto_attack = auto_attack
	_ability_manager = ability_manager
	_enemy_container = enemy_container
	_pickup_container = pickup_container
	_effect_container = effect_container
	reset_run_state()


func _process(delta: float) -> void:
	if _stopped or get_tree().paused or _player == null or _player.is_dead():
		return
	if has_passive("static_field"):
		_tick_static_field(delta)
	if has_passive("battle_focus"):
		_tick_battle_focus(delta)
	if has_passive("recovery_field"):
		_tick_recovery_field(delta)
	if has_passive("magnet_core"):
		_tick_magnet_core(delta)


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
	passive_changed.emit(passive_id, next_level)
	passive_state_changed.emit()
	return true


func get_passive_level(passive_id: String) -> int:
	return int(_levels.get(passive_id, 0))


func get_passive_max_level(passive_id: String) -> int:
	return int(PASSIVE_DEFINITIONS.get(passive_id, {}).get("max_level", 0))


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
		state["base_magnet_radius_pixels"] = LEGACY_BASE_MAGNET_RADIUS_PIXELS
		state["effective_pickup_radius"] = _get_effective_magnet_radius(level)
		state["attraction_speed"] = MAGNET_ATTRACTION_SPEED
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
	return (evolution_id == RAGE_FIELD_EVOLUTION_ID and target_passive_id == "static_field" and has_passive("static_field")) or (evolution_id == BERSERKER_FOCUS_EVOLUTION_ID and target_passive_id == "battle_focus" and has_passive("battle_focus"))


func apply_passive_evolution(evolution_id: String, target_passive_id: String) -> bool:
	if not can_apply_passive_evolution(evolution_id, target_passive_id):
		return false
	if evolution_id in _selected_passive_evolutions:
		return true
	_selected_passive_evolutions.append(evolution_id)
	_passive_evolution_targets[evolution_id] = target_passive_id
	if evolution_id == RAGE_FIELD_EVOLUTION_ID:
		_spawn_pulse(_player.global_position, _world_value("static_field", "radius", get_passive_level("static_field")) * 1.35, 0.28, Color(1.0, 0.24, 0.05, 0.76), 0.52)
	else:
		_spawn_pulse(_player.global_position, 1.3, 0.22, Color(1.0, 0.16, 0.04, 0.78), 0.55)
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
	return titles


func reset_run_state() -> void:
	if _auto_attack != null:
		_auto_attack.clear_temporary_attack_speed_modifier("battle_focus")
	_levels.clear()
	_selected_passive_evolutions.clear()
	_passive_evolution_targets.clear()
	_timers = {"static_field": 0.0, "battle_focus": 0.0, "recovery_field": 0.0}
	_pickup_scan_remaining = 0.0
	_stopped = false
	passive_state_changed.emit()


func stop() -> void:
	_stopped = true
	if _auto_attack != null:
		_auto_attack.clear_temporary_attack_speed_modifier("battle_focus")
	_selected_passive_evolutions.clear()
	_passive_evolution_targets.clear()
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


func _value(passive_id: String, key: String, level: int) -> float:
	var value: Variant = PASSIVE_DEFINITIONS[passive_id].get(key, 0.0)
	if value is Array:
		var values: Array = value
		return float(values[clampi(level - 1, 0, values.size() - 1)])
	return float(value)


func _world_value(passive_id: String, key: String, level: int) -> float:
	return _value(passive_id, key, level) / PIXELS_PER_WORLD_UNIT


func _get_effective_magnet_radius(level: int) -> float:
	return (LEGACY_BASE_MAGNET_RADIUS_PIXELS + _get_magnet_bonus_pixels(level)) / PIXELS_PER_WORLD_UNIT


func _get_magnet_bonus_pixels(level: int) -> float:
	return _value("magnet_core", "pickup_radius_bonus", level) if level > 0 else 0.0


func _get_passive_display_title(passive_id: String) -> String:
	if passive_id == "static_field" and has_passive_evolution(RAGE_FIELD_EVOLUTION_ID):
		return "Rage Field"
	if passive_id == "battle_focus" and has_passive_evolution(BERSERKER_FOCUS_EVOLUTION_ID):
		return "Berserker Focus"
	return str(PASSIVE_DEFINITIONS.get(passive_id, {}).get("title", passive_id))


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
