extends Node

const BASE_SPAWN_INTERVAL := 1.5
const MIN_SPAWN_INTERVAL := 0.45
const BASE_MAX_ALIVE_ENEMIES := 12
const MAX_ALIVE_ENEMIES := 60

var run_manager: Node
var active_event_modifiers: Dictionary = {}

func setup(new_run_manager: Node) -> void:
	run_manager = new_run_manager


func apply_event_modifier(event_data: Dictionary) -> void:
	active_event_modifiers[event_data["id"]] = event_data.get("modifier", {})


func clear_event_modifier(event_id: String) -> void:
	active_event_modifiers.erase(event_id)


func get_spawn_interval() -> float:
	var seconds := _get_run_time()
	var progress := clampf(seconds / 240.0, 0.0, 1.0)
	var base_interval := lerpf(BASE_SPAWN_INTERVAL, MIN_SPAWN_INTERVAL, progress)
	# Apply spawn_pressure modifiers from active events
	var spawn_pressure := 1.0
	for mod_id in active_event_modifiers:
		var mod: Dictionary = active_event_modifiers[mod_id]
		if mod.has("spawn_pressure"):
			spawn_pressure *= float(mod["spawn_pressure"])
	if spawn_pressure != 1.0:
		base_interval = maxf(base_interval / spawn_pressure, 0.05)
	return base_interval


func get_max_alive_enemies() -> int:
	var seconds := _get_run_time()
	var progress := clampf(seconds / 300.0, 0.0, 1.0)
	var base_max := int(round(lerpf(BASE_MAX_ALIVE_ENEMIES, MAX_ALIVE_ENEMIES, progress)))
	# Apply max_alive_bonus modifiers from active events
	var bonus := 0
	for mod_id in active_event_modifiers:
		var mod: Dictionary = active_event_modifiers[mod_id]
		if mod.has("max_alive_bonus"):
			bonus += int(mod["max_alive_bonus"])
	return base_max + bonus


func get_enemy_variant() -> Dictionary:
	var seconds := _get_run_time()
	var variants := _get_available_variants(seconds)
	if variants.is_empty():
		return {}

	var total_weight := 0.0
	for variant in variants:
		total_weight += _get_modified_weight(variant)

	if total_weight <= 0.0:
		return _strip_weight(variants[0])

	var roll := randf() * total_weight
	var weight_cursor := 0.0
	for variant in variants:
		weight_cursor += _get_modified_weight(variant)
		if roll <= weight_cursor:
			return _strip_weight(variant)

	return _strip_weight(variants[0])


func get_enemy_variant_by_id(variant_id: String) -> Dictionary:
	for variant in _get_available_variants(9999.0):
		if str(variant.get("id", "")) == variant_id:
			return _strip_weight(variant)

	return {}


func _get_run_time() -> float:
	if run_manager == null:
		return 0.0

	var value = run_manager.get("run_time")
	return float(value) if value != null else 0.0


