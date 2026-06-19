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

	# Check for weight boost modifiers from active events
	var boost_runner := false
	var boost_tank := false
	for mod_id in active_event_modifiers:
		var mod: Dictionary = active_event_modifiers[mod_id]
		if mod.get("boost_runner_weight", false):
			boost_runner = true
		if mod.get("boost_tank_weight", false):
			boost_tank = true

	var total_weight := 0.0
	for variant in variants:
		var w := float(variant.get("weight", 1.0))
		var vid: String = variant.get("id", "")
		if boost_runner and vid == "runner":
			w *= 3.0
		if boost_tank and vid == "tank":
			w *= 3.0
		total_weight += w

	var roll := randf() * total_weight
	var weight_cursor := 0.0
	for variant in variants:
		var w := float(variant.get("weight", 1.0))
		var vid: String = variant.get("id", "")
		if boost_runner and vid == "runner":
			w *= 3.0
		if boost_tank and vid == "tank":
			w *= 3.0
		weight_cursor += w
		if roll <= weight_cursor:
			var selected := variant.duplicate()
			selected.erase("weight")
			return selected

	var fallback := variants[0].duplicate()
	fallback.erase("weight")
	return fallback


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

	return variants
