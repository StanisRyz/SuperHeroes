extends Node

signal currency_changed(amount: int)
signal meta_upgrade_changed(upgrade_id: String, level: int)
signal hero_unlock_changed(hero_id: String, unlocked: bool)
signal progress_loaded
signal progress_saved

const SAVE_PATH := "user://superheroes_meta_progress.json"
const SAVE_VERSION := 4
const DEFAULT_HERO_ID := "guardian"
const DEFAULT_HERO_IDS: Array[String] = ["guardian", "blaster", "vanguard"]
const DEFAULT_STAGE_IDS: Array[String] = ["city_rooftop", "neon_lab", "wasteland_gate"]
const EQUIPMENT_SLOT_IDS: Array[String] = ["core", "suit", "emblem", "gauntlets", "boots", "artifact"]

var _data: Dictionary = {}
var _newly_completed_goals: Array[Dictionary] = []


func _ready() -> void:
	load_progress()


func load_progress() -> void:
	_data = _get_defaults()
	if not FileAccess.file_exists(SAVE_PATH):
		progress_loaded.emit()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("MetaProgressionManager: cannot open save file. Starting fresh.")
		progress_loaded.emit()
		return
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		push_warning("MetaProgressionManager: corrupt save file. Starting fresh.")
		progress_loaded.emit()
		return
	var parsed = json.get_data()
	if not parsed is Dictionary:
		push_warning("MetaProgressionManager: unexpected save format. Starting fresh.")
		progress_loaded.emit()
		return
	_merge_with_defaults(parsed)
	progress_loaded.emit()


func save_progress() -> void:
	_sync_legacy_meta_upgrades()
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("MetaProgressionManager: cannot write save file.")
		return
	file.store_string(JSON.stringify(_data, "\t"))
	file.close()
	progress_saved.emit()


func reset_progress() -> void:
	_data = _get_defaults()
	save_progress()
	currency_changed.emit(int(_data.get("currency", 0)))


func get_currency() -> int:
	return int(_data.get("currency", 0))


func add_currency(amount: int) -> void:
	if amount <= 0:
		return
	_data["currency"] = get_currency() + amount
	currency_changed.emit(get_currency())


func spend_currency(amount: int) -> bool:
	if amount <= 0:
		return true
	if get_currency() < amount:
		return false
	_data["currency"] = get_currency() - amount
	currency_changed.emit(get_currency())
	return true


func get_training_level(hero_id: String, upgrade_id: String) -> int:
	var resolved_hero_id := _resolve_hero_id(hero_id)
	ensure_training_data_for_hero(resolved_hero_id)
	var training_by_hero: Dictionary = _data.get("training_by_hero", {})
	var hero_training: Dictionary = training_by_hero.get(resolved_hero_id, {})
	return int(hero_training.get(upgrade_id, 0))


func set_training_level(hero_id: String, upgrade_id: String, level: int) -> void:
	var resolved_hero_id := _resolve_hero_id(hero_id)
	ensure_training_data_for_hero(resolved_hero_id)
	var def := get_meta_upgrade_definition(upgrade_id)
	var max_level := int(def.get("max_level", 99)) if not def.is_empty() else 99
	var clamped_level := clampi(level, 0, max_level)
	var training_by_hero: Dictionary = _data.get("training_by_hero", {})
	var hero_training: Dictionary = training_by_hero.get(resolved_hero_id, {})
	hero_training[upgrade_id] = clamped_level
	training_by_hero[resolved_hero_id] = hero_training
	_data["training_by_hero"] = training_by_hero
	meta_upgrade_changed.emit(upgrade_id, clamped_level)


func get_training_levels_for_hero(hero_id: String) -> Dictionary:
	var resolved_hero_id := _resolve_hero_id(hero_id)
	ensure_training_data_for_hero(resolved_hero_id)
	var training_by_hero: Dictionary = _data.get("training_by_hero", {})
	var hero_training: Dictionary = training_by_hero.get(resolved_hero_id, {})
	return hero_training.duplicate()


func get_training_summary_for_hero(hero_id: String) -> Dictionary:
	var resolved_hero_id := _resolve_hero_id(hero_id)
	return {
		"hero_id": resolved_hero_id,
		"currency": get_currency(),
		"levels": get_training_levels_for_hero(resolved_hero_id),
		"equipment": get_equipment_summary_for_hero(resolved_hero_id),
	}


func get_equipment_definitions(hero_id: String = "") -> Array[Dictionary]:
	var resolved_hero_id := _resolve_hero_id(hero_id)
	var result: Array[Dictionary] = []
	for def in _get_all_equipment_definitions():
		if hero_id.is_empty() or str(def.get("hero_id", "")) == resolved_hero_id:
			result.append(def.duplicate(true))
	return result


func get_equipment_definition(hero_id: String, equipment_id: String) -> Dictionary:
	var resolved_hero_id := _resolve_hero_id(hero_id)
	for def in _get_all_equipment_definitions():
		if str(def.get("hero_id", "")) == resolved_hero_id and str(def.get("equipment_id", "")) == equipment_id:
			return def.duplicate(true)
	return {}


func get_equipment_level(hero_id: String, equipment_id: String) -> int:
	var resolved_hero_id := _resolve_hero_id(hero_id)
	ensure_equipment_data_for_hero(resolved_hero_id)
	var equipment_by_hero: Dictionary = _data.get("equipment_by_hero", {})
	var hero_equipment: Dictionary = equipment_by_hero.get(resolved_hero_id, {})
	return int(hero_equipment.get(equipment_id, 0))


