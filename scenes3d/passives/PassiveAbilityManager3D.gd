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
const PASSIVE_DEFINITIONS: Dictionary = {
	"static_field": {"title": "Static Field", "max_level": 3, "damage": [5, 7, 9], "interval": [4.8, 4.2, 3.6], "radius": [150.0, 175.0, 200.0]},
	"battle_focus": {"title": "Battle Focus", "max_level": 3, "damage": [4, 6, 8], "interval": [7.5, 6.5, 5.5], "range": 420.0, "attack_speed_multiplier": [1.12, 1.18, 1.24], "duration": [3.0, 3.5, 4.0]},
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
var _timers: Dictionary = {"static_field": 0.0, "battle_focus": 0.0}
var _pickup_scan_remaining := 0.0
var _stopped := false


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
	if has_passive("magnet_core"):
		_tick_magnet_core(delta)


func add_or_upgrade_passive(passive_id: String) -> bool:
	if not PASSIVE_DEFINITIONS.has(passive_id):
		return false
	var level := get_passive_level(passive_id)
	if level >= get_passive_max_level(passive_id):
		return false
	level += 1
	_levels[passive_id] = level
	if passive_id in _timers and level == 0:
		_timers[passive_id] = 0.0
	if passive_id == "magnet_core":
		_spawn_pulse(_player.global_position, _get_effective_magnet_radius(level), 0.28, Color(0.34, 0.95, 0.62, 0.68), 0.76)
	elif passive_id == "static_field":
		_spawn_pulse(_player.global_position, _world_value("static_field", "radius", level), 0.24, Color(0.25, 0.95, 1.0, 0.72), 0.70)
	passive_changed.emit(passive_id, level)
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
	var state := {"id": passive_id, "title": str(definition["title"]), "level": level, "max_level": get_passive_max_level(passive_id), "selected": has_passive(passive_id), "timer_remaining": float(_timers.get(passive_id, 0.0))}
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
		titles.append(str(PASSIVE_DEFINITIONS[passive_id]["title"]))
	return titles


func reset_run_state() -> void:
	if _auto_attack != null:
		_auto_attack.clear_temporary_attack_speed_modifier("battle_focus")
	_levels.clear()
	_timers = {"static_field": 0.0, "battle_focus": 0.0}
	_pickup_scan_remaining = 0.0
	_stopped = false
	passive_state_changed.emit()


func stop() -> void:
	_stopped = true
	if _auto_attack != null:
		_auto_attack.clear_temporary_attack_speed_modifier("battle_focus")
	passive_state_changed.emit()


func _tick_static_field(delta: float) -> void:
	_timers["static_field"] = maxf(float(_timers["static_field"]) - delta, 0.0)
	if float(_timers["static_field"]) > 0.0:
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


func _tick_battle_focus(delta: float) -> void:
	_timers["battle_focus"] = maxf(float(_timers["battle_focus"]) - delta, 0.0)
	if float(_timers["battle_focus"]) > 0.0:
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
