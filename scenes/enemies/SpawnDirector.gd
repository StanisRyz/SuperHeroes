extends Node

# Enemy roles (display/gameplay metadata)
# swarmer  = weak mass pressure      (grunt, swarm)
# hunter   = fast chase pressure     (runner, charger)
# bruiser  = slow durable block      (tank, shielded)
# shooter  = ranged pressure         (shooter)
# disruptor= special pressure        (exploder, support)

const BASE_SPAWN_INTERVAL := 1.5
const MIN_SPAWN_INTERVAL := 0.45
const BASE_MAX_ALIVE_ENEMIES := 12
const MAX_ALIVE_ENEMIES := 60

var run_manager: Node
var active_event_modifiers: Dictionary = {}
var _stage_profile: String = "balanced"
var _last_wave_package_id: String = ""

var _stage_profile_weight_bonuses: Dictionary = {
	"ranged_support": {"shooter": 1.25, "support": 1.25},
	"swarm_exploder": {"exploder": 1.3, "swarm": 1.3},
}

# Wave packages — each defines a role-themed burst of enemies.
# variant_pool: ids to pick from; min/max_count: how many to spawn.
# weight: selection probability; unlock_time: seconds before package is available.
# profile_bonus: per stage-profile weight multiplier (stacks with base weight).
const WAVE_PACKAGES: Array = [
	{
		"id": "early_grunts",
		"role": "swarmer",
		"variant_pool": ["grunt"],
		"min_count": 2, "max_count": 3,
		"weight": 1.2,
		"unlock_time": 0.0,
		"profile_bonus": {},
	},
	{
		"id": "runner_pack",
		"role": "hunter",
		"variant_pool": ["runner"],
		"min_count": 2, "max_count": 3,
		"weight": 1.0,
		"unlock_time": 30.0,
		"profile_bonus": {},
	},
	{
		"id": "bruiser_wall",
		"role": "bruiser",
		"variant_pool": ["tank"],
		"min_count": 1, "max_count": 2,
		"weight": 0.7,
		"unlock_time": 60.0,
		"profile_bonus": {"balanced": 1.2},
	},
	{
		"id": "shooter_screen",
		"role": "shooter",
		"variant_pool": ["shooter"],
		"min_count": 1, "max_count": 2,
		"weight": 0.7,
		"unlock_time": 75.0,
		"profile_bonus": {"ranged_support": 1.5},
	},
	{
		"id": "exploder_pressure",
		"role": "disruptor",
		"variant_pool": ["exploder"],
		"min_count": 1, "max_count": 2,
		"weight": 0.65,
		"unlock_time": 120.0,
		"profile_bonus": {"swarm_exploder": 1.5},
	},
	{
		"id": "swarm_rush",
		"role": "swarmer",
		"variant_pool": ["swarm"],
		"min_count": 2, "max_count": 4,
		"weight": 0.85,
		"unlock_time": 150.0,
		"profile_bonus": {"swarm_exploder": 1.5},
	},
	{
		"id": "shielded_push",
		"role": "bruiser",
		"variant_pool": ["shielded"],
		"min_count": 1, "max_count": 2,
		"weight": 0.6,
		"unlock_time": 180.0,
		"profile_bonus": {},
	},
	{
		"id": "support_pair",
		"role": "disruptor",
		"variant_pool": ["support"],
		"min_count": 1, "max_count": 2,
		"weight": 0.55,
		"unlock_time": 210.0,
		"profile_bonus": {"ranged_support": 1.4},
	},
	{
		"id": "mixed_late_wave",
		"role": "mixed",
		"variant_pool": ["runner", "tank", "shooter"],
		"min_count": 2, "max_count": 3,
		"weight": 0.65,
		"unlock_time": 240.0,
		"profile_bonus": {"balanced": 1.3},
	},
]

func setup(new_run_manager: Node) -> void:
	run_manager = new_run_manager


func set_stage_profile(profile: String) -> void:
	_stage_profile = profile


func apply_event_modifier(event_data: Dictionary) -> void:
	active_event_modifiers[event_data["id"]] = event_data.get("modifier", {})