func get_equipment_levels_for_hero(hero_id: String) -> Dictionary:
	var resolved_hero_id := _resolve_hero_id(hero_id)
	ensure_equipment_data_for_hero(resolved_hero_id)
	var equipment_by_hero: Dictionary = _data.get("equipment_by_hero", {})
	var hero_equipment: Dictionary = equipment_by_hero.get(resolved_hero_id, {})
	return hero_equipment.duplicate()


func get_equipment_summary_for_hero(hero_id: String) -> Dictionary:
	var resolved_hero_id := _resolve_hero_id(hero_id)
	ensure_equipment_data_for_hero(resolved_hero_id)
	var defs := get_equipment_definitions(resolved_hero_id)
	var levels := get_equipment_levels_for_hero(resolved_hero_id)
	var upgraded_count := 0
	var total_levels := 0
	var max_total_levels := 0
	for def in defs:
		var equipment_id := str(def.get("equipment_id", ""))
		var level := int(levels.get(equipment_id, 0))
		if level > 0:
			upgraded_count += 1
		total_levels += level
		max_total_levels += int(def.get("max_level", 0))
	return {
		"hero_id": resolved_hero_id,
		"equipment_count": defs.size(),
		"upgraded_count": upgraded_count,
		"total_levels": total_levels,
		"max_total_levels": max_total_levels,
		"levels": levels,
	}


func debug_get_equipment_summary() -> Dictionary:
	var result := {}
	for hero_id in DEFAULT_HERO_IDS:
		result[hero_id] = get_equipment_summary_for_hero(hero_id)
	return result


func can_purchase_equipment_upgrade(_hero_id: String, _equipment_id: String) -> bool:
	return false


func purchase_equipment_upgrade(_hero_id: String, _equipment_id: String) -> bool:
	return false


func get_debug_training_summary() -> Dictionary:
	var result := {}
	var training_by_hero: Dictionary = _data.get("training_by_hero", {})
	for hero_id in training_by_hero:
		var levels: Dictionary = training_by_hero.get(hero_id, {})
		var non_zero := {}
		for upgrade_id in levels:
			var level := int(levels.get(upgrade_id, 0))
			if level > 0:
				non_zero[upgrade_id] = level
		result[str(hero_id)] = non_zero
	return result


func can_purchase_training_upgrade(hero_id: String, upgrade_id: String) -> bool:
	var def := get_meta_upgrade_definition(upgrade_id)
	if def.is_empty():
		return false
	if get_training_level(hero_id, upgrade_id) >= int(def.get("max_level", 1)):
		return false
	return get_currency() >= get_training_upgrade_cost(hero_id, upgrade_id)


func purchase_training_upgrade(hero_id: String, upgrade_id: String) -> bool:
	var resolved_hero_id := _resolve_hero_id(hero_id)
	if not can_purchase_training_upgrade(resolved_hero_id, upgrade_id):
		return false
	var cost := get_training_upgrade_cost(resolved_hero_id, upgrade_id)
	if not spend_currency(cost):
		return false
	var new_level := get_training_level(resolved_hero_id, upgrade_id) + 1
	set_training_level(resolved_hero_id, upgrade_id, new_level)
	save_progress()
	return true


func ensure_training_data_for_hero(hero_id: String) -> void:
	var resolved_hero_id := _resolve_hero_id(hero_id)
	var training_by_hero: Dictionary = _data.get("training_by_hero", {})
	if not training_by_hero.has(resolved_hero_id) or not training_by_hero.get(resolved_hero_id) is Dictionary:
		training_by_hero[resolved_hero_id] = {}
		_data["training_by_hero"] = training_by_hero


func ensure_training_data_for_all_heroes(hero_ids: Array) -> void:
	for hero_id in hero_ids:
		ensure_training_data_for_hero(str(hero_id))


func ensure_equipment_data_for_hero(hero_id: String) -> void:
	var resolved_hero_id := _resolve_hero_id(hero_id)
	var equipment_by_hero: Dictionary = _data.get("equipment_by_hero", {})
	var hero_equipment: Dictionary = equipment_by_hero.get(resolved_hero_id, {}) if equipment_by_hero.get(resolved_hero_id, {}) is Dictionary else {}
	for def in get_equipment_definitions(resolved_hero_id):
		var equipment_id := str(def.get("equipment_id", ""))
		if equipment_id.is_empty():
			continue
		var current := int(hero_equipment.get(equipment_id, 0))
		hero_equipment[equipment_id] = clampi(current, 0, int(def.get("max_level", 0)))
	equipment_by_hero[resolved_hero_id] = hero_equipment
	_data["equipment_by_hero"] = equipment_by_hero


func ensure_equipment_data_for_all_heroes(hero_ids: Array) -> void:
	for hero_id in hero_ids:
		ensure_equipment_data_for_hero(str(hero_id))


func get_training_upgrade_cost(hero_id: String, upgrade_id: String) -> int:
	var def := get_meta_upgrade_definition(upgrade_id)
	if def.is_empty():
		return 0
	var level := get_training_level(hero_id, upgrade_id)
	return _calculate_upgrade_cost(def, level)


func get_meta_upgrade_level(upgrade_id: String) -> int:
	return get_training_level(DEFAULT_HERO_ID, upgrade_id)


