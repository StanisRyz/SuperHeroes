extends Node

const CATEGORIES: Array[String] = ["stats", "autoattack", "ability_1", "ability_2", "ability_3", "passive"]
const REQUIRED_KEYS: Array[String] = [
	"id", "hero_id", "name", "category", "max_level", "cost_base", "cost_growth",
	"effect_type", "effect_per_level", "target", "tags",
]

var _training_nodes: Array[Dictionary] = []
var _nodes_by_id: Dictionary = {}
var _duplicate_ids: Array[String] = []
var _invalid_nodes: Array[Dictionary] = []
var _missing_hero_id: Array[String] = []


func _ready() -> void:
	_build_nodes()
	_rebuild_index()


func get_all_training_nodes() -> Array[Dictionary]:
	_ensure_index()
	var result: Array[Dictionary] = []
	for node in _training_nodes:
		result.append(node.duplicate(true))
	return result


func get_training_nodes_for_hero(hero_id: String) -> Array[Dictionary]:
	_ensure_index()
	var result: Array[Dictionary] = []
	for node in _training_nodes:
		if str(node.get("hero_id", "")) == hero_id:
			result.append(node.duplicate(true))
	return result


func get_training_nodes_for_category(hero_id: String, category: String) -> Array[Dictionary]:
	_ensure_index()
	var result: Array[Dictionary] = []
	if category not in CATEGORIES:
		return result
	for node in _training_nodes:
		if str(node.get("hero_id", "")) == hero_id and str(node.get("category", "")) == category:
			result.append(node.duplicate(true))
	return result


func get_training_node(node_id: String) -> Dictionary:
	_ensure_index()
	var node: Dictionary = _nodes_by_id.get(node_id, {})
	return node.duplicate(true) if not node.is_empty() else {}


func get_categories() -> Array[String]:
	return CATEGORIES.duplicate()


func is_valid_training_node(node_id: String) -> bool:
	_ensure_index()
	return _nodes_by_id.has(node_id)


func is_training_node_for_hero(node_id: String, hero_id: String) -> bool:
	var node := get_training_node(node_id)
	return not node.is_empty() and str(node.get("hero_id", "")) == hero_id


func debug_get_training_node_summary() -> Dictionary:
	_ensure_index()
	var nodes_by_hero := {}
	var nodes_by_category := {}
	var category_presence := {}
	for node in _training_nodes:
		var hero_id := str(node.get("hero_id", ""))
		var category := str(node.get("category", ""))
		nodes_by_hero[hero_id] = int(nodes_by_hero.get(hero_id, 0)) + 1
		nodes_by_category[category] = int(nodes_by_category.get(category, 0)) + 1
		if not category_presence.has(hero_id):
			category_presence[hero_id] = {}
		var hero_categories: Dictionary = category_presence.get(hero_id, {})
		hero_categories[category] = int(hero_categories.get(category, 0)) + 1
		category_presence[hero_id] = hero_categories

	var missing_categories := {}
	for hero_id in category_presence:
		var hero_missing: Array[String] = []
		var hero_categories: Dictionary = category_presence.get(hero_id, {})
		for category in CATEGORIES:
			if int(hero_categories.get(category, 0)) <= 0:
				hero_missing.append(category)
		if not hero_missing.is_empty():
			missing_categories[str(hero_id)] = hero_missing

	return {
		"total_nodes": _training_nodes.size(),
		"nodes_by_hero": nodes_by_hero,
		"nodes_by_category": nodes_by_category,
		"invalid_nodes": _invalid_nodes.duplicate(true),
		"missing_hero_id": _missing_hero_id.duplicate(),
		"duplicate_ids": _duplicate_ids.duplicate(),
		"missing_categories": missing_categories,
		"categories": get_categories(),
	}


func _ensure_index() -> void:
	if _training_nodes.is_empty():
		_build_nodes()
	if _nodes_by_id.is_empty():
		_rebuild_index()


