extends Node

signal evolution_available(evolution_data: Dictionary)
signal evolution_applied(evolution_id: String, evolution_data: Dictionary)
signal evolution_state_changed

@export var elite_reward_chance: float = 0.0

var player: Node
var auto_attack: Node
var ability_manager: Node
var upgrade_manager: Node

var _applied_evolutions: Array[String] = []

var _evolutions: Array[Dictionary] = [
	{
		"id": "projectile_storm",
		"title": "Projectile Storm",
		"archetype": "projectile",
		"description": "Evolve the basic weapon into a denser storm of bouncing piercing bolts.",
		"prerequisites": {"archetype_points": {"projectile": 5}, "any_upgrade_levels": {"multishot_up": 1, "projectile_pierce_up": 1, "bouncing_bolts": 1}},
		"effects": [
			{"target": "auto_attack", "property": "projectile_count", "operation": "add", "value": 1, "max_value": 7},
			{"target": "auto_attack", "property": "projectile_pierce", "operation": "add", "value": 1, "max_value": 5},
			{"target": "auto_attack", "property": "projectile_bounce", "operation": "add", "value": 1, "max_value": 5},
			{"target": "auto_attack", "property": "projectile_spread_degrees", "operation": "add", "value": 4.0, "max_value": 48.0},
		],
		"announcement": "Evolution: Projectile Storm!",
	},
	{
		"id": "supernova_core",
		"title": "Supernova Core",
		"archetype": "nova",
		"description": "Evolve Nova into a larger aftershock core with stronger delayed area control.",
		"prerequisites": {"archetype_points": {"nova": 5}, "any_upgrade_levels": {"nova_aftershock_zone": 1}, "properties_true": {"ability_manager": ["nova_aftershock_enabled"]}},
		"effects": [
			{"target": "ability_manager", "property": "nova_aftershock_enabled", "operation": "set", "value": true},
			{"target": "ability_manager", "property": "nova_aftershock_damage", "operation": "add", "value": 8},
			{"target": "ability_manager", "property": "nova_aftershock_radius", "operation": "add", "value": 35.0},
			{"target": "ability_manager", "property": "nova_cooldown", "operation": "subtract", "value": 0.4, "min_value": 2.0},
		],
		"announcement": "Evolution: Supernova Core!",
	},
	{
		"id": "prism_laser",
		"title": "Prism Laser",
		"archetype": "laser",
		"description": "Evolve Laser into a wider prism beam with a sharper second pulse.",
		"prerequisites": {"archetype_points": {"laser": 5}, "any_upgrade_levels": {"laser_double_pulse": 1}, "properties_true": {"ability_manager": ["laser_double_pulse_enabled"]}},
		"effects": [
			{"target": "ability_manager", "property": "laser_double_pulse_enabled", "operation": "set", "value": true},
			{"target": "ability_manager", "property": "laser_width", "operation": "add", "value": 24.0},
			{"target": "ability_manager", "property": "laser_damage", "operation": "add", "value": 10},
			{"target": "ability_manager", "property": "laser_second_pulse_damage_multiplier", "operation": "add", "value": 0.12, "max_value": 0.9},
		],
		"announcement": "Evolution: Prism Laser!",
	},
	{
		"id": "earthbreaker_slam",
		"title": "Earthbreaker Slam",
		"archetype": "slam",
		"description": "Evolve Hero Slam into a heavier second-wave quake.",
		"prerequisites": {"archetype_points": {"slam": 5}, "any_upgrade_levels": {"slam_second_wave": 1}, "properties_true": {"ability_manager": ["slam_second_wave_enabled"]}},
		"effects": [
			{"target": "ability_manager", "property": "slam_second_wave_enabled", "operation": "set", "value": true},
			{"target": "ability_manager", "property": "slam_radius", "operation": "add", "value": 28.0},
			{"target": "ability_manager", "property": "slam_damage", "operation": "add", "value": 14},
			{"target": "ability_manager", "property": "slam_second_wave_radius_multiplier", "operation": "add", "value": 0.15, "max_value": 1.7},
		],
		"announcement": "Evolution: Earthbreaker Slam!",
	},
	{
		"id": "comet_engine",
		"title": "Comet Engine",
		"archetype": "dash",
		"description": "Evolve dash into a faster comet burst with stronger trail damage.",
		"prerequisites": {"archetype_points": {"dash": 4}, "any_upgrade_levels": {"dash_damage_trail": 1}, "properties_true": {"player": ["dash_damage_trail_enabled"]}},
		"effects": [
			{"target": "player", "property": "dash_damage_trail_enabled", "operation": "set", "value": true},
			{"target": "player", "property": "dash_cooldown", "operation": "subtract", "value": 0.12, "min_value": 0.45},
			{"target": "player", "property": "dash_trail_damage", "operation": "add", "value": 10},
			{"target": "player", "property": "dash_invulnerability_duration", "operation": "add", "value": 0.05, "max_value": 0.6},
		],
		"announcement": "Evolution: Comet Engine!",
	},
]


func setup(new_player: Node, new_auto_attack: Node, new_ability_manager: Node, new_upgrade_manager: Node) -> void:
	player = new_player
	auto_attack = new_auto_attack
	ability_manager = new_ability_manager
	upgrade_manager = new_upgrade_manager


func get_all_evolutions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for evolution in _evolutions:
		result.append(evolution.duplicate(true))
	return result


