extends Node

signal passive_changed(passive_id: String, level: int)

const PASSIVE_DEFINITIONS := {
	"orbit_shields": {
		"display_name": "Orbit Shields",
		"max_charges": [1, 1, 2],
		"regen_interval": [18.0, 14.0, 12.0],
	},
	"storm_relay": {
		"display_name": "Storm Relay",
		"damage": [8, 12, 16],
		"interval": [5.5, 4.8, 4.2],
		"range": 520.0,
	},
	"guardian_drone": {
		"display_name": "Guardian Drone",
		"damage": [5, 8, 11],
		"interval": [3.4, 3.0, 2.6],
		"range": 460.0,
	},
	"magnet_core": {
		"display_name": "Magnet Core",
		"pickup_radius_bonus": [45.0, 85.0, 125.0],
	},
}
const STATUS_SENTINEL := Vector2(100000000.0, 100000000.0)

var player: Node2D = null
var enemy_container: Node = null
var projectile_container: Node = null
var pickup_container: Node = null
var feedback_manager: Node = null

var _passive_levels: Dictionary = {}
var _timers: Dictionary = {
	"orbit_shields": 0.0,
	"storm_relay": 0.0,
	"guardian_drone": 0.0,
}
var _applied_pickup_radius_bonus: float = 0.0


func setup(new_player: Node, new_enemy_container: Node, new_projectile_container: Node, new_pickup_container: Node, new_feedback_manager: Node) -> void:
	player = new_player as Node2D
	enemy_container = new_enemy_container
	projectile_container = new_projectile_container
	pickup_container = new_pickup_container
	feedback_manager = new_feedback_manager


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	if player.has_method("is_dead") and player.is_dead():
		return

	if has_passive("orbit_shields"):
		_tick_orbit_shields(delta)
	if has_passive("storm_relay"):
		_tick_storm_relay(delta)
	if has_passive("guardian_drone"):
		_tick_guardian_drone(delta)


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
		"magnet_core":
			_apply_magnet_core_bonus()

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
	}
	var buff_manager := _get_buff_manager()
	if buff_manager != null and buff_manager.has_method("get_shield_charges"):
		state["shield_charges"] = buff_manager.get_shield_charges()
		state["shield_max_charges"] = _get_orbit_shield_max_charges()
	return state


func cleanup() -> void:
	_reset_magnet_core_bonus()
	_passive_levels.clear()
	for key in _timers.keys():
		_timers[key] = 0.0


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


func _tick_storm_relay(delta: float) -> void:
	_timers["storm_relay"] = maxf(float(_timers.get("storm_relay", 0.0)) - delta, 0.0)
	if float(_timers["storm_relay"]) > 0.0:
		return

	var level := get_passive_level("storm_relay")
	var target := _find_nearest_enemy(_get_scaled_value("storm_relay", "range", level))
	if target == null:
		_timers["storm_relay"] = 0.35
		return

	var damage := int(_get_scaled_value("storm_relay", "damage", level))
	target.take_damage(damage)
	_show_damage(damage, target.global_position)
	_show_status("RELAY", target.global_position + Vector2.UP * 28.0)
	_timers["storm_relay"] = _get_scaled_value("storm_relay", "interval", level)


func _tick_guardian_drone(delta: float) -> void:
	_timers["guardian_drone"] = maxf(float(_timers.get("guardian_drone", 0.0)) - delta, 0.0)
	if float(_timers["guardian_drone"]) > 0.0:
		return

	var level := get_passive_level("guardian_drone")
	var target := _find_nearest_enemy(_get_scaled_value("guardian_drone", "range", level))
	if target == null:
		_timers["guardian_drone"] = 0.35
		return

	var damage := int(_get_scaled_value("guardian_drone", "damage", level))
	target.take_damage(damage)
	_show_damage(damage, target.global_position)
	_show_status("DRONE", target.global_position + Vector2.UP * 28.0)
	_timers["guardian_drone"] = _get_scaled_value("guardian_drone", "interval", level)


func _fill_orbit_shields() -> void:
	var buff_manager := _get_buff_manager()
	if buff_manager == null or not buff_manager.has_method("get_shield_charges") or not buff_manager.has_method("add_shield_charges"):
		return
	var missing := _get_orbit_shield_max_charges() - int(buff_manager.get_shield_charges())
	if missing > 0:
		buff_manager.add_shield_charges(missing)
	_timers["orbit_shields"] = _get_orbit_shield_regen_interval()


func _apply_magnet_core_bonus() -> void:
	if player == null or player.get("pickup_radius_bonus") == null:
		return
	var level := get_passive_level("magnet_core")
	var new_bonus := _get_scaled_value("magnet_core", "pickup_radius_bonus", level)
	player.set("pickup_radius_bonus", float(player.get("pickup_radius_bonus")) - _applied_pickup_radius_bonus + new_bonus)
	_applied_pickup_radius_bonus = new_bonus


func _reset_magnet_core_bonus() -> void:
	if player == null or not is_instance_valid(player) or player.get("pickup_radius_bonus") == null:
		return
	player.set("pickup_radius_bonus", float(player.get("pickup_radius_bonus")) - _applied_pickup_radius_bonus)
	_applied_pickup_radius_bonus = 0.0


func _find_nearest_enemy(max_range: float) -> Node2D:
	if enemy_container == null or not is_instance_valid(enemy_container) or player == null:
		return null

	var best: Node2D = null
	var best_distance_sq := max_range * max_range
	for enemy in enemy_container.get_children():
		if not _is_valid_enemy(enemy):
			continue
		var enemy_node := enemy as Node2D
		var distance_sq := player.global_position.distance_squared_to(enemy_node.global_position)
		if distance_sq <= best_distance_sq:
			best_distance_sq = distance_sq
			best = enemy_node
	return best


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
	return int(_get_scaled_value("orbit_shields", "max_charges", get_passive_level("orbit_shields")))


func _get_orbit_shield_regen_interval() -> float:
	return _get_scaled_value("orbit_shields", "regen_interval", get_passive_level("orbit_shields"))


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


func _show_damage(amount: int, world_position: Vector2) -> void:
	if feedback_manager != null and feedback_manager.has_method("show_damage"):
		feedback_manager.show_damage(amount, world_position)


func _show_status(text: String, world_position: Vector2 = STATUS_SENTINEL) -> void:
	if feedback_manager == null or not feedback_manager.has_method("show_status"):
		return
	var position := world_position
	if position == STATUS_SENTINEL and player != null:
		position = player.global_position + Vector2.UP * 42.0
	feedback_manager.show_status(text, position)