func _build_nodes() -> void:
	_training_nodes = [
		_make_node("guardian_radiant_vitality", "guardian", "Radiant Vitality", "stats", "hero_stats", "max_health", 5.0, 60, 1.25, ["stats", "health", "guardian"], "Increases Solar Guardian max health.", 10),
		_make_node("guardian_solar_might", "guardian", "Solar Might", "stats", "hero_stats", "base_damage", 1.0, 70, 1.25, ["stats", "damage", "guardian"], "Increases Solar Guardian base damage.", 11),
		_make_node("guardian_sunforged_guard", "guardian", "Sunforged Guard", "stats", "hero_stats", "defense", 1.0, 80, 1.25, ["stats", "defense", "guardian"], "Increases Solar Guardian Defense.", 12),
		_make_node("guardian_beam_focus", "guardian", "Beam Focus", "autoattack", "autoattack", "autoattack_damage", 1.0, 55, 1.25, ["autoattack", "solar_ray"], "Improves Solar Ray autoattack damage.", 20),
		_make_node("guardian_solar_ray_intensity", "guardian", "Solar Ray Intensity", "ability_1", "ability_1", "ability_damage", 1.0, 60, 1.28, ["ability", "solar_beam"], "Improves Solar Beam damage.", 30),
		_make_node("guardian_ice_breath_control", "guardian", "Ice Breath Control", "ability_2", "ability_2", "slow_strength", 0.02, 60, 1.28, ["ability", "frost_breath", "control"], "Improves Frost Breath slow strength.", 40),
		_make_node("guardian_deadly_dash_force", "guardian", "Deadly Dash Force", "ability_3", "ability_3", "ability_damage", 1.0, 65, 1.30, ["ability", "death_dash"], "Improves Death Dash damage.", 50),
		_make_node("guardian_solar_energy_flow", "guardian", "Solar Energy Flow", "passive", "passive", "passive_gain", 0.5, 70, 1.30, ["passive", "solar_energy"], "Improves Solar Energy generation.", 60),

		_make_node("blaster_field_conditioning", "blaster", "Field Conditioning", "stats", "hero_stats", "max_health", 5.0, 60, 1.25, ["stats", "health", "blaster"], "Increases Night Tactician max health.", 10),
		_make_node("blaster_tactical_precision", "blaster", "Tactical Precision", "stats", "hero_stats", "base_damage", 1.0, 70, 1.25, ["stats", "damage", "blaster"], "Increases Night Tactician base damage.", 11),
		_make_node("blaster_smoke_discipline", "blaster", "Smoke Discipline", "stats", "hero_stats", "defense", 1.0, 80, 1.25, ["stats", "defense", "blaster"], "Increases Night Tactician Defense.", 12),
		_make_node("blaster_rocket_calibration", "blaster", "Rocket Calibration", "autoattack", "autoattack", "autoattack_damage", 1.0, 55, 1.25, ["autoattack", "rocket"], "Improves homing rocket damage.", 20),
		_make_node("blaster_smoke_density", "blaster", "Smoke Density", "ability_1", "ability_1", "ability_defense", 0.01, 60, 1.28, ["ability", "smoke_screen", "defense"], "Improves Smoke Screen protection.", 30),
		_make_node("blaster_trap_engineering", "blaster", "Trap Engineering", "ability_2", "ability_2", "ability_damage", 1.0, 60, 1.28, ["ability", "trap"], "Improves Explosive Trap damage.", 40),
		_make_node("blaster_hook_impact", "blaster", "Hook Impact", "ability_3", "ability_3", "ability_damage", 1.0, 65, 1.30, ["ability", "grappling_hook"], "Improves Grappling Hook damage.", 50),
		_make_node("blaster_mark_exploitation", "blaster", "Mark Exploitation", "passive", "passive", "mark_damage", 1.0, 70, 1.30, ["passive", "tactical_mark"], "Improves Tactical Mark follow-up damage.", 60),

		_make_node("vanguard_battle_conditioning", "vanguard", "Battle Conditioning", "stats", "hero_stats", "max_health", 5.0, 60, 1.25, ["stats", "health", "vanguard"], "Increases Fury Vanguard max health.", 10),
		_make_node("vanguard_brutal_strength", "vanguard", "Brutal Strength", "stats", "hero_stats", "base_damage", 1.0, 70, 1.25, ["stats", "damage", "vanguard"], "Increases Fury Vanguard base damage.", 11),
		_make_node("vanguard_pain_tolerance", "vanguard", "Pain Tolerance", "stats", "hero_stats", "defense", 1.0, 80, 1.25, ["stats", "defense", "vanguard"], "Increases Fury Vanguard Defense.", 12),
		_make_node("vanguard_heavy_swing", "vanguard", "Heavy Swing", "autoattack", "autoattack", "autoattack_damage", 1.0, 55, 1.25, ["autoattack", "splash_melee"], "Improves Fury Strikes damage.", 20),
		_make_node("vanguard_rage_wave_force", "vanguard", "Rage Wave Force", "ability_1", "ability_1", "ability_damage", 1.0, 60, 1.28, ["ability", "rage_wave"], "Improves Rage Wave damage.", 30),
		_make_node("vanguard_power_clap_impact", "vanguard", "Power Clap Impact", "ability_2", "ability_2", "knockback_power", 0.02, 60, 1.28, ["ability", "mighty_clap", "control"], "Improves Mighty Clap impact.", 40),
		_make_node("vanguard_rage_jump_landing", "vanguard", "Rage Jump Landing", "ability_3", "ability_3", "ability_damage", 1.0, 65, 1.30, ["ability", "rage_leap"], "Improves Rage Leap landing damage.", 50),
		_make_node("vanguard_rage_control", "vanguard", "Rage Control", "passive", "passive", "rage_gain", 0.5, 70, 1.30, ["passive", "rage"], "Improves Rage generation.", 60),
	]