func get_meta_upgrade_cost(upgrade_id: String) -> int:
	var def := get_meta_upgrade_definition(upgrade_id)
	if def.is_empty():
		return 0
	return _calculate_upgrade_cost(def, get_meta_upgrade_level(upgrade_id))


func can_buy_meta_upgrade(upgrade_id: String) -> bool:
	return can_purchase_training_upgrade(DEFAULT_HERO_ID, upgrade_id)


func buy_meta_upgrade(upgrade_id: String) -> bool:
	return purchase_training_upgrade(DEFAULT_HERO_ID, upgrade_id)


func is_hero_unlocked(hero_id: String) -> bool:
	var unlocked: Array = _data.get("unlocked_heroes", [])
	return hero_id in unlocked


func unlock_hero(hero_id: String) -> bool:
	if is_hero_unlocked(hero_id):
		return true
	var unlocked: Array = _data.get("unlocked_heroes", [])
	unlocked.append(hero_id)
	_data["unlocked_heroes"] = unlocked
	hero_unlock_changed.emit(hero_id, true)
	save_progress()
	return true


func calculate_run_rewards(summary: Dictionary) -> Dictionary:
	var run_time := float(summary.get("run_time", 0.0))
	var kill_count := int(summary.get("kill_count", 0))
	var elite_kill_count := int(summary.get("elite_kill_count", 0))
	var miniboss_kill_count := int(summary.get("miniboss_kill_count", 0))
	var result := str(summary.get("result", "defeat"))
	var applied_evolutions: Array = summary.get("applied_evolutions", [])

	var final_boss_defeated := bool(summary.get("final_boss_defeated", false))

	var base_reward := 10
	var time_reward := int(floor(run_time / 30.0)) * 2
	var kill_reward := int(floor(float(kill_count) / 10.0))
	var elite_reward := elite_kill_count * 5
	var miniboss_reward := miniboss_kill_count * 15
	var final_boss_reward := 35 if final_boss_defeated else 0
	var victory_bonus := 40 if result == "victory" else 0
	var evolution_bonus := applied_evolutions.size() * 10
	var hero_id := str(summary.get("hero_id", DEFAULT_HERO_ID))
	var starting_bonus := get_training_level(hero_id, "meta_starting_currency_bonus") * 2

	var total_reward := maxi(
		base_reward + time_reward + kill_reward + elite_reward + miniboss_reward +
		final_boss_reward + victory_bonus + evolution_bonus + starting_bonus, 0
	)

	return {
		"base_reward": base_reward,
		"time_reward": time_reward,
		"kill_reward": kill_reward,
		"elite_reward": elite_reward,
		"miniboss_reward": miniboss_reward,
		"final_boss_reward": final_boss_reward,
		"victory_bonus": victory_bonus,
		"evolution_bonus": evolution_bonus,
		"starting_bonus": starting_bonus,
		"goal_reward": 0,
		"total_reward": total_reward,
	}


func apply_run_result(summary: Dictionary) -> Dictionary:
	var rewards := calculate_run_rewards(summary)

	_data["total_runs"] = int(_data.get("total_runs", 0)) + 1
	if str(summary.get("result", "")) == "victory":
		_data["total_victories"] = int(_data.get("total_victories", 0)) + 1
	_data["total_kills"] = int(_data.get("total_kills", 0)) + int(summary.get("kill_count", 0))
	_data["total_elite_kills"] = int(_data.get("total_elite_kills", 0)) + int(summary.get("elite_kill_count", 0))
	_data["total_miniboss_kills"] = int(_data.get("total_miniboss_kills", 0)) + int(summary.get("miniboss_kill_count", 0))

	var mastery_changes := _apply_mastery_from_run(summary)
	var stage_changes := _apply_stage_mastery_from_run(summary)
	var completed_goals := evaluate_goals_from_run(summary)
	var goal_reward := 0
	for goal in completed_goals:
		goal_reward += int(goal.get("reward_currency", 0))
	rewards["run_reward_total"] = int(rewards.get("total_reward", 0))
	rewards["goal_reward"] = goal_reward
	rewards["total_reward"] = int(rewards.get("total_reward", 0)) + goal_reward
	rewards["mastery_changes"] = mastery_changes
	rewards["stage_mastery_changes"] = stage_changes
	rewards["newly_completed_goals"] = completed_goals
	rewards["goal_rewards_auto_claimed"] = true

	add_currency(int(rewards.get("total_reward", 0)))
	save_progress()

	return rewards


func get_progress_summary() -> Dictionary:
	return {
		"currency": get_currency(),
		"total_runs": int(_data.get("total_runs", 0)),
		"total_victories": int(_data.get("total_victories", 0)),
		"total_kills": int(_data.get("total_kills", 0)),
		"total_elite_kills": int(_data.get("total_elite_kills", 0)),
		"total_miniboss_kills": int(_data.get("total_miniboss_kills", 0)),
		"training_by_hero": _data.get("training_by_hero", {}).duplicate(true),
		"equipment_by_hero": _data.get("equipment_by_hero", {}).duplicate(true),
		"meta_upgrades": get_training_levels_for_hero(DEFAULT_HERO_ID),
		"unlocked_heroes": _data.get("unlocked_heroes", []).duplicate(),
		"hero_mastery": get_hero_mastery_summary(),
		"stage_mastery": get_stage_mastery_summary(),
		"goals": get_goal_progress(),
	}


