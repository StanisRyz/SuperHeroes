extends Node

const BASE_SPAWN_INTERVAL := 1.5
const MIN_SPAWN_INTERVAL := 0.45
const BASE_MAX_ALIVE_ENEMIES := 12
const MAX_ALIVE_ENEMIES := 60

var run_manager: Node

func setup(new_run_manager: Node) -> void:
	run_manager = new_run_manager


func get_spawn_interval() -> float:
	var seconds := _get_run_time()
	var progress := clampf(seconds / 240.0, 0.0, 1.0)
	return lerpf(BASE_SPAWN_INTERVAL, MIN_SPAWN_INTERVAL, progress)


func get_max_alive_enemies() -> int:
	var seconds := _get_run_time()
	var progress := clampf(seconds / 300.0, 0.0, 1.0)
	return int(round(lerpf(BASE_MAX_ALIVE_ENEMIES, MAX_ALIVE_ENEMIES, progress)))


func get_enemy_variant() -> Dictionary:
	var seconds := _get_run_time()
	var variants := _get_available_variants(seconds)
	var total_weight := 0.0

	for variant in variants:
		total_weight += float(variant.get("weight", 1.0))

	var roll := randf() * total_weight
	var weight_cursor := 0.0
	for variant in variants:
		weight_cursor += float(variant.get("weight", 1.0))
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
			"speed": 175.0,
			"max_health": 14,
			"contact_damage": 10,
			"experience_value": 1,
			"body_color": Color(0.95, 0.55, 0.12, 1.0),
			"core_color": Color(0.42, 0.16, 0.02, 1.0),
			"weight": clampf((seconds - 30.0) / 90.0, 0.25, 1.4),
		})

	if seconds >= 60.0:
		variants.append({
			"id": "tank",
			"display_name": "Tank",
			"speed": 85.0,
			"max_health": 55,
			"contact_damage": 18,
			"experience_value": 3,
			"body_color": Color(0.42, 0.26, 0.72, 1.0),
			"core_color": Color(0.14, 0.08, 0.32, 1.0),
			"weight": clampf((seconds - 60.0) / 150.0, 0.15, 0.85),
		})

	return variants