func _make_node(node_id: String, hero_id: String, node_name: String, category: String, target: String, effect_type: String, effect_per_level: float, cost_base: int, cost_growth: float, tags: Array[String], short_description: String, sort_order: int) -> Dictionary:
	return {
		"id": node_id,
		"hero_id": hero_id,
		"name": node_name,
		"title": node_name,
		"category": category,
		"max_level": 10,
		"cost_base": cost_base,
		"base_cost": cost_base,
		"cost_growth": cost_growth,
		"effect_type": effect_type,
		"effect_per_level": effect_per_level,
		"target": target,
		"tags": tags.duplicate(),
		"short_description": short_description,
		"description": short_description,
		"sort_order": sort_order,
	}


func _rebuild_index() -> void:
	_nodes_by_id.clear()
	_duplicate_ids.clear()
	_invalid_nodes.clear()
	_missing_hero_id.clear()
	var seen := {}
	for node in _training_nodes:
		var node_id := str(node.get("id", ""))
		if node_id.is_empty() or seen.has(node_id):
			if not node_id.is_empty() and node_id not in _duplicate_ids:
				_duplicate_ids.append(node_id)
			_invalid_nodes.append(node.duplicate(true))
			continue
		seen[node_id] = true
		if not _is_valid_node_schema(node):
			_invalid_nodes.append(node.duplicate(true))
			continue
		_nodes_by_id[node_id] = node


func _is_valid_node_schema(node: Dictionary) -> bool:
	for key in REQUIRED_KEYS:
		if not node.has(key):
			return false
	var node_id := str(node.get("id", ""))
	var hero_id := str(node.get("hero_id", ""))
	var category := str(node.get("category", ""))
	if node_id.is_empty():
		return false
	if hero_id.is_empty():
		_missing_hero_id.append(node_id)
		return false
	if category not in CATEGORIES:
		return false
	return true