func get_meta_upgrade_definitions() -> Array[Dictionary]:
	return [
		{
			"id": "meta_max_health",
			"title": "Training: Vitality",
			"description": "+5 starting max HP per level.",
			"max_level": 10,
			"base_cost": 25,
			"cost_growth": 1.35,
		},
		{
			"id": "meta_attack_damage",
			"title": "Training: Power",
			"description": "+1 starting attack damage per level.",
			"max_level": 10,
			"base_cost": 30,
			"cost_growth": 1.4,
		},
		{
			"id": "meta_pickup_radius",
			"title": "Training: Awareness",
			"description": "+8 XP pickup radius per level.",
			"max_level": 8,
			"base_cost": 20,
			"cost_growth": 1.35,
		},
		{
			"id": "meta_move_speed",
			"title": "Training: Mobility",
			"description": "+3 starting movement speed per level.",
			"max_level": 8,
			"base_cost": 20,
			"cost_growth": 1.35,
		},
		{
			"id": "meta_starting_currency_bonus",
			"title": "Training: Rewards",
			"description": "+2 currency after each run per level.",
			"max_level": 5,
			"base_cost": 40,
			"cost_growth": 1.5,
		},
	]


func get_meta_upgrade_definition(upgrade_id: String) -> Dictionary:
	for def in get_meta_upgrade_definitions():
		if str(def.get("id", "")) == upgrade_id:
			return def
	return {}


func get_hero_mastery_summary() -> Dictionary:
	_ensure_mastery_defaults()
	var result := {}
	var mastery_by_hero: Dictionary = _data.get("hero_mastery", {})
	for hero_id in mastery_by_hero:
		var entry: Dictionary = mastery_by_hero.get(hero_id, {})
		var copy := entry.duplicate(true)
		copy["current_mastery_level"] = _calculate_hero_mastery_level(copy)
		result[str(hero_id)] = copy
	return result


func get_stage_mastery_summary() -> Dictionary:
	_ensure_mastery_defaults()
	return _data.get("stage_mastery", {}).duplicate(true)


func get_goal_definitions() -> Array[Dictionary]:
	return [
		{
			"id": "win_city_rooftop",
			"title": "Rooftop Victor",
			"description": "Win City Rooftop once.",
			"category": "stage",
			"reward_currency": 30,
			"progress_target": 1,
		},
		{
			"id": "defend_lab_reactor",
			"title": "Reactor Defender",
			"description": "Win Neon Lab with the Reactor alive.",
			"category": "stage",
			"reward_currency": 45,
			"progress_target": 1,
		},
		{
			"id": "close_wasteland_portals",
			"title": "Gate Closer",
			"description": "Destroy all Wasteland Gate portals.",
			"category": "stage",
			"reward_currency": 45,
			"progress_target": 1,
		},
		{
			"id": "guardian_attack_evolution",
			"title": "Solar Arsenal",
			"description": "Select 1 attack evolution as Solar Guardian.",
			"category": "hero",
			"reward_currency": 35,
			"progress_target": 1,
		},
		{
			"id": "blaster_mark_build",
			"title": "Tactical Evolution",
			"description": "Select 2 Night Tactician evolutions in one run.",
			"category": "evolution",
			"reward_currency": 45,
			"progress_target": 2,
		},
		{
			"id": "vanguard_rage_boss",
			"title": "Ragebreaker",
			"description": "Defeat a final boss as Fury Vanguard.",
			"category": "boss",
			"reward_currency": 45,
			"progress_target": 1,
		},
		{
			"id": "first_3_evolutions",
			"title": "Triple Overdrive",
			"description": "Select 3 evolutions in one run.",
			"category": "evolution",
			"reward_currency": 60,
			"progress_target": 3,
		},
		{
			"id": "boss_slayer",
			"title": "Boss Slayer",
			"description": "Defeat any final boss.",
			"category": "boss",
			"reward_currency": 40,
			"progress_target": 1,
		},
		{
			"id": "elite_hunter",
			"title": "Elite Hunter",
			"description": "Defeat 10 elites total.",
			"category": "general",
			"reward_currency": 35,
			"progress_target": 10,
		},
		{
			"id": "mastery_beginner",
			"title": "Mastery Beginner",
			"description": "Reach mastery level 2 with any hero.",
			"category": "general",
			"reward_currency": 35,
			"progress_target": 2,
		},
	]


func get_goal_progress() -> Array[Dictionary]:
	_ensure_goal_defaults()
	var result: Array[Dictionary] = []
	var goals: Dictionary = _data.get("goals", {})
	for def in get_goal_definitions():
		var goal_id := str(def.get("id", ""))
		var state: Dictionary = goals.get(goal_id, {})
		var current := maxi(int(state.get("progress_current", 0)), _calculate_goal_progress(def))
		var target := int(def.get("progress_target", 1))
		result.append({
			"id": goal_id,
			"title": str(def.get("title", goal_id)),
			"description": str(def.get("description", "")),
			"category": str(def.get("category", "general")),
			"reward_currency": int(def.get("reward_currency", 0)),
			"completed": bool(state.get("completed", false)) or current >= target,
			"claimed": bool(state.get("claimed", false)),
			"progress_current": mini(current, target),
			"progress_target": target,
		})
	return result