func clear_event_modifier(event_id: String) -> void:
	active_event_modifiers.erase(event_id)


func get_spawn_interval() -> float:
	var seconds := _get_run_time()
	var progress := clampf(seconds / 240.0, 0.0, 1.0)
	var base_interval := lerpf(BASE_SPAWN_INTERVAL, MIN_SPAWN_INTERVAL, progress)
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


# --- Wave Director ---

# Returns the interval (seconds) between wave package spawns.
func get_wave_interval() -> float:
	var seconds := _get_run_time()
	if seconds < 60.0:
		return 14.0
	elif seconds < 180.0:
		return 12.0
	elif seconds < 300.0:
		return 10.0
	else:
		return 8.0


# Selects and builds a wave package for the current run time and stage profile.
# Returns a dict with id, role, variant_ids (the actual list of ids to spawn).
# Returns {} if no package is available yet.
func get_wave_package() -> Dictionary:
	var seconds := _get_run_time()
	var available := _get_available_packages(seconds)
	if available.is_empty():
		return {}

	var total := 0.0
	for pkg in available:
		total += _get_package_weight(pkg)

	if total <= 0.0:
		_last_wave_package_id = str(available[0].get("id", ""))
		return _build_package_spawn(available[0], seconds)

	var roll := randf() * total
	var cursor := 0.0
	for pkg in available:
		cursor += _get_package_weight(pkg)
		if roll <= cursor:
			_last_wave_package_id = str(pkg.get("id", ""))
			return _build_package_spawn(pkg, seconds)

	_last_wave_package_id = str(available[0].get("id", ""))
	return _build_package_spawn(available[0], seconds)


func debug_get_wave_state() -> Dictionary:
	return {
		"stage_profile": _stage_profile,
		"last_wave_package": _last_wave_package_id,
		"wave_interval": get_wave_interval(),
	}


# --- Internal helpers ---

func _get_available_packages(seconds: float) -> Array:
	# Build a fast lookup of which variant ids are available at this time.
	var available_variants := _get_available_variants(seconds)
	var available_ids: Dictionary = {}
	for v in available_variants:
		available_ids[str(v.get("id", ""))] = true

	var result: Array = []
	for pkg in WAVE_PACKAGES:
		if seconds < float(pkg.get("unlock_time", 0.0)):
			continue
		var pool: Array = pkg.get("variant_pool", [])
		var all_ok := true
		for vid in pool:
			if not available_ids.has(str(vid)):
				all_ok = false
				break
		if all_ok:
			result.append(pkg)
	return result


func _get_package_weight(pkg: Dictionary) -> float:
	var weight := float(pkg.get("weight", 1.0))
	var bonus: Dictionary = pkg.get("profile_bonus", {})
	if bonus.has(_stage_profile):
		weight *= float(bonus[_stage_profile])
	return maxf(weight, 0.0)


func _build_package_spawn(pkg: Dictionary, seconds: float) -> Dictionary:
	var pool: Array = pkg.get("variant_pool", [])
	var min_c: int = int(pkg.get("min_count", 1))
	var max_c: int = int(pkg.get("max_count", 2))

	# Gradually increase max count after 300 s (late game), capped at +2.
	if seconds >= 300.0:
		max_c = mini(max_c + 1, max_c + 2)

	var count: int = randi_range(min_c, max_c)

	var ids: Array[String] = []
	for i in range(count):
		ids.append(str(pool[randi() % pool.size()]))

	return {
		"id": str(pkg.get("id", "")),
		"role": str(pkg.get("role", "")),
		"variant_ids": ids,
	}


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
			"role": "swarmer",
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
			"role": "hunter",
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
			"role": "hunter",
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
			"role": "bruiser",
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
			"role": "shooter",
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
			"role": "disruptor",
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
			"role": "swarmer",
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
			"role": "bruiser",
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
			"role": "disruptor",
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
	if _stage_profile_weight_bonuses.has(_stage_profile):
		var bonuses: Dictionary = _stage_profile_weight_bonuses[_stage_profile]
		if bonuses.has(variant_id):
			weight *= float(bonuses[variant_id])
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