func _get_available_variants(seconds: float) -> Array[Dictionary]:
	var variants: Array[Dictionary] = [
		{
			"id": "grunt",
			"display_name": "Grunt",
			"behavior_id": "chase",
			"speed": 120.0,
			"max_health": 20,
			"contact_damage": 10,
			"experience_value": 1,
			"body_color": Color(0.83, 0.12, 0.24, 1.0),
			"core_color": Color(0.34, 0.04, 0.1, 1.0),
			"weight": 1.0,
		},
	]

	if seconds >= 30.0:
		variants.append({
			"id": "runner",
			"display_name": "Runner",
			"behavior_id": "chase",
			"speed": 175.0,
			"max_health": 14,
			"contact_damage": 10,
			"experience_value": 1,
			"body_color": Color(0.95, 0.55, 0.12, 1.0),
			"core_color": Color(0.42, 0.16, 0.02, 1.0),
			"weight": clampf((seconds - 30.0) / 90.0, 0.25, 1.4),
		})

	if seconds >= 45.0:
		variants.append({
			"id": "charger",
			"display_name": "Charger",
			"behavior_id": "charger",
			"speed": 150.0,
			"max_health": 32,
			"contact_damage": 13,
			"experience_value": 2,
			"body_color": Color(0.1, 0.68, 0.62, 1.0),
			"core_color": Color(0.02, 0.26, 0.28, 1.0),
			"charge_range": 360.0,
			"charge_windup": 0.35,
			"charge_speed_multiplier": 2.4,
			"charge_duration": 0.45,
			"charge_cooldown": 2.2,
			"weight": clampf((seconds - 45.0) / 120.0, 0.15, 0.9),
		})

	if seconds >= 60.0:
		variants.append({
			"id": "tank",
			"display_name": "Tank",
			"behavior_id": "chase",
			"speed": 85.0,
			"max_health": 55,
			"contact_damage": 18,
			"experience_value": 3,
			"body_color": Color(0.42, 0.26, 0.72, 1.0),
			"core_color": Color(0.14, 0.08, 0.32, 1.0),
			"weight": clampf((seconds - 60.0) / 150.0, 0.15, 0.85),
		})

	if seconds >= 75.0:
		variants.append({
			"id": "shooter",
			"display_name": "Shooter",
			"behavior_id": "shooter",
			"speed": 90.0,
			"max_health": 24,
			"contact_damage": 9,
			"experience_value": 2,
			"body_color": Color(0.24, 0.42, 0.95, 1.0),
			"core_color": Color(0.05, 0.12, 0.38, 1.0),
			"preferred_distance": 430.0,
			"shoot_range": 560.0,
			"shoot_interval": 1.8,
			"projectile_damage": 8,
			"projectile_speed": 360.0,
			"weight": clampf((seconds - 75.0) / 150.0, 0.1, 0.75),
		})

	if seconds >= 120.0:
		variants.append({
			"id": "exploder",
			"display_name": "Exploder",
			"behavior_id": "exploder",
			"speed": 135.0,
			"max_health": 26,
			"contact_damage": 6,
			"experience_value": 2,
			"body_color": Color(1.0, 0.22, 0.08, 1.0),
			"core_color": Color(1.0, 0.72, 0.08, 1.0),
			"explode_radius": 115.0,
			"explode_damage": 22,
			"explode_windup": 0.65,
			"explode_trigger_distance": 70.0,
			"weight": clampf((seconds - 120.0) / 160.0, 0.1, 0.7),
		})

	if seconds >= 150.0:
		variants.append({
			"id": "swarm",
			"display_name": "Swarm",
			"behavior_id": "swarm",
			"speed": 205.0,
			"max_health": 12,
			"contact_damage": 7,
			"experience_value": 1,
			"body_color": Color(0.05, 0.95, 0.76, 1.0),
			"core_color": Color(0.02, 0.34, 0.18, 1.0),
			"orbit_distance": 135.0,
			"orbit_strength": 0.85,
			"orbit_direction": 1.0,
			"approach_distance": 230.0,
			"weight": clampf((seconds - 150.0) / 180.0, 0.1, 0.8),
		})

	if seconds >= 180.0:
		variants.append({
			"id": "shielded",
			"display_name": "Shielded",
			"behavior_id": "chase",
			"speed": 105.0,
			"max_health": 42,
			"contact_damage": 14,
			"experience_value": 3,
			"body_color": Color(0.26, 0.56, 1.0, 1.0),
			"core_color": Color(0.86, 0.95, 1.0, 1.0),
			"shield_value": 28,
			"weight": clampf((seconds - 180.0) / 190.0, 0.1, 0.7),
		})

	if seconds >= 210.0:
		variants.append({
			"id": "support",
			"display_name": "Support",
			"behavior_id": "support",
			"speed": 82.0,
			"max_health": 34,
			"contact_damage": 7,
			"experience_value": 3,
			"body_color": Color(0.7, 0.22, 0.95, 1.0),
			"core_color": Color(1.0, 0.86, 0.18, 1.0),
			"support_radius": 300.0,
			"support_interval": 4.0,
			"support_damage_multiplier": 1.25,
			"support_speed_multiplier": 1.18,
			"support_buff_duration": 5.0,
			"weight": clampf((seconds - 210.0) / 210.0, 0.1, 0.55),
		})

	return variants


func _get_modified_weight(variant: Dictionary) -> float:
	var weight := float(variant.get("weight", 1.0))
	var variant_id := str(variant.get("id", ""))
	for mod_id in active_event_modifiers:
		var mod: Dictionary = active_event_modifiers[mod_id]
		if mod.get("boost_runner_weight", false) and variant_id == "runner":
			weight *= 3.0
		if mod.get("boost_tank_weight", false) and variant_id == "tank":
			weight *= 3.0
		if mod.get("boost_special_weight", false) and ["charger", "shooter", "exploder", "swarm", "shielded", "support"].has(variant_id):
			weight *= 1.5
		var boosted: Dictionary = mod.get("boost_variant_weights", {})
		if boosted.has(variant_id):
			weight *= float(boosted[variant_id])

	return maxf(weight, 0.0)


func _strip_weight(variant: Dictionary) -> Dictionary:
	var selected := variant.duplicate()
	selected.erase("weight")
	return selected