func evaluate_goals_from_run(summary: Dictionary) -> Array[Dictionary]:
	_ensure_goal_defaults()
	_newly_completed_goals.clear()
	var goals: Dictionary = _data.get("goals", {})
	for def in get_goal_definitions():
		var goal_id := str(def.get("id", ""))
		var state: Dictionary = goals.get(goal_id, _get_default_goal_state())
		var target := int(def.get("progress_target", 1))
		var current := maxi(maxi(int(state.get("progress_current", 0)), _calculate_goal_progress(def)), _calculate_goal_run_progress(def, summary))
		state["progress_current"] = mini(current, target)
		if not bool(state.get("completed", false)) and current >= target:
			state["completed"] = true
			state["claimed"] = true
			var completed := def.duplicate(true)
			completed["completed"] = true
			completed["claimed"] = true
			completed["progress_current"] = target
			_newly_completed_goals.append(completed)
		goals[goal_id] = state
	_data["goals"] = goals
	return _newly_completed_goals.duplicate(true)


func claim_goal_reward(goal_id: String) -> bool:
	_ensure_goal_defaults()
	var goals: Dictionary = _data.get("goals", {})
	if not goals.has(goal_id):
		return false
	var state: Dictionary = goals.get(goal_id, {})
	if not bool(state.get("completed", false)) or bool(state.get("claimed", false)):
		return false
	var def := _get_goal_definition(goal_id)
	if def.is_empty():
		return false
	state["claimed"] = true
	goals[goal_id] = state
	_data["goals"] = goals
	add_currency(int(def.get("reward_currency", 0)))
	save_progress()
	return true


func get_newly_completed_goals() -> Array[Dictionary]:
	return _newly_completed_goals.duplicate(true)


func debug_get_mastery_summary() -> Dictionary:
	return {
		"heroes": get_hero_mastery_summary(),
		"stages": get_stage_mastery_summary(),
	}


func debug_get_goal_summary() -> Array[Dictionary]:
	return get_goal_progress()


func _get_defaults() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"currency": 0,
		"meta_upgrades": {},
		"training_by_hero": _get_default_training_by_hero(),
		"equipment_by_hero": _get_default_equipment_by_hero(),
		"unlocked_heroes": ["guardian", "blaster", "vanguard"],
		"total_runs": 0,
		"total_victories": 0,
		"total_kills": 0,
		"total_elite_kills": 0,
		"total_miniboss_kills": 0,
		"hero_mastery": _get_default_hero_mastery(),
		"stage_mastery": _get_default_stage_mastery(),
		"goals": _get_default_goals(),
	}


func _merge_with_defaults(parsed: Dictionary) -> void:
	var defaults := _get_defaults()
	_data = defaults.duplicate(true)
	for key in parsed:
		_data[key] = parsed[key]
	if not _data.get("meta_upgrades") is Dictionary:
		_data["meta_upgrades"] = {}
	if not _data.get("training_by_hero") is Dictionary:
		_data["training_by_hero"] = {}
	if not _data.get("equipment_by_hero") is Dictionary:
		_data["equipment_by_hero"] = {}
	_migrate_global_training_if_needed(parsed)
	ensure_training_data_for_all_heroes(DEFAULT_HERO_IDS)
	ensure_equipment_data_for_all_heroes(DEFAULT_HERO_IDS)
	_data["version"] = SAVE_VERSION
	if not _data.get("unlocked_heroes") is Array:
		_data["unlocked_heroes"] = ["guardian", "blaster", "vanguard"]
	var unlocked: Array = _data["unlocked_heroes"]
	if "guardian" not in unlocked:
		unlocked.append("guardian")
	_ensure_mastery_defaults()
	_ensure_goal_defaults()


func _get_default_training_by_hero() -> Dictionary:
	var result := {}
	for hero_id in DEFAULT_HERO_IDS:
		result[hero_id] = {}
	return result


func _get_default_equipment_by_hero() -> Dictionary:
	var result := {}
	for hero_id in DEFAULT_HERO_IDS:
		var hero_equipment := {}
		for def in get_equipment_definitions(hero_id):
			hero_equipment[str(def.get("equipment_id", ""))] = 0
		result[hero_id] = hero_equipment
	return result