func get_available_evolutions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for evolution in _evolutions:
		if not has_evolution(str(evolution.get("id", ""))) and _meets_prerequisites(evolution):
			var data := evolution.duplicate(true)
			result.append(data)
			evolution_available.emit(data)
	return result


func has_evolution(evolution_id: String) -> bool:
	return _applied_evolutions.has(evolution_id)


func apply_evolution(evolution_id: String) -> bool:
	var evolution := _get_evolution(evolution_id)
	if evolution.is_empty() or has_evolution(evolution_id) or not _meets_prerequisites(evolution):
		return false
	var effects: Array = evolution.get("effects", [])
	if not _can_apply_effects(effects):
		push_warning("EvolutionManager: cannot apply evolution %s." % evolution_id)
		return false
	if not _apply_effects(effects):
		return false
	_applied_evolutions.append(evolution_id)
	evolution_applied.emit(evolution_id, evolution.duplicate(true))
	evolution_state_changed.emit()
	return true


func get_applied_evolutions() -> Array[String]:
	return _applied_evolutions.duplicate()


func get_applied_evolution_titles() -> Array[String]:
	var titles: Array[String] = []
	for evolution_id in _applied_evolutions:
		var evolution := _get_evolution(evolution_id)
		titles.append(str(evolution.get("title", evolution_id)))
	return titles


func debug_print_evolution_state() -> void:
	print("=== EvolutionManager ===")
	print("available=%d applied=%s" % [get_available_evolutions().size(), str(get_applied_evolution_titles())])
	print("========================")


func debug_get_evolution_state() -> Dictionary:
	return {
		"available_count": get_available_evolutions().size(),
		"applied_ids": get_applied_evolutions(),
		"applied_titles": get_applied_evolution_titles(),
	}


func _meets_prerequisites(evolution: Dictionary) -> bool:
	var prerequisites: Dictionary = evolution.get("prerequisites", {})
	var points: Dictionary = _get_archetype_points()
	var arch_reqs: Dictionary = prerequisites.get("archetype_points", {})
	for arch in arch_reqs:
		if int(points.get(arch, 0)) < int(arch_reqs[arch]):
			return false
	var any_levels: Dictionary = prerequisites.get("any_upgrade_levels", {})
	if not any_levels.is_empty():
		var any_level_met := false
		for upgrade_id in any_levels:
			if _has_upgrade(str(upgrade_id), int(any_levels[upgrade_id])):
				any_level_met = true
				break
		var any_property_met := _any_property_true(prerequisites.get("properties_true", {}))
		if not any_level_met and not any_property_met:
			return false
	return true


func _get_archetype_points() -> Dictionary:
	if upgrade_manager != null and upgrade_manager.has_method("get_archetype_points"):
		return upgrade_manager.get_archetype_points()
	return {}


func _has_upgrade(upgrade_id: String, min_level: int = 1) -> bool:
	if upgrade_manager != null and upgrade_manager.has_method("has_upgrade"):
		return upgrade_manager.has_upgrade(upgrade_id, min_level)
	if upgrade_manager != null and upgrade_manager.has_method("get_upgrade_level"):
		return int(upgrade_manager.get_upgrade_level(upgrade_id)) >= min_level
	return false


func _any_property_true(properties: Dictionary) -> bool:
	for target_id in properties:
		var target := _get_target(str(target_id))
		if target == null:
			continue
		var names: Array = properties[target_id]
		for property_name in names:
			var value = target.get(str(property_name))
			if value is bool and value:
				return true
	return false


func _can_apply_effects(effects: Array) -> bool:
	for effect in effects:
		var target := _get_target(str(effect.get("target", "")))
		var property_name := str(effect.get("property", ""))
		if target == null or property_name.is_empty() or target.get(property_name) == null:
			return false
	return true


func _apply_effects(effects: Array) -> bool:
	for effect in effects:
		var target := _get_target(str(effect.get("target", "")))
		var property_name := str(effect.get("property", ""))
		var operation := str(effect.get("operation", "add"))
		var value = effect.get("value", 0.0)
		var min_value = effect.get("min_value", null)
		var max_value = effect.get("max_value", null)
		var current = target.get(property_name)
		if current is bool:
			if operation != "set":
				return false
			target.set(property_name, bool(value))
		elif current is int:
			var next_int := int(current)
			match operation:
				"add": next_int += int(value)
				"subtract": next_int -= int(value)
				"multiply": next_int = int(float(current) * float(value))
				"set": next_int = int(value)
				_: return false
			if min_value != null:
				next_int = maxi(next_int, int(min_value))
			if max_value != null:
				next_int = mini(next_int, int(max_value))
			target.set(property_name, next_int)
		else:
			var next_float := float(current)
			match operation:
				"add": next_float += float(value)
				"subtract": next_float -= float(value)
				"multiply": next_float *= float(value)
				"set": next_float = float(value)
				_: return false
			if min_value != null:
				next_float = maxf(next_float, float(min_value))
			if max_value != null:
				next_float = minf(next_float, float(max_value))
			target.set(property_name, next_float)
	return true


func _get_target(target_id: String) -> Node:
	match target_id:
		"player": return player
		"auto_attack": return auto_attack
		"ability_manager": return ability_manager
	return null


func _get_evolution(evolution_id: String) -> Dictionary:
	for evolution in _evolutions:
		if str(evolution.get("id", "")) == evolution_id:
			return evolution
	return {}
