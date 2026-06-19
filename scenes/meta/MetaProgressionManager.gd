extends Node

signal currency_changed(amount: int)
signal meta_upgrade_changed(upgrade_id: String, level: int)
signal hero_unlock_changed(hero_id: String, unlocked: bool)
signal progress_loaded
signal progress_saved

const SAVE_PATH := "user://superheroes_meta_progress.json"
const SAVE_VERSION := 2
const DEFAULT_HERO_ID := "guardian"
const DEFAULT_HERO_IDS: Array[String] = ["guardian", "blaster", "vanguard"]

var _data: Dictionary = {}


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
	}


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
		"meta_upgrades": get_training_levels_for_hero(DEFAULT_HERO_ID),
		"unlocked_heroes": _data.get("unlocked_heroes", []).duplicate(),
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


func _get_defaults() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"currency": 0,
		"meta_upgrades": {},
		"training_by_hero": _get_default_training_by_hero(),
		"unlocked_heroes": ["guardian", "blaster", "vanguard"],
		"total_runs": 0,
		"total_victories": 0,
		"total_kills": 0,
		"total_elite_kills": 0,
		"total_miniboss_kills": 0,
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
	_migrate_global_training_if_needed(parsed)
	ensure_training_data_for_all_heroes(DEFAULT_HERO_IDS)
	_data["version"] = SAVE_VERSION
	if not _data.get("unlocked_heroes") is Array:
		_data["unlocked_heroes"] = ["guardian", "blaster", "vanguard"]
	var unlocked: Array = _data["unlocked_heroes"]
	if "guardian" not in unlocked:
		unlocked.append("guardian")


func _get_default_training_by_hero() -> Dictionary:
	var result := {}
	for hero_id in DEFAULT_HERO_IDS:
		result[hero_id] = {}
	return result


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