func _get_all_equipment_definitions() -> Array[Dictionary]:
	return [
		_make_equipment_definition("guardian", "solar_core", "core", "Core", "Solar Core", "A radiant reactor that will strengthen Solar Guardian's core power.", "ability_damage", 0.02, 60, 1.35),
		_make_equipment_definition("guardian", "radiant_suit", "suit", "Suit", "Radiant Suit", "Layered solar armor reserved for future durability upgrades.", "max_health", 5, 55, 1.34),
		_make_equipment_definition("guardian", "sun_emblem", "emblem", "Emblem", "Sun Emblem", "A bright insignia prepared for future mastery scaling.", "xp_gain", 0.01, 50, 1.33),
		_make_equipment_definition("guardian", "power_gauntlets", "gauntlets", "Gauntlets", "Power Gauntlets", "Solar-charged gauntlets for future attack upgrades.", "attack_damage", 1, 60, 1.36),
		_make_equipment_definition("guardian", "flight_boots", "boots", "Boots", "Flight Boots", "Stabilized boots reserved for future movement upgrades.", "move_speed", 3, 45, 1.32),
		_make_equipment_definition("guardian", "aegis_artifact", "artifact", "Artifact", "Aegis Artifact", "A protective relic prepared for future shield upgrades.", "shield_capacity", 1, 75, 1.4),
		_make_equipment_definition("blaster", "tactical_core", "core", "Core", "Tactical Core", "A compact command module for future ability cooldown upgrades.", "ability_cooldown", 0.01, 60, 1.35),
		_make_equipment_definition("blaster", "shadow_suit", "suit", "Suit", "Shadow Suit", "Stealth-lined armor reserved for future survivability upgrades.", "max_health", 4, 55, 1.34),
		_make_equipment_definition("blaster", "signal_emblem", "emblem", "Emblem", "Signal Emblem", "A targeting badge prepared for future mark upgrades.", "mark_damage", 0.02, 50, 1.33),
		_make_equipment_definition("blaster", "gadget_gauntlets", "gauntlets", "Gauntlets", "Gadget Gauntlets", "Utility gauntlets reserved for future rocket damage upgrades.", "attack_damage", 1, 60, 1.36),
		_make_equipment_definition("blaster", "grapnel_boots", "boots", "Boots", "Grapnel Boots", "Anchored boots prepared for future repositioning upgrades.", "move_speed", 3, 45, 1.32),
		_make_equipment_definition("blaster", "drone_artifact", "artifact", "Artifact", "Drone Artifact", "A mini-drone relay reserved for future tactical support upgrades.", "support_damage", 0.02, 75, 1.4),
		_make_equipment_definition("vanguard", "rage_core", "core", "Core", "Rage Core", "A volatile core prepared for future Rage scaling.", "rage_gain", 0.02, 60, 1.35),
		_make_equipment_definition("vanguard", "titan_suit", "suit", "Suit", "Titan Suit", "Heavy reinforced armor reserved for future health upgrades.", "max_health", 6, 55, 1.34),
		_make_equipment_definition("vanguard", "war_emblem", "emblem", "Emblem", "War Emblem", "A battle crest prepared for future impact upgrades.", "impact_damage", 0.02, 50, 1.33),
		_make_equipment_definition("vanguard", "impact_gauntlets", "gauntlets", "Gauntlets", "Impact Gauntlets", "Weighted gauntlets reserved for future melee upgrades.", "attack_damage", 1, 60, 1.36),
		_make_equipment_definition("vanguard", "heavy_boots", "boots", "Boots", "Heavy Boots", "Grounded boots prepared for future knockback resistance upgrades.", "knockback_resist", 0.03, 45, 1.32),
		_make_equipment_definition("vanguard", "fury_artifact", "artifact", "Artifact", "Fury Artifact", "A charged relic prepared for future enrage upgrades.", "low_health_damage", 0.02, 75, 1.4),
	]


func _make_equipment_definition(hero_id: String, equipment_id: String, slot_id: String, slot_name: String, display_name: String, description: String, stat_bonus_type: String, stat_bonus_per_level, base_cost: int, cost_growth: float) -> Dictionary:
	return {
		"equipment_id": equipment_id,
		"hero_id": hero_id,
		"slot_id": slot_id,
		"slot_name": slot_name,
		"display_name": display_name,
		"description": description,
		"max_level": 10,
		"base_cost": base_cost,
		"cost_growth": cost_growth,
		"stat_bonus_type": stat_bonus_type,
		"stat_bonus_per_level": stat_bonus_per_level,
		"tier": "signature",
	}


func _get_default_hero_mastery() -> Dictionary:
	var result := {}
	for hero_id in DEFAULT_HERO_IDS:
		result[hero_id] = _get_default_hero_mastery_entry()
	return result


func _get_default_hero_mastery_entry() -> Dictionary:
	return {
		"runs_played": 0,
		"victories": 0,
		"kills": 0,
		"elite_kills": 0,
		"miniboss_kills": 0,
		"final_boss_kills": 0,
		"evolutions_selected": 0,
		"attack_evolutions_selected": 0,
		"active_evolutions_selected": 0,
		"passive_evolutions_selected": 0,
		"highest_mastery_level": 1,
	}


func _get_default_stage_mastery() -> Dictionary:
	var result := {}
	for stage_id in DEFAULT_STAGE_IDS:
		result[stage_id] = _get_default_stage_mastery_entry()
	return result


func _get_default_stage_mastery_entry() -> Dictionary:
	return {
		"attempts": 0,
		"victories": 0,
		"objective_completions": 0,
		"final_boss_kills": 0,
		"best_grade": "",
		"best_time": 0.0,
	}


func _get_default_goals() -> Dictionary:
	var result := {}
	for goal in get_goal_definitions():
		result[str(goal.get("id", ""))] = _get_default_goal_state()
	return result


func _get_default_goal_state() -> Dictionary:
	return {
		"completed": false,
		"claimed": false,
		"progress_current": 0,
	}


func _ensure_mastery_defaults() -> void:
	if not _data.get("hero_mastery") is Dictionary:
		_data["hero_mastery"] = {}
	var hero_mastery: Dictionary = _data.get("hero_mastery", {})
	for hero_id in DEFAULT_HERO_IDS:
		var entry: Dictionary = hero_mastery.get(hero_id, {}) if hero_mastery.get(hero_id, {}) is Dictionary else {}
		hero_mastery[hero_id] = _merge_entry_defaults(entry, _get_default_hero_mastery_entry())
	_data["hero_mastery"] = hero_mastery

	if not _data.get("stage_mastery") is Dictionary:
		_data["stage_mastery"] = {}
	var stage_mastery: Dictionary = _data.get("stage_mastery", {})
	for stage_id in DEFAULT_STAGE_IDS:
		var entry: Dictionary = stage_mastery.get(stage_id, {}) if stage_mastery.get(stage_id, {}) is Dictionary else {}
		stage_mastery[stage_id] = _merge_entry_defaults(entry, _get_default_stage_mastery_entry())
	_data["stage_mastery"] = stage_mastery


func _ensure_goal_defaults() -> void:
	if not _data.get("goals") is Dictionary:
		_data["goals"] = {}
	var goals: Dictionary = _data.get("goals", {})
	for goal in get_goal_definitions():
		var goal_id := str(goal.get("id", ""))
		var state: Dictionary = goals.get(goal_id, {}) if goals.get(goal_id, {}) is Dictionary else {}
		goals[goal_id] = _merge_entry_defaults(state, _get_default_goal_state())
	_data["goals"] = goals


func _merge_entry_defaults(entry: Dictionary, defaults: Dictionary) -> Dictionary:
	var merged := defaults.duplicate(true)
	for key in entry:
		merged[key] = entry[key]
	return merged


func _migrate_global_training_if_needed(parsed: Dictionary) -> void:
	var old_global: Dictionary = parsed.get("meta_upgrades", {}) if parsed.get("meta_upgrades", {}) is Dictionary else {}
	var parsed_training = parsed.get("training_by_hero", null)
	var has_per_hero_training: bool = parsed_training is Dictionary and not parsed_training.is_empty()
	if old_global.is_empty() or has_per_hero_training:
		return

	var training_by_hero: Dictionary = _data.get("training_by_hero", {})
	for hero_id in DEFAULT_HERO_IDS:
		training_by_hero[hero_id] = old_global.duplicate()
	_data["training_by_hero"] = training_by_hero


func _apply_mastery_from_run(summary: Dictionary) -> Dictionary:
	_ensure_mastery_defaults()
	var hero_id := _resolve_hero_id(str(summary.get("hero_id", DEFAULT_HERO_ID)))
	var hero_mastery: Dictionary = _data.get("hero_mastery", {})
	var before: Dictionary = hero_mastery.get(hero_id, _get_default_hero_mastery_entry()).duplicate(true)
	var entry: Dictionary = hero_mastery.get(hero_id, _get_default_hero_mastery_entry())
	var evolution_counts: Dictionary = summary.get("applied_evolution_type_counts", {})
	entry["runs_played"] = int(entry.get("runs_played", 0)) + 1
	if str(summary.get("result", "")) == "victory":
		entry["victories"] = int(entry.get("victories", 0)) + 1
	entry["kills"] = int(entry.get("kills", 0)) + int(summary.get("kill_count", 0))
	entry["elite_kills"] = int(entry.get("elite_kills", 0)) + int(summary.get("elite_kill_count", 0))
	entry["miniboss_kills"] = int(entry.get("miniboss_kills", 0)) + int(summary.get("miniboss_kill_count", 0))
	if bool(summary.get("final_boss_defeated", false)):
		entry["final_boss_kills"] = int(entry.get("final_boss_kills", 0)) + 1
	entry["evolutions_selected"] = int(entry.get("evolutions_selected", 0)) + int(summary.get("applied_evolution_count", 0))
	entry["attack_evolutions_selected"] = int(entry.get("attack_evolutions_selected", 0)) + int(evolution_counts.get("attack", 0))
	entry["active_evolutions_selected"] = int(entry.get("active_evolutions_selected", 0)) + int(evolution_counts.get("active", 0))
	entry["passive_evolutions_selected"] = int(entry.get("passive_evolutions_selected", 0)) + int(evolution_counts.get("passive", 0))
	var new_level := _calculate_hero_mastery_level(entry)
	entry["highest_mastery_level"] = maxi(int(entry.get("highest_mastery_level", 1)), new_level)
	hero_mastery[hero_id] = entry
	_data["hero_mastery"] = hero_mastery
	return {
		"hero_id": hero_id,
		"before": before,
		"after": entry.duplicate(true),
		"level_before": int(before.get("highest_mastery_level", 1)),
		"level_after": int(entry.get("highest_mastery_level", 1)),
	}


func _apply_stage_mastery_from_run(summary: Dictionary) -> Dictionary:
	_ensure_mastery_defaults()
	var stage_id := str(summary.get("stage_id", "city_rooftop"))
	if stage_id.is_empty():
		stage_id = "city_rooftop"
	var stage_mastery: Dictionary = _data.get("stage_mastery", {})
	var before: Dictionary = stage_mastery.get(stage_id, _get_default_stage_mastery_entry()).duplicate(true)
	var entry: Dictionary = stage_mastery.get(stage_id, _get_default_stage_mastery_entry())
	entry["attempts"] = int(entry.get("attempts", 0)) + 1
	if str(summary.get("result", "")) == "victory":
		entry["victories"] = int(entry.get("victories", 0)) + 1
	if bool(summary.get("objective_completed", false)):
		entry["objective_completions"] = int(entry.get("objective_completions", 0)) + 1
	if bool(summary.get("final_boss_defeated", false)):
		entry["final_boss_kills"] = int(entry.get("final_boss_kills", 0)) + 1
	var grade := str(summary.get("run_grade", "C"))
	if _is_better_grade(grade, str(entry.get("best_grade", ""))):
		entry["best_grade"] = grade
	var run_time := float(summary.get("run_time", 0.0))
	if str(summary.get("result", "")) == "victory" and run_time > 0.0:
		var best_time := float(entry.get("best_time", 0.0))
		if best_time <= 0.0 or run_time < best_time:
			entry["best_time"] = run_time
	stage_mastery[stage_id] = entry
	_data["stage_mastery"] = stage_mastery
	return {
		"stage_id": stage_id,
		"before": before,
		"after": entry.duplicate(true),
	}


func _calculate_hero_mastery_level(entry: Dictionary) -> int:
	var score := 0
	score += int(entry.get("runs_played", 0))
	score += int(entry.get("victories", 0)) * 3
	score += int(entry.get("final_boss_kills", 0)) * 3
	score += int(floor(float(entry.get("kills", 0)) / 75.0))
	score += int(floor(float(entry.get("elite_kills", 0)) / 4.0))
	score += int(floor(float(entry.get("miniboss_kills", 0)) / 2.0))
	score += int(entry.get("evolutions_selected", 0)) * 2
	if score >= 100:
		return 5
	if score >= 60:
		return 4
	if score >= 30:
		return 3
	if score >= 12:
		return 2
	return 1


func _calculate_goal_progress(goal: Dictionary) -> int:
	var goal_id := str(goal.get("id", ""))
	match goal_id:
		"win_city_rooftop":
			return 1 if _get_stage_stat("city_rooftop", "victories") > 0 else 0
		"defend_lab_reactor":
			return 1 if _get_stage_stat("neon_lab", "objective_completions") > 0 else 0
		"close_wasteland_portals":
			return 1 if _get_stage_stat("wasteland_gate", "objective_completions") > 0 else 0
		"guardian_attack_evolution":
			return mini(_get_hero_stat("guardian", "attack_evolutions_selected"), 1)
		"vanguard_rage_boss":
			return mini(_get_hero_stat("vanguard", "final_boss_kills"), 1)
		"boss_slayer":
			return 1 if _get_total_final_boss_kills() > 0 else 0
		"elite_hunter":
			return mini(int(_data.get("total_elite_kills", 0)), int(goal.get("progress_target", 10)))
		"mastery_beginner":
			return mini(_get_highest_any_hero_mastery_level(), int(goal.get("progress_target", 2)))
		_:
			var goals: Dictionary = _data.get("goals", {})
			var state: Dictionary = goals.get(goal_id, {})
			return int(state.get("progress_current", 0))


func _calculate_goal_run_progress(goal: Dictionary, summary: Dictionary) -> int:
	var goal_id := str(goal.get("id", ""))
	var hero_id := str(summary.get("hero_id", ""))
	var stage_id := str(summary.get("stage_id", ""))
	match goal_id:
		"blaster_mark_build":
			if hero_id == "blaster":
				return int(summary.get("applied_evolution_count", 0))
		"first_3_evolutions":
			return int(summary.get("applied_evolution_count", 0))
		"defend_lab_reactor":
			if stage_id == "neon_lab" and str(summary.get("result", "")) == "victory" and not bool(summary.get("objective_failed", false)):
				return 1
		"close_wasteland_portals":
			if stage_id == "wasteland_gate" and bool(summary.get("objective_completed", false)):
				return int(goal.get("progress_target", 1))
		_:
			return 0
	return 0


func _get_goal_definition(goal_id: String) -> Dictionary:
	for goal in get_goal_definitions():
		if str(goal.get("id", "")) == goal_id:
			return goal
	return {}


func _get_hero_stat(hero_id: String, key: String) -> int:
	var mastery: Dictionary = _data.get("hero_mastery", {})
	var entry: Dictionary = mastery.get(hero_id, {})
	return int(entry.get(key, 0))


func _get_stage_stat(stage_id: String, key: String) -> int:
	var mastery: Dictionary = _data.get("stage_mastery", {})
	var entry: Dictionary = mastery.get(stage_id, {})
	return int(entry.get(key, 0))


func _get_total_final_boss_kills() -> int:
	var total := 0
	var mastery: Dictionary = _data.get("hero_mastery", {})
	for hero_id in mastery:
		var entry: Dictionary = mastery.get(hero_id, {})
		total += int(entry.get("final_boss_kills", 0))
	return total


func _get_highest_any_hero_mastery_level() -> int:
	var highest := 1
	var mastery: Dictionary = _data.get("hero_mastery", {})
	for hero_id in mastery:
		var entry: Dictionary = mastery.get(hero_id, {})
		highest = maxi(highest, int(entry.get("highest_mastery_level", _calculate_hero_mastery_level(entry))))
	return highest


func _is_better_grade(new_grade: String, old_grade: String) -> bool:
	return _grade_value(new_grade) > _grade_value(old_grade)


func _grade_value(grade: String) -> int:
	match grade:
		"S":
			return 4
		"A":
			return 3
		"B":
			return 2
		"C":
			return 1
		_:
			return 0


func _calculate_upgrade_cost(def: Dictionary, level: int) -> int:
	var base_cost := int(def.get("base_cost", 25))
	var growth := float(def.get("cost_growth", 1.35))
	if level <= 0:
		return base_cost
	return int(round(float(base_cost) * pow(growth, float(level))))


func _resolve_hero_id(hero_id: String) -> String:
	return hero_id if not hero_id.is_empty() else DEFAULT_HERO_ID


func _sync_legacy_meta_upgrades() -> void:
	var training_by_hero: Dictionary = _data.get("training_by_hero", {})
	var default_training: Dictionary = training_by_hero.get(DEFAULT_HERO_ID, {})
	_data["meta_upgrades"] = default_training.duplicate()
