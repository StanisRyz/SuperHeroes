extends Node

signal currency_changed(amount: int)
signal gold_changed(value: int)
signal equipment_materials_changed(materials: Dictionary)
signal meta_upgrade_changed(upgrade_id: String, level: int)
signal equipment_upgrade_changed(hero_id: String, equipment_id: String, level: int)
signal inventory_changed(hero_id: String)
signal equipment_changed(hero_id: String, slot_id: String, instance_id: String)
signal hero_unlock_changed(hero_id: String, unlocked: bool)
signal progress_loaded
signal progress_saved
signal inventory_item_upgraded(hero_id: String, instance_id: String, level: int)

const SAVE_PATH := "user://superheroes_meta_progress.json"
const SAVE_VERSION := 7
const DEFAULT_HERO_ID := "guardian"
const DEFAULT_HERO_IDS: Array[String] = ["guardian", "blaster", "vanguard"]
const DEFAULT_STAGE_IDS: Array[String] = ["city_rooftop", "neon_lab", "wasteland_gate"]
const EQUIPMENT_SLOT_IDS: Array[String] = ["core", "suit", "emblem", "gauntlets", "boots", "artifact"]
const STARTER_PACK_ID := "starter_pack_v1"
const INVENTORY_CAPACITY := 60
const TRAINING_DAMAGE_REDUCTION_CAP := 0.50

const _RARITY_GOLD_BASE := {
	"common": 5,
	"uncommon": 10,
	"rare": 20,
	"epic": 40,
	"legendary": 80,
	"mythic": 160,
}
const _RARITY_MATERIAL_BASE := {
	"common": 3,
	"uncommon": 3,
	"rare": 3,
	"epic": 2,
	"legendary": 2,
	"mythic": 1,
}
const _RARITY_UPGRADE_COST_CONFIG := {
	"common": {"gold_base": 20, "material_base": 2},
	"uncommon": {"gold_base": 35, "material_base": 2},
	"rare": {"gold_base": 60, "material_base": 2},
	"epic": {"gold_base": 100, "material_base": 2},
	"legendary": {"gold_base": 160, "material_base": 2},
	"mythic": {"gold_base": 250, "material_base": 2},
}
const STARTER_PACK_TEMPLATES: Array[String] = [
	"power_core_common", "reinforced_suit_common", "awareness_emblem_common",
	"striker_gauntlets_common", "runner_boots_common", "shield_artifact_common",
]

var _data: Dictionary = {}
var _newly_completed_goals: Array[Dictionary] = []
var _equipment_provider: Node = null
var _training_provider: Node = null


func _ready() -> void:
	_training_provider = load("res://scenes/training/CharacterTrainingDataProvider.gd").new()
	add_child(_training_provider)
	_equipment_provider = load("res://scenes/equipment/EquipmentDataProvider.gd").new()
	add_child(_equipment_provider)
	load_progress()


func load_progress() -> void:
	_data = _get_defaults()
	if not FileAccess.file_exists(SAVE_PATH):
		_clear_static_inventory_if_needed(_data)
		progress_loaded.emit()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("MetaProgressionManager: cannot open save file. Starting fresh.")
		_clear_static_inventory_if_needed(_data)
		progress_loaded.emit()
		return
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		push_warning("MetaProgressionManager: corrupt save file. Starting fresh.")
		_clear_static_inventory_if_needed(_data)
		progress_loaded.emit()
		return
	var parsed = json.get_data()
	if not parsed is Dictionary:
		push_warning("MetaProgressionManager: unexpected save format. Starting fresh.")
		_clear_static_inventory_if_needed(_data)
		progress_loaded.emit()
		return
	_merge_with_defaults(parsed)
	_clear_static_inventory_if_needed(_data)
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
	gold_changed.emit(get_gold())
	equipment_materials_changed.emit(get_equipment_materials())


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


func get_gold() -> int:
	return int(_data.get("gold", 0))


func set_gold(amount: int) -> void:
	_data["gold"] = maxi(amount, 0)
	gold_changed.emit(get_gold())
	save_progress()


func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	_data["gold"] = get_gold() + amount
	gold_changed.emit(get_gold())
	save_progress()


func spend_gold(amount: int) -> bool:
	if amount <= 0:
		return true
	if get_gold() < amount:
		return false
	_data["gold"] = get_gold() - amount
	gold_changed.emit(get_gold())
	save_progress()
	return true


func get_material_ids() -> Array[String]:
	if _equipment_provider != null and _equipment_provider.has_method("get_material_ids"):
		return _equipment_provider.get_material_ids()
	return ["common_dust", "uncommon_dust", "rare_dust", "epic_core", "legendary_core", "mythic_core"]


func get_material_for_rarity(rarity: String) -> String:
	if _equipment_provider != null and _equipment_provider.has_method("get_material_for_rarity"):
		return str(_equipment_provider.get_material_for_rarity(rarity))
	match rarity:
		"uncommon": return "uncommon_dust"
		"rare": return "rare_dust"
		"epic": return "epic_core"
		"legendary": return "legendary_core"
		"mythic": return "mythic_core"
		_: return "common_dust"


func get_material_display_name(material_id: String) -> String:
	if _equipment_provider != null and _equipment_provider.has_method("get_material_display_name"):
		return str(_equipment_provider.get_material_display_name(material_id))
	return material_id.replace("_", " ").capitalize()


func is_valid_material_id(material_id: String) -> bool:
	if _equipment_provider != null and _equipment_provider.has_method("is_valid_material_id"):
		return bool(_equipment_provider.is_valid_material_id(material_id))
	return material_id in get_material_ids()


func get_equipment_materials() -> Dictionary:
	_ensure_equipment_material_defaults()
	return _data.get("equipment_materials", {}).duplicate(true)


func get_equipment_material_amount(material_id: String) -> int:
	_ensure_equipment_material_defaults()
	if not is_valid_material_id(material_id):
		return 0
	var materials: Dictionary = _data.get("equipment_materials", {})
	return int(materials.get(material_id, 0))


func set_equipment_material_amount(material_id: String, amount: int) -> void:
	if not is_valid_material_id(material_id):
		return
	_ensure_equipment_material_defaults()
	var materials: Dictionary = _data.get("equipment_materials", {})
	materials[material_id] = maxi(amount, 0)
	_data["equipment_materials"] = materials
	equipment_materials_changed.emit(materials.duplicate(true))
	save_progress()


func add_equipment_material(material_id: String, amount: int) -> void:
	if amount <= 0 or not is_valid_material_id(material_id):
		return
	_ensure_equipment_material_defaults()
	var materials: Dictionary = _data.get("equipment_materials", {})
	materials[material_id] = int(materials.get(material_id, 0)) + amount
	_data["equipment_materials"] = materials
	equipment_materials_changed.emit(materials.duplicate(true))
	save_progress()


func can_spend_equipment_materials(material_cost: Dictionary) -> bool:
	_ensure_equipment_material_defaults()
	var materials: Dictionary = _data.get("equipment_materials", {})
	for material_id in material_cost:
		var key := str(material_id)
		var amount := int(material_cost.get(material_id, 0))
		if amount <= 0:
			continue
		if not is_valid_material_id(key):
			return false
		if int(materials.get(key, 0)) < amount:
			return false
	return true


func spend_equipment_materials(material_cost: Dictionary) -> bool:
	if not can_spend_equipment_materials(material_cost):
		return false
	_ensure_equipment_material_defaults()
	var materials: Dictionary = _data.get("equipment_materials", {})
	for material_id in material_cost:
		var key := str(material_id)
		var amount := int(material_cost.get(material_id, 0))
		if amount <= 0:
			continue
		materials[key] = maxi(int(materials.get(key, 0)) - amount, 0)
	_data["equipment_materials"] = materials
	equipment_materials_changed.emit(materials.duplicate(true))
	save_progress()
	return true


func get_training_level(hero_id: String, upgrade_id: String) -> int:
	var resolved_hero_id := _resolve_hero_id(hero_id)
	if not _is_training_node_for_hero(upgrade_id, resolved_hero_id):
		return 0
	ensure_training_data_for_hero(resolved_hero_id)
	var training_by_hero: Dictionary = _data.get("training_by_hero", {})
	var hero_training: Dictionary = training_by_hero.get(resolved_hero_id, {})
	return int(hero_training.get(upgrade_id, 0))


func set_training_level(hero_id: String, upgrade_id: String, level: int) -> void:
	var resolved_hero_id := _resolve_hero_id(hero_id)
	if not _is_training_node_for_hero(upgrade_id, resolved_hero_id):
		return
	ensure_training_data_for_hero(resolved_hero_id)
	var def := get_training_definition(resolved_hero_id, upgrade_id)
	var max_level := int(def.get("max_level", 0))
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
		"definitions": get_training_definitions_for_hero(resolved_hero_id),
		"effect_modifiers": get_training_effect_modifiers_for_hero(resolved_hero_id),
		"effect_summary": get_training_effect_summary_for_hero(resolved_hero_id),
		"equipment": get_equipment_summary_for_hero(resolved_hero_id),
	}


func get_training_definitions_for_hero(hero_id: String) -> Array[Dictionary]:
	if _training_provider == null:
		return []
	return _training_provider.get_training_nodes_for_hero(_resolve_hero_id(hero_id))


func get_training_definitions_for_category(hero_id: String, category: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node in get_training_definitions_for_hero(hero_id):
		if str(node.get("category", "")) == category:
			result.append(node)
	return result


func get_training_progress_summary_for_hero(hero_id: String) -> Dictionary:
	var resolved_hero_id := _resolve_hero_id(hero_id)
	var defs := get_training_definitions_for_hero(resolved_hero_id)
	var total_level := 0
	var max_total_level := 0
	var categories: Dictionary = {}
	for node in defs:
		var category := str(node.get("category", ""))
		var max_level := int(node.get("max_level", 0))
		var level := get_training_level(resolved_hero_id, str(node.get("id", "")))
		total_level += level
		max_total_level += max_level
		if not categories.has(category):
			categories[category] = {"level": 0, "max": 0}
		categories[category]["level"] = int(categories[category]["level"]) + level
		categories[category]["max"] = int(categories[category]["max"]) + max_level
	return {
		"hero_id": resolved_hero_id,
		"total_level": total_level,
		"max_total_level": max_total_level,
		"categories": categories,
	}


func get_training_definition(hero_id: String, node_id: String) -> Dictionary:
	if _training_provider == null:
		return {}
	var def: Dictionary = _training_provider.get_training_node(node_id)
	if def.is_empty() or str(def.get("hero_id", "")) != _resolve_hero_id(hero_id):
		return {}
	return def


func get_training_categories() -> Array[String]:
	if _training_provider != null:
		return _training_provider.get_categories()
	return []


func get_training_effect_modifiers_for_hero(hero_id: String) -> Dictionary:
	var resolved_hero_id := _resolve_hero_id(hero_id)
	ensure_training_data_for_hero(resolved_hero_id)
	var result := {}
	for node in get_training_definitions_for_hero(resolved_hero_id):
		var node_id := str(node.get("id", ""))
		var level := get_training_level(resolved_hero_id, node_id)
		if level <= 0:
			continue
		var effect_type := str(node.get("effect_type", ""))
		if effect_type.is_empty():
			continue
		var total := float(node.get("effect_per_level", 0.0)) * float(level)
		result[effect_type] = float(result.get(effect_type, 0.0)) + total
	if result.has("damage_reduction"):
		result["damage_reduction"] = clampf(float(result.get("damage_reduction", 0.0)), 0.0, TRAINING_DAMAGE_REDUCTION_CAP)
	return result


func get_training_stat_modifiers_for_hero(hero_id: String) -> Dictionary:
	var resolved_hero_id := _resolve_hero_id(hero_id)
	ensure_training_data_for_hero(resolved_hero_id)
	var result := {
		"max_health": 0.0,
		"base_damage": 0.0,
		"damage_reduction": 0.0,
	}
	for node in get_training_definitions_for_hero(resolved_hero_id):
		if str(node.get("target", "")) != "hero_stats":
			continue
		var effect_type := str(node.get("effect_type", ""))
		if not result.has(effect_type):
			continue
		var level := get_training_level(resolved_hero_id, str(node.get("id", "")))
		if level <= 0:
			continue
		result[effect_type] = float(result.get(effect_type, 0.0)) + float(node.get("effect_per_level", 0.0)) * float(level)
	result["damage_reduction"] = clampf(float(result.get("damage_reduction", 0.0)), 0.0, TRAINING_DAMAGE_REDUCTION_CAP)
	return result


func get_training_effect_summary_for_hero(hero_id: String) -> Array[Dictionary]:
	var resolved_hero_id := _resolve_hero_id(hero_id)
	ensure_training_data_for_hero(resolved_hero_id)
	var grouped := {}
	for node in get_training_definitions_for_hero(resolved_hero_id):
		var node_id := str(node.get("id", ""))
		var level := get_training_level(resolved_hero_id, node_id)
		if level <= 0:
			continue
		var effect_type := str(node.get("effect_type", ""))
		var target := str(node.get("target", ""))
		var key := "%s|%s" % [target, effect_type]
		var entry: Dictionary = grouped.get(key, {
			"hero_id": resolved_hero_id,
			"target": target,
			"effect_type": effect_type,
			"total": 0.0,
			"levels": 0,
			"node_ids": [],
		})
		entry["total"] = float(entry.get("total", 0.0)) + float(node.get("effect_per_level", 0.0)) * float(level)
		entry["levels"] = int(entry.get("levels", 0)) + level
		var node_ids: Array = entry.get("node_ids", [])
		node_ids.append(node_id)
		entry["node_ids"] = node_ids
		grouped[key] = entry

	for key in grouped:
		var entry: Dictionary = grouped.get(key, {})
		if str(entry.get("effect_type", "")) == "damage_reduction":
			entry["total"] = clampf(float(entry.get("total", 0.0)), 0.0, TRAINING_DAMAGE_REDUCTION_CAP)
			grouped[key] = entry

	var result: Array[Dictionary] = []
	for key in grouped:
		result.append(grouped.get(key, {}).duplicate(true))
	result.sort_custom(func(a, b):
		var at := str(a.get("target", ""))
		var bt := str(b.get("target", ""))
		if at == bt:
			return str(a.get("effect_type", "")) < str(b.get("effect_type", ""))
		return at < bt
	)
	return result


func get_training_ability_modifiers_for_hero(hero_id: String) -> Dictionary:
	var resolved_hero_id := _resolve_hero_id(hero_id)
	ensure_training_data_for_hero(resolved_hero_id)
	var result := {}
	var ability_categories := ["ability_1", "ability_2", "ability_3"]
	for node in get_training_definitions_for_hero(resolved_hero_id):
		var category := str(node.get("category", ""))
		if category not in ability_categories:
			continue
		var node_id := str(node.get("id", ""))
		var level := get_training_level(resolved_hero_id, node_id)
		if level <= 0:
			continue
		var target := str(node.get("target", ""))
		var effect_type := str(node.get("effect_type", ""))
		if target.is_empty() or effect_type.is_empty():
			continue
		var total := float(node.get("effect_per_level", 0.0)) * float(level)
		if not result.has(target):
			result[target] = {}
		var target_dict: Dictionary = result.get(target, {})
		target_dict[effect_type] = float(target_dict.get(effect_type, 0.0)) + total
		result[target] = target_dict
	return result


func get_training_ability_modifiers_for_target(hero_id: String, target: String) -> Dictionary:
	var all_mods := get_training_ability_modifiers_for_hero(hero_id)
	var target_mods = all_mods.get(target, {})
	if target_mods is Dictionary:
		return target_mods.duplicate()
	return {}


func get_training_ability_summary_for_hero(hero_id: String) -> Array[Dictionary]:
	var resolved_hero_id := _resolve_hero_id(hero_id)
	ensure_training_data_for_hero(resolved_hero_id)
	var result: Array[Dictionary] = []
	var ability_categories := ["ability_1", "ability_2", "ability_3"]
	for node in get_training_definitions_for_hero(resolved_hero_id):
		var category := str(node.get("category", ""))
		if category not in ability_categories:
			continue
		var node_id := str(node.get("id", ""))
		var level := get_training_level(resolved_hero_id, node_id)
		if level <= 0:
			continue
		result.append({
			"node_id": node_id,
			"name": str(node.get("name", node_id)),
			"category": category,
			"target": str(node.get("target", "")),
			"effect_type": str(node.get("effect_type", "")),
			"level": level,
			"total": float(node.get("effect_per_level", 0.0)) * float(level),
		})
	return result


func debug_get_training_ability_summary(hero_id: String) -> Dictionary:
	var resolved_hero_id := _resolve_hero_id(hero_id)
	ensure_training_data_for_hero(resolved_hero_id)
	var ignored_invalid: Array[String] = []
	var training_by_hero: Dictionary = _data.get("training_by_hero", {})
	var hero_training: Dictionary = training_by_hero.get(resolved_hero_id, {}) if training_by_hero.get(resolved_hero_id, {}) is Dictionary else {}
	for node_id in hero_training:
		var level := int(hero_training.get(node_id, 0))
		if level <= 0:
			continue
		var node := get_training_definition(resolved_hero_id, str(node_id))
		if node.is_empty():
			ignored_invalid.append(str(node_id))
	return {
		"hero_id": resolved_hero_id,
		"purchased_ability_nodes": get_training_ability_summary_for_hero(resolved_hero_id),
		"aggregated_ability_modifiers": get_training_ability_modifiers_for_hero(resolved_hero_id),
		"target_breakdown": get_training_ability_modifiers_for_hero(resolved_hero_id),
		"ignored_invalid_nodes": ignored_invalid,
	}


func get_training_passive_modifiers_for_hero(hero_id: String) -> Dictionary:
	var resolved_hero_id := _resolve_hero_id(hero_id)
	ensure_training_data_for_hero(resolved_hero_id)
	var result := {}
	for node in get_training_definitions_for_hero(resolved_hero_id):
		if str(node.get("category", "")) != "passive":
			continue
		var node_id := str(node.get("id", ""))
		var level := get_training_level(resolved_hero_id, node_id)
		if level <= 0:
			continue
		var effect_type := str(node.get("effect_type", ""))
		if effect_type.is_empty():
			continue
		var total := float(node.get("effect_per_level", 0.0)) * float(level)
		result[effect_type] = float(result.get(effect_type, 0.0)) + total
	return result


func get_training_passive_summary_for_hero(hero_id: String) -> Array[Dictionary]:
	var resolved_hero_id := _resolve_hero_id(hero_id)
	ensure_training_data_for_hero(resolved_hero_id)
	var result: Array[Dictionary] = []
	for node in get_training_definitions_for_hero(resolved_hero_id):
		if str(node.get("category", "")) != "passive":
			continue
		var node_id := str(node.get("id", ""))
		var level := get_training_level(resolved_hero_id, node_id)
		if level <= 0:
			continue
		result.append({
			"node_id": node_id,
			"name": str(node.get("name", node_id)),
			"category": "passive",
			"target": str(node.get("target", "")),
			"effect_type": str(node.get("effect_type", "")),
			"level": level,
			"total": float(node.get("effect_per_level", 0.0)) * float(level),
		})
	return result


func debug_get_training_passive_summary(hero_id: String) -> Dictionary:
	var resolved_hero_id := _resolve_hero_id(hero_id)
	ensure_training_data_for_hero(resolved_hero_id)
	var ignored_invalid: Array[String] = []
	var training_by_hero: Dictionary = _data.get("training_by_hero", {})
	var hero_training: Dictionary = training_by_hero.get(resolved_hero_id, {}) if training_by_hero.get(resolved_hero_id, {}) is Dictionary else {}
	for node_id in hero_training:
		var level := int(hero_training.get(node_id, 0))
		if level <= 0:
			continue
		var node := get_training_definition(resolved_hero_id, str(node_id))
		if node.is_empty():
			ignored_invalid.append(str(node_id))
	return {
		"hero_id": resolved_hero_id,
		"purchased_passive_nodes": get_training_passive_summary_for_hero(resolved_hero_id),
		"aggregated_passive_modifiers": get_training_passive_modifiers_for_hero(resolved_hero_id),
		"ignored_invalid_nodes": ignored_invalid,
	}


func format_training_modifier(effect_type: String, value: float) -> String:
	match effect_type:
		"max_health":
			return "+%d Max HP" % int(round(value))
		"base_damage":
			return "+%d Base Damage" % int(round(value))
		"damage_reduction":
			return "-%d%% Damage Taken" % int(round(value * 100.0))
		"autoattack_damage":
			return "+%d Autoattack Damage" % int(round(value))
		"ability_damage":
			return "+%d Ability Damage" % int(round(value))
		"passive_gain":
			return "+%s Passive Gain" % _format_training_number(value)
		"rage_gain":
			return "+%s Rage Gain" % _format_training_number(value)
		"mark_damage":
			return "+%d Mark Damage" % int(round(value))
		"slow_strength":
			return "+%d%% Slow Strength" % int(round(value * 100.0))
		"knockback_power":
			return "+%d%% Knockback Power" % int(round(value * 100.0))
		_:
			return "+%s %s" % [_format_training_number(value), effect_type.replace("_", " ").capitalize()]


func format_training_node_modifier(node: Dictionary, value: float) -> String:
	var effect_type := str(node.get("effect_type", ""))
	var tags: Array = node.get("tags", []) if node.get("tags", []) is Array else []
	if effect_type == "ability_damage":
		if "solar_beam" in tags:
			return "+%d Solar Beam Damage" % int(round(value))
		elif "death_dash" in tags:
			return "+%d Death Dash Damage" % int(round(value))
		elif "trap" in tags:
			return "+%d Trap Damage" % int(round(value))
		elif "grappling_hook" in tags:
			return "+%d Hook Damage" % int(round(value))
		elif "rage_wave" in tags:
			return "+%d Rage Wave Damage" % int(round(value))
		elif "rage_leap" in tags:
			return "+%d Rage Leap Damage" % int(round(value))
		elif "mighty_clap" in tags:
			return "+%d Clap Damage" % int(round(value))
	elif effect_type == "slow_strength":
		if "frost_breath" in tags:
			return "+%d%% Ice Breath Slow" % int(round(value * 100.0))
		elif "rage_wave" in tags:
			return "+%d%% Rage Wave Slow" % int(round(value * 100.0))
	elif effect_type == "damage_reduction":
		if "smoke_screen" in tags:
			return "+%d%% Smoke Screen Defense" % int(round(value * 100.0))
	elif effect_type == "knockback_power":
		if "mighty_clap" in tags:
			return "+%d%% Power Clap Knockback" % int(round(value * 100.0))
	elif effect_type == "passive_gain":
		if "solar_energy" in tags:
			return "+%d%% Solar Energy Gain" % int(round(value * 10.0))
	elif effect_type == "mark_damage":
		if "tactical_mark" in tags:
			return "+%d Marked Target Damage" % int(round(value))
	elif effect_type == "rage_gain":
		if "rage" in tags:
			return "+%d%% Rage Gain" % int(round(value * 10.0))
	return format_training_modifier(effect_type, value)


func format_training_node_effect(node_id: String, level: int = 1) -> String:
	var node: Dictionary = get_meta_upgrade_definition(node_id)
	if node.is_empty():
		return ""
	var amount := float(node.get("effect_per_level", 0.0)) * float(maxi(level, 0))
	return format_training_modifier(str(node.get("effect_type", "")), amount)


func get_equipment_definitions(hero_id: String = "") -> Array[Dictionary]:
	if _equipment_provider != null:
		var resolved := _resolve_hero_id(hero_id) if not hero_id.is_empty() else ""
		var result: Array[Dictionary] = []
		for tmpl in _equipment_provider.get_all_item_templates():
			result.append(_adapt_template_to_definition(tmpl, resolved))
		return result
	return []


func get_equipment_definition(hero_id: String, equipment_id: String) -> Dictionary:
	if _equipment_provider != null:
		var tmpl: Dictionary = _equipment_provider.get_item_template(equipment_id)
		if not tmpl.is_empty():
			return _adapt_template_to_definition(tmpl, _resolve_hero_id(hero_id))
	return {}


func _adapt_template_to_definition(tmpl: Dictionary, hero_id: String = "") -> Dictionary:
	if tmpl.is_empty():
		return {}
	var def := tmpl.duplicate(true)
	def["equipment_id"] = str(tmpl.get("id", ""))
	def["display_name"] = str(tmpl.get("name", ""))
	def["description"] = ""
	def["max_level"] = _equipment_provider.MAX_ITEM_LEVEL if _equipment_provider != null else 10
	if not hero_id.is_empty():
		def["hero_id"] = hero_id
	return def


func get_equipment_level(hero_id: String, equipment_id: String) -> int:
	var resolved_hero_id := _resolve_hero_id(hero_id)
	# Try to resolve through equipped instance first
	var def := get_equipment_definition(resolved_hero_id, equipment_id)
	if not def.is_empty():
		var slot_id := str(def.get("slot_id", ""))
		if not slot_id.is_empty():
			var equipped_item := get_equipped_item_for_slot(resolved_hero_id, slot_id)
			if not equipped_item.is_empty() and str(equipped_item.get("template_id", "")) == equipment_id:
				return int(equipped_item.get("level", 0))
	# Fallback to legacy equipment_by_hero
	ensure_equipment_data_for_hero(resolved_hero_id)
	var equipment_by_hero: Dictionary = _data.get("equipment_by_hero", {})
	var hero_equipment: Dictionary = equipment_by_hero.get(resolved_hero_id, {})
	return int(hero_equipment.get(equipment_id, 0))


func set_equipment_level(hero_id: String, equipment_id: String, level: int) -> void:
	var resolved_hero_id := _resolve_hero_id(hero_id)
	var def := get_equipment_definition(resolved_hero_id, equipment_id)
	if def.is_empty():
		return
	ensure_equipment_data_for_hero(resolved_hero_id)
	var clamped_level := clampi(level, 0, int(def.get("max_level", 0)))
	# Update legacy equipment_by_hero
	var equipment_by_hero: Dictionary = _data.get("equipment_by_hero", {})
	var hero_equipment: Dictionary = equipment_by_hero.get(resolved_hero_id, {})
	hero_equipment[equipment_id] = clamped_level
	equipment_by_hero[resolved_hero_id] = hero_equipment
	_data["equipment_by_hero"] = equipment_by_hero
	# Also update inventory instance level for the equipped item in that slot
	var slot_id := str(def.get("slot_id", ""))
	if not slot_id.is_empty():
		var equipped_by_hero: Dictionary = _data.get("equipped_by_hero", {})
		var equipped: Dictionary = equipped_by_hero.get(resolved_hero_id, {}) if equipped_by_hero.get(resolved_hero_id, {}) is Dictionary else {}
		var instance_id := str(equipped.get(slot_id, ""))
		if not instance_id.is_empty():
			_set_inventory_item_level(resolved_hero_id, instance_id, clamped_level)
	equipment_upgrade_changed.emit(resolved_hero_id, equipment_id, clamped_level)


func _set_inventory_item_level(_hero_id: String, instance_id: String, level: int) -> void:
	var items: Array = _data.get("inventory_items", [])
	if not items is Array:
		return
	for i in range(items.size()):
		var item = items[i]
		if item is Dictionary and str(item.get("instance_id", "")) == instance_id:
			item["level"] = level
			items[i] = item
			break
	_data["inventory_items"] = items


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
	var highest_level := 0
	for def in defs:
		var equipment_id := str(def.get("equipment_id", ""))
		var level := int(levels.get(equipment_id, 0))
		if level > 0:
			upgraded_count += 1
		total_levels += level
		max_total_levels += int(def.get("max_level", 0))
		highest_level = maxi(highest_level, level)
	return {
		"hero_id": resolved_hero_id,
		"equipment_count": defs.size(),
		"upgraded_count": upgraded_count,
		"total_levels": total_levels,
		"max_total_levels": max_total_levels,
		"highest_level": highest_level,
		"levels": levels,
		"modifiers": get_equipment_stat_modifiers_for_hero(resolved_hero_id),
	}


func debug_get_equipment_summary() -> Dictionary:
	var result := {}
	for hero_id in DEFAULT_HERO_IDS:
		result[hero_id] = get_equipment_summary_for_hero(hero_id)
	return result


func debug_get_equipment_modifiers_for_hero(hero_id: String) -> Dictionary:
	return get_equipment_stat_modifiers_for_hero(hero_id)


func get_equipment_stat_modifiers_for_hero(hero_id: String) -> Dictionary:
	var resolved_hero_id := _resolve_hero_id(hero_id)
	ensure_equipment_data_for_hero(resolved_hero_id)
	var result := {}
	# Read from global equipped_slots — shared across all heroes
	var equipped := get_equipped_slots()
	if not equipped.is_empty():
		for slot_id in EQUIPMENT_SLOT_IDS:
			var instance_id := str(equipped.get(slot_id, ""))
			if instance_id.is_empty():
				continue
			var item := get_inventory_item("", instance_id)
			if item.is_empty():
				continue
			var template_id := str(item.get("template_id", ""))
			var level := int(item.get("level", 0))
			if level <= 0:
				continue
			var def := _get_item_template(template_id)
			if def.is_empty():
				continue
			var stat_type := str(def.get("stat_bonus_type", ""))
			if stat_type.is_empty():
				continue
			var current := float(result.get(stat_type, 0.0))
			result[stat_type] = current + float(def.get("stat_bonus_per_level", 0.0)) * float(level)
	else:
		# Fallback to legacy equipment_by_hero if no global inventory data exists
		for def in get_equipment_definitions(resolved_hero_id):
			var equipment_id := str(def.get("equipment_id", ""))
			var level := get_equipment_level(resolved_hero_id, equipment_id)
			if level <= 0:
				continue
			var stat_type := str(def.get("stat_bonus_type", ""))
			if stat_type.is_empty():
				continue
			var current := float(result.get(stat_type, 0.0))
			result[stat_type] = current + float(def.get("stat_bonus_per_level", 0.0)) * float(level)
	var set_modifiers := get_set_bonus_stat_modifiers()
	for stat_type in set_modifiers:
		result[stat_type] = float(result.get(stat_type, 0.0)) + float(set_modifiers.get(stat_type, 0.0))
	return result


func get_equipment_upgrade_cost(hero_id: String, equipment_id: String) -> int:
	var resolved_hero_id := _resolve_hero_id(hero_id)
	var def := get_equipment_definition(resolved_hero_id, equipment_id)
	if def.is_empty():
		return 0
	var level := get_equipment_level(resolved_hero_id, equipment_id)
	if level >= int(def.get("max_level", 0)):
		return 0
	return _calculate_upgrade_cost(def, level)


func can_purchase_equipment_upgrade(hero_id: String, equipment_id: String) -> bool:
	var resolved_hero_id := _resolve_hero_id(hero_id)
	var def := get_equipment_definition(resolved_hero_id, equipment_id)
	if def.is_empty():
		return false
	if not is_hero_unlocked(resolved_hero_id):
		return false
	var slot_id := str(def.get("slot_id", ""))
	var equipped_instance_id := get_equipped_instance_id_for_slot(resolved_hero_id, slot_id)
	if equipped_instance_id.is_empty():
		return false
	return can_upgrade_inventory_item(equipped_instance_id)


func purchase_equipment_upgrade(hero_id: String, equipment_id: String) -> bool:
	var resolved_hero_id := _resolve_hero_id(hero_id)
	if not can_purchase_equipment_upgrade(resolved_hero_id, equipment_id):
		return false
	var def := get_equipment_definition(resolved_hero_id, equipment_id)
	if not def.is_empty():
		var slot_id := str(def.get("slot_id", ""))
		if not slot_id.is_empty():
			var equipped_instance_id := get_equipped_instance_id_for_slot(resolved_hero_id, slot_id)
			if not equipped_instance_id.is_empty():
				var result := upgrade_inventory_item(resolved_hero_id, equipped_instance_id)
				return bool(result.get("success", false))
	return false


func get_inventory_item_level(hero_id: String, instance_id: String) -> int:
	var item := get_inventory_item(hero_id, instance_id)
	return int(item.get("level", 0))


func get_inventory_item_max_level(hero_id: String, instance_id: String) -> int:
	var item := get_inventory_item(hero_id, instance_id)
	if item.is_empty():
		return 0
	if _equipment_provider != null:
		return _equipment_provider.MAX_ITEM_LEVEL
	var template_id := str(item.get("template_id", ""))
	var tmpl := _get_item_template(template_id, _resolve_hero_id(hero_id))
	return int(tmpl.get("max_level", 0))


func get_inventory_item_upgrade_cost(hero_id: String, instance_id: String) -> int:
	var cost_data := get_inventory_item_upgrade_cost_data(instance_id)
	return int(cost_data.get("gold", 0))


func get_inventory_item_upgrade_cost_data(instance_id: String) -> Dictionary:
	var item := get_inventory_item("", instance_id)
	if item.is_empty():
		return {"gold": 0, "materials": {}}
	var template_id := str(item.get("template_id", ""))
	var tmpl := _get_item_template(template_id)
	if tmpl.is_empty():
		return {"gold": 0, "materials": {}}
	var level := int(item.get("level", 0))
	var max_level := get_inventory_item_max_level("", instance_id)
	if level >= max_level:
		return {"gold": 0, "materials": {}}
	var rarity := str(tmpl.get("rarity", "common"))
	var config: Dictionary = _RARITY_UPGRADE_COST_CONFIG.get(rarity, _RARITY_UPGRADE_COST_CONFIG["common"])
	var next_level := level + 1
	var gold_cost := int(config.get("gold_base", 20)) * next_level
	var material_id := get_material_for_rarity(rarity)
	var material_cost := int(config.get("material_base", 2)) + int(floor(float(level) / 2.0))
	return {
		"gold": gold_cost,
		"materials": {
			material_id: material_cost,
		},
	}


func get_inventory_item_upgrade_block_reason(instance_id: String) -> String:
	var item := get_inventory_item("", instance_id)
	if item.is_empty():
		return "Item not found."
	var template_id := str(item.get("template_id", ""))
	var tmpl := _get_item_template(template_id)
	if tmpl.is_empty():
		return "Item template not found."
	var level := int(item.get("level", 0))
	var max_level := get_inventory_item_max_level("", instance_id)
	if level >= max_level:
		return "Item is already at max level."
	var cost := get_inventory_item_upgrade_cost_data(instance_id)
	var gold_cost := int(cost.get("gold", 0))
	if gold_cost <= 0:
		return "Upgrade cost unavailable."
	if get_gold() < gold_cost:
		return "Not enough Gold."
	var material_cost: Dictionary = cost.get("materials", {}) if cost.get("materials", {}) is Dictionary else {}
	if not can_spend_equipment_materials(material_cost):
		return "Not enough materials."
	return ""


func can_upgrade_inventory_item(instance_id: String, maybe_instance_id: String = "") -> bool:
	var resolved_instance_id := maybe_instance_id if not maybe_instance_id.is_empty() else instance_id
	return get_inventory_item_upgrade_block_reason(resolved_instance_id).is_empty()


func upgrade_inventory_item(instance_id: String, maybe_instance_id: String = "") -> Dictionary:
	var resolved_hero_id := _resolve_hero_id(instance_id) if not maybe_instance_id.is_empty() else DEFAULT_HERO_ID
	var resolved_instance_id := maybe_instance_id if not maybe_instance_id.is_empty() else instance_id
	var item := get_inventory_item("", resolved_instance_id)
	if item.is_empty():
		return {"success": false, "reason": "Item not found.", "new_level": 0, "cost": {"gold": 0, "materials": {}}}
	var cost := get_inventory_item_upgrade_cost_data(resolved_instance_id)
	var reason := get_inventory_item_upgrade_block_reason(resolved_instance_id)
	if not reason.is_empty():
		return {"success": false, "reason": reason, "new_level": int(item.get("level", 0)), "cost": cost}
	var gold_cost := int(cost.get("gold", 0))
	var material_cost: Dictionary = cost.get("materials", {}) if cost.get("materials", {}) is Dictionary else {}
	if get_gold() < gold_cost or not can_spend_equipment_materials(material_cost):
		return {"success": false, "reason": "Not enough resources.", "new_level": int(item.get("level", 0)), "cost": cost}
	_ensure_equipment_material_defaults()
	var materials: Dictionary = _data.get("equipment_materials", {})
	for material_id in material_cost:
		var key := str(material_id)
		var amount := int(material_cost.get(material_id, 0))
		if amount <= 0:
			continue
		if not is_valid_material_id(key) or int(materials.get(key, 0)) < amount:
			return {"success": false, "reason": "Not enough resources.", "new_level": int(item.get("level", 0)), "cost": cost}
	var level := int(item.get("level", 0))
	var max_level := get_inventory_item_max_level("", resolved_instance_id)
	if level >= max_level:
		return {"success": false, "reason": "Item is already at max level.", "new_level": level, "cost": cost}
	_data["gold"] = get_gold() - gold_cost
	for material_id in material_cost:
		var key := str(material_id)
		var amount := int(material_cost.get(material_id, 0))
		if amount > 0:
			materials[key] = maxi(int(materials.get(key, 0)) - amount, 0)
	_data["equipment_materials"] = materials
	var new_level := level + 1
	_set_inventory_item_level(resolved_hero_id, resolved_instance_id, new_level)
	# Keep legacy equipment_by_hero in sync if this item is equipped in its slot
	var slot_id := str(item.get("slot_id", ""))
	var equipped_instance_id := get_equipped_instance_id_for_slot(resolved_hero_id, slot_id)
	if equipped_instance_id == resolved_instance_id:
		var template_id := str(item.get("template_id", ""))
		ensure_equipment_data_for_hero(resolved_hero_id)
		var equipment_by_hero: Dictionary = _data.get("equipment_by_hero", {})
		var hero_equipment: Dictionary = equipment_by_hero.get(resolved_hero_id, {})
		hero_equipment[template_id] = new_level
		equipment_by_hero[resolved_hero_id] = hero_equipment
		_data["equipment_by_hero"] = equipment_by_hero
		equipment_upgrade_changed.emit(resolved_hero_id, template_id, new_level)
	inventory_item_upgraded.emit(resolved_hero_id, resolved_instance_id, new_level)
	inventory_changed.emit(resolved_hero_id)
	gold_changed.emit(get_gold())
	equipment_materials_changed.emit(materials.duplicate(true))
	save_progress()
	return {"success": true, "reason": "", "new_level": new_level, "cost": cost}


func set_inventory_item_level(hero_id: String, instance_id: String, level: int) -> void:
	var resolved := _resolve_hero_id(hero_id)
	var max_level := get_inventory_item_max_level(resolved, instance_id)
	var clamped := clampi(level, 0, max_level)
	_set_inventory_item_level(resolved, instance_id, clamped)
	# Keep legacy in sync if this item is the currently equipped one
	var item := get_inventory_item(resolved, instance_id)
	var slot_id := str(item.get("slot_id", ""))
	var equipped_instance_id := get_equipped_instance_id_for_slot(resolved, slot_id)
	if equipped_instance_id == instance_id:
		var template_id := str(item.get("template_id", ""))
		ensure_equipment_data_for_hero(resolved)
		var equipment_by_hero: Dictionary = _data.get("equipment_by_hero", {})
		var hero_eq: Dictionary = equipment_by_hero.get(resolved, {})
		hero_eq[template_id] = clamped
		equipment_by_hero[resolved] = hero_eq
		_data["equipment_by_hero"] = equipment_by_hero
		equipment_upgrade_changed.emit(resolved, template_id, clamped)
	inventory_item_upgraded.emit(resolved, instance_id, clamped)
	inventory_changed.emit(resolved)
	save_progress()


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


func debug_get_character_training_summary() -> Dictionary:
	var provider_summary := {}
	if _training_provider != null and _training_provider.has_method("debug_get_training_node_summary"):
		provider_summary = _training_provider.debug_get_training_node_summary()
	var save_levels := {}
	var training_by_hero: Dictionary = _data.get("training_by_hero", {})
	for hero_id in training_by_hero:
		var hero_training: Dictionary = training_by_hero.get(hero_id, {}) if training_by_hero.get(hero_id, {}) is Dictionary else {}
		save_levels[str(hero_id)] = hero_training.duplicate(true)
	provider_summary["save_training_levels_by_hero"] = save_levels
	provider_summary["effect_modifiers_by_hero"] = {}
	for hero_id in DEFAULT_HERO_IDS:
		provider_summary["effect_modifiers_by_hero"][hero_id] = get_training_effect_modifiers_for_hero(hero_id)
	return provider_summary


func debug_get_training_modifier_summary(hero_id: String) -> Dictionary:
	var resolved_hero_id := _resolve_hero_id(hero_id)
	ensure_training_data_for_hero(resolved_hero_id)
	var purchased: Array[Dictionary] = []
	var ignored_invalid: Array[String] = []
	var training_by_hero: Dictionary = _data.get("training_by_hero", {})
	var hero_training: Dictionary = training_by_hero.get(resolved_hero_id, {}) if training_by_hero.get(resolved_hero_id, {}) is Dictionary else {}
	for node_id in hero_training:
		var key := str(node_id)
		var level := int(hero_training.get(node_id, 0))
		if level <= 0:
			continue
		var node := get_training_definition(resolved_hero_id, key)
		if node.is_empty():
			ignored_invalid.append(key)
			continue
		purchased.append({
			"id": key,
			"name": str(node.get("name", key)),
			"category": str(node.get("category", "")),
			"target": str(node.get("target", "")),
			"effect_type": str(node.get("effect_type", "")),
			"level": level,
			"total": float(node.get("effect_per_level", 0.0)) * float(level),
			"display": format_training_modifier(str(node.get("effect_type", "")), float(node.get("effect_per_level", 0.0)) * float(level)),
		})
	return {
		"hero_id": resolved_hero_id,
		"purchased_training_nodes": purchased,
		"aggregated_modifiers": get_training_stat_modifiers_for_hero(resolved_hero_id),
		"all_effect_modifiers": get_training_effect_modifiers_for_hero(resolved_hero_id),
		"ignored_invalid_nodes": ignored_invalid,
	}


func can_purchase_training_upgrade(hero_id: String, upgrade_id: String) -> bool:
	var resolved_hero_id := _resolve_hero_id(hero_id)
	var def := get_training_definition(resolved_hero_id, upgrade_id)
	if def.is_empty():
		return false
	if not is_hero_unlocked(resolved_hero_id):
		return false
	if get_training_level(resolved_hero_id, upgrade_id) >= int(def.get("max_level", 1)):
		return false
	return get_currency() >= get_training_upgrade_cost(resolved_hero_id, upgrade_id)


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
	var hero_training: Dictionary = training_by_hero.get(resolved_hero_id, {})
	for node in get_training_definitions_for_hero(resolved_hero_id):
		var node_id := str(node.get("id", ""))
		if node_id.is_empty():
			continue
		if not hero_training.has(node_id):
			continue
		hero_training[node_id] = clampi(int(hero_training.get(node_id, 0)), 0, int(node.get("max_level", 0)))
	training_by_hero[resolved_hero_id] = hero_training
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
	var resolved_hero_id := _resolve_hero_id(hero_id)
	var def := get_training_definition(resolved_hero_id, upgrade_id)
	if def.is_empty():
		return 0
	var level := get_training_level(resolved_hero_id, upgrade_id)
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
	var item_rewards := grant_item_rewards(summary)
	rewards["item_rewards"] = item_rewards
	summary["item_rewards"] = item_rewards
	save_progress()

	return rewards


func get_progress_summary() -> Dictionary:
	return {
		"currency": get_currency(),
		"gold": get_gold(),
		"equipment_materials": get_equipment_materials(),
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
	return get_training_definitions_for_hero(DEFAULT_HERO_ID)


func get_meta_upgrade_definition(upgrade_id: String) -> Dictionary:
	if _training_provider != null:
		return _training_provider.get_training_node(upgrade_id)
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
		"gold": 0,
		"equipment_materials": _get_default_equipment_materials(),
		"meta_upgrades": {},
		"training_by_hero": _get_default_training_by_hero(),
		"equipment_by_hero": _get_default_equipment_by_hero(),
		"inventory_by_hero": {},
		"equipped_by_hero": {},
		"inventory_items": [],
		"equipped_slots": {},
		"equipment_grants": {},
		"instance_id_counter": 0,
		"inventory_static_items_cleared": false,
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
	if not _data.get("inventory_by_hero") is Dictionary:
		_data["inventory_by_hero"] = {}
	if not _data.get("equipped_by_hero") is Dictionary:
		_data["equipped_by_hero"] = {}
	if not _data.get("inventory_items") is Array:
		_data["inventory_items"] = []
	if not _data.get("equipped_slots") is Dictionary:
		_data["equipped_slots"] = {}
	if not _data.get("equipment_grants") is Dictionary:
		_data["equipment_grants"] = {}
	_data["gold"] = maxi(int(_data.get("gold", 0)), 0)
	_ensure_equipment_material_defaults()
	_migrate_global_training_if_needed(parsed)
	ensure_training_data_for_all_heroes(DEFAULT_HERO_IDS)
	ensure_equipment_data_for_all_heroes(DEFAULT_HERO_IDS)
	_migrate_inventory_if_needed()
	_data["version"] = SAVE_VERSION
	if not _data.get("unlocked_heroes") is Array:
		_data["unlocked_heroes"] = ["guardian", "blaster", "vanguard"]
	var unlocked: Array = _data["unlocked_heroes"]
	if "guardian" not in unlocked:
		unlocked.append("guardian")
	_ensure_mastery_defaults()
	_ensure_goal_defaults()


func _clear_static_inventory_if_needed(data: Dictionary) -> void:
	if bool(data.get("inventory_static_items_cleared", false)):
		return  # already done — idempotent
	var inv: Dictionary = data.get("inventory_by_hero", {})
	var eq: Dictionary = data.get("equipped_by_hero", {})
	var leg: Dictionary = data.get("equipment_by_hero", {})
	for hid in DEFAULT_HERO_IDS:
		inv[hid] = []
		eq[hid] = {}
		if leg.has(hid):
			var hero_leg: Dictionary = leg[hid]
			for k in hero_leg.keys():
				hero_leg[k] = 0
			leg[hid] = hero_leg
	data["inventory_by_hero"] = inv
	data["equipped_by_hero"] = eq
	data["equipment_by_hero"] = leg
	data["inventory_static_items_cleared"] = true


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


func _get_default_equipment_materials() -> Dictionary:
	var result := {}
	for material_id in get_material_ids():
		result[material_id] = 0
	return result


func _ensure_equipment_material_defaults() -> void:
	var materials = _data.get("equipment_materials", {})
	if not materials is Dictionary:
		materials = {}
	for material_id in get_material_ids():
		materials[material_id] = maxi(int(materials.get(material_id, 0)), 0)
	var saved_material_ids: Array = materials.keys()
	for material_id in saved_material_ids:
		if not is_valid_material_id(str(material_id)):
			materials.erase(material_id)
	_data["equipment_materials"] = materials


# ─── Inventory & Equipment Swapping ───────────────────────────────────────────

func _get_alt_item_templates() -> Array:
	return []


func get_alt_item_template(template_id: String) -> Dictionary:
	return get_equipment_definition("", template_id)


func _migrate_inventory_if_needed() -> void:
	# Ensure legacy per-hero structures are valid (backward compat, now read-only)
	var inventory_by_hero: Dictionary = _data.get("inventory_by_hero", {})
	var equipped_by_hero: Dictionary = _data.get("equipped_by_hero", {})
	for hero_id in DEFAULT_HERO_IDS:
		if not inventory_by_hero.has(hero_id) or not inventory_by_hero.get(hero_id) is Array:
			inventory_by_hero[hero_id] = []
		if not equipped_by_hero.has(hero_id) or not equipped_by_hero.get(hero_id) is Dictionary:
			equipped_by_hero[hero_id] = {}
	_data["inventory_by_hero"] = inventory_by_hero
	_data["equipped_by_hero"] = equipped_by_hero
	# Initialize global structures
	if not _data.get("inventory_items") is Array:
		_data["inventory_items"] = []
	if not _data.get("equipped_slots") is Dictionary:
		_data["equipped_slots"] = {}
	if not _data.get("equipment_grants") is Dictionary:
		_data["equipment_grants"] = {}
	# Migrate valid items from per-hero legacy into global inventory if global is still empty
	var global_items: Array = _data.get("inventory_items", [])
	if global_items.is_empty() and _equipment_provider != null:
		var migrated: Array = []
		var seen_ids: Dictionary = {}
		for hero_id in DEFAULT_HERO_IDS:
			var items = inventory_by_hero.get(hero_id, [])
			if not items is Array:
				continue
			for item in items:
				if not item is Dictionary:
					continue
				var iid := str(item.get("instance_id", ""))
				if iid.is_empty() or seen_ids.has(iid):
					continue
				var template_id := str(item.get("template_id", ""))
				if not _equipment_provider.is_valid_template_id(template_id):
					continue
				seen_ids[iid] = true
				var migrated_item: Dictionary = item.duplicate(true)
				migrated_item.erase("hero_id")
				migrated.append(migrated_item)
		if not migrated.is_empty():
			_data["inventory_items"] = migrated
			if (_data.get("equipped_slots", {}) as Dictionary).is_empty():
				for hero_id in DEFAULT_HERO_IDS:
					var eq = equipped_by_hero.get(hero_id, {})
					if eq is Dictionary and not eq.is_empty():
						_data["equipped_slots"] = eq.duplicate(true)
						break
	if _equipment_provider != null:
		_validate_inventory_against_provider()


func _validate_inventory_against_provider() -> void:
	# Validate global inventory_items and prune unknown template_ids
	var items = _data.get("inventory_items", [])
	if not items is Array:
		_data["inventory_items"] = []
		_data["equipped_slots"] = {}
	else:
		var valid_items: Array = []
		var valid_instance_ids: Dictionary = {}
		for item in items:
			if not item is Dictionary:
				continue
			var template_id := str(item.get("template_id", ""))
			if _equipment_provider.is_valid_template_id(template_id):
				valid_items.append(item)
				valid_instance_ids[str(item.get("instance_id", ""))] = true
		_data["inventory_items"] = valid_items
		var equipped: Dictionary = _data.get("equipped_slots", {})
		if equipped is Dictionary:
			for slot_id in equipped.keys():
				var iid := str(equipped.get(slot_id, ""))
				if iid.is_empty() or not valid_instance_ids.has(iid):
					equipped.erase(slot_id)
			_data["equipped_slots"] = equipped
	# Also clear legacy per-hero structures (they are dead data now)
	var inventory_by_hero: Dictionary = _data.get("inventory_by_hero", {})
	var equipped_by_hero: Dictionary = _data.get("equipped_by_hero", {})
	for hero_id in DEFAULT_HERO_IDS:
		inventory_by_hero[hero_id] = []
		equipped_by_hero[hero_id] = {}
	_data["inventory_by_hero"] = inventory_by_hero
	_data["equipped_by_hero"] = equipped_by_hero


func _initialize_starter_inventory(hero_id: String) -> void:
	var inventory_by_hero: Dictionary = _data.get("inventory_by_hero", {})
	var equipped_by_hero: Dictionary = _data.get("equipped_by_hero", {})
	var equipment_by_hero: Dictionary = _data.get("equipment_by_hero", {})
	var old_levels: Dictionary = equipment_by_hero.get(hero_id, {})

	var starter_data := _get_starter_inventory_data(hero_id)
	var inventory: Array = []
	var equipped: Dictionary = {}

	for slot_id in EQUIPMENT_SLOT_IDS:
		var slot_data: Dictionary = starter_data.get(slot_id, {})
		var equipped_template_id: String = str(slot_data.get("equipped_template_id", ""))
		var equipped_instance_id: String = str(slot_data.get("equipped_instance_id", ""))
		if equipped_template_id.is_empty() or equipped_instance_id.is_empty():
			continue
		var old_level := int(old_levels.get(equipped_template_id, 0))
		var item := {
			"instance_id": equipped_instance_id,
			"template_id": equipped_template_id,
			"hero_id": hero_id,
			"slot_id": slot_id,
			"level": old_level,
			"locked": false,
		}
		inventory.append(item)
		equipped[slot_id] = equipped_instance_id

		var alt_template_id: String = str(slot_data.get("alt_template_id", ""))
		var alt_instance_id: String = str(slot_data.get("alt_instance_id", ""))
		if not alt_template_id.is_empty() and not alt_instance_id.is_empty():
			var alt_item := {
				"instance_id": alt_instance_id,
				"template_id": alt_template_id,
				"hero_id": hero_id,
				"slot_id": slot_id,
				"level": 0,
				"locked": false,
			}
			inventory.append(alt_item)

	inventory_by_hero[hero_id] = inventory
	equipped_by_hero[hero_id] = equipped
	_data["inventory_by_hero"] = inventory_by_hero
	_data["equipped_by_hero"] = equipped_by_hero


func _get_starter_inventory_data(_hero_id: String) -> Dictionary:
	return {}


func get_inventory_items() -> Array:
	var items = _data.get("inventory_items", [])
	if items is Array:
		return items.duplicate(true)
	return []


func get_equipped_slots() -> Dictionary:
	var equipped = _data.get("equipped_slots", {})
	if equipped is Dictionary:
		return equipped.duplicate(true)
	return {}


func get_inventory_items_for_hero(_hero_id: String) -> Array:
	return get_inventory_items()


func get_equipped_items_for_hero(_hero_id: String) -> Dictionary:
	return get_equipped_slots()


func get_inventory_item(_hero_id: String, instance_id: String) -> Dictionary:
	var items: Array = _data.get("inventory_items", [])
	if not items is Array:
		return {}
	for item in items:
		if item is Dictionary and str(item.get("instance_id", "")) == instance_id:
			return item.duplicate(true)
	return {}


func get_equipped_item_for_slot(hero_id: String, slot_id: String) -> Dictionary:
	var instance_id := get_equipped_instance_id_for_slot(hero_id, slot_id)
	if instance_id.is_empty():
		return {}
	return get_inventory_item("", instance_id)


func can_equip_inventory_item(_hero_id: String, instance_id: String, slot_id: String) -> bool:
	var item := get_inventory_item("", instance_id)
	if item.is_empty():
		return false
	return str(item.get("slot_id", "")) == slot_id


func equip_inventory_item(hero_id: String, instance_id: String, slot_id: String) -> bool:
	if not can_equip_inventory_item("", instance_id, slot_id):
		return false
	var equipped: Dictionary = _data.get("equipped_slots", {})
	if not equipped is Dictionary:
		equipped = {}
	equipped[slot_id] = instance_id
	_data["equipped_slots"] = equipped
	inventory_changed.emit(hero_id)
	equipment_changed.emit(hero_id, slot_id, instance_id)
	save_progress()
	return true


func can_unequip_slot(_hero_id: String, slot_id: String) -> bool:
	return not get_equipped_instance_id_for_slot("", slot_id).is_empty()


func unequip_slot(hero_id: String, slot_id: String) -> bool:
	if not can_unequip_slot("", slot_id):
		return false
	var equipped: Dictionary = _data.get("equipped_slots", {})
	if not equipped is Dictionary:
		equipped = {}
	equipped.erase(slot_id)
	_data["equipped_slots"] = equipped
	equipment_changed.emit(hero_id, slot_id, "")
	inventory_changed.emit(hero_id)
	save_progress()
	return true


func debug_get_item_template_summary() -> Dictionary:
	if _equipment_provider != null:
		return _equipment_provider.debug_get_item_template_summary()
	return {}


func debug_get_inventory_summary() -> Dictionary:
	var items := get_inventory_items()
	var by_source: Dictionary = {}
	for item in items:
		var src := str(item.get("source", ""))
		by_source[src] = int(by_source.get(src, 0)) + 1
	return {
		"item_count": items.size(),
		"equipped_slots": get_equipped_slots(),
		"items": items,
		"equipment_grants": _data.get("equipment_grants", {}).duplicate(true),
		"items_by_source": by_source,
		"gold": get_gold(),
		"equipment_materials": get_equipment_materials(),
	}


# ─── Starter Equipment Grant ──────────────────────────────────────────────────

func has_equipment_grant(grant_id: String) -> bool:
	var grants = _data.get("equipment_grants", {})
	return grants is Dictionary and bool(grants.get(grant_id, false))


func can_claim_starter_equipment() -> bool:
	return not has_equipment_grant(STARTER_PACK_ID)


func debug_get_equipped_set_summary() -> Array[Dictionary]:
	return get_equipped_set_bonus_summary()


func debug_get_set_bonus_stat_modifiers() -> Dictionary:
	return get_set_bonus_stat_modifiers()


func preview_starter_equipment() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if _equipment_provider == null:
		return result
	for template_id in STARTER_PACK_TEMPLATES:
		var tmpl: Dictionary = _equipment_provider.get_item_template(template_id)
		if not tmpl.is_empty():
			result.append(tmpl.duplicate(true))
	return result


func claim_starter_equipment() -> Array[Dictionary]:
	if not can_claim_starter_equipment():
		return []
	var items: Array = _data.get("inventory_items", [])
	if not items is Array:
		items = []
	var granted: Array[Dictionary] = []
	for template_id in STARTER_PACK_TEMPLATES:
		var item := create_inventory_item_instance(template_id, STARTER_PACK_ID)
		if not item.is_empty():
			items.append(item)
			granted.append(item.duplicate(true))
	_data["inventory_items"] = items
	var grants: Dictionary = _data.get("equipment_grants", {})
	if not grants is Dictionary:
		grants = {}
	grants[STARTER_PACK_ID] = true
	_data["equipment_grants"] = grants
	inventory_changed.emit("")
	save_progress()
	return granted


func create_inventory_item_instance(template_id: String, source: String = "") -> Dictionary:
	if _equipment_provider == null:
		return {}
	var tmpl: Dictionary = _equipment_provider.get_item_template(template_id)
	if tmpl.is_empty():
		return {}
	var slot_id := str(tmpl.get("slot_id", ""))
	var counter := int(_data.get("instance_id_counter", 0)) + 1
	_data["instance_id_counter"] = counter
	return {
		"instance_id": "%s_%04d" % [template_id, counter],
		"template_id": template_id,
		"slot_id": slot_id,
		"level": 0,
		"locked": false,
		"favorite": false,
		"created_index": counter,
		"source": source,
	}


# ─── Item Rewards After Run ───────────────────────────────────────────────────

func _select_item_reward_count(summary: Dictionary) -> int:
	var result := str(summary.get("result", "defeat"))
	var run_time := float(summary.get("run_time", 0.0))
	var final_boss_defeated := bool(summary.get("final_boss_defeated", false))
	if result != "victory":
		return 1 if run_time >= 300.0 else 0
	return 2 if final_boss_defeated else 1


func _select_item_reward_rarity(summary: Dictionary, item_index: int) -> String:
	var result := str(summary.get("result", "defeat"))
	var final_boss_defeated := bool(summary.get("final_boss_defeated", false))
	var objective_completed := bool(summary.get("objective_completed", false))
	var grade := str(summary.get("run_grade", "C"))
	if result != "victory":
		return "common"
	var w_common := 60
	var w_uncommon := 35
	var w_rare := 5
	if objective_completed:
		w_common = 45
		w_uncommon = 45
		w_rare = 10
	if final_boss_defeated and item_index >= 1:
		w_common = 30
		w_uncommon = 45
		w_rare = 25
	if grade == "A" or grade == "S":
		w_rare += 5
	var total := w_common + w_uncommon + w_rare
	var roll := randi() % total
	if roll < w_common:
		return "common"
	if roll < w_common + w_uncommon:
		return "uncommon"
	return "rare"


func _select_item_reward_templates(summary: Dictionary) -> Array[String]:
	var count := _select_item_reward_count(summary)
	if count <= 0 or _equipment_provider == null:
		return []
	var result: Array[String] = []
	for i in range(count):
		var rarity := _select_item_reward_rarity(summary, i)
		var candidates: Array = _equipment_provider.get_templates_by_rarity(rarity)
		if candidates.is_empty():
			candidates = _equipment_provider.get_templates_by_rarity("common")
		if candidates.is_empty():
			continue
		var tmpl: Dictionary = candidates[randi() % candidates.size()]
		var tid := str(tmpl.get("id", ""))
		if not tid.is_empty():
			result.append(tid)
	return result


func calculate_item_rewards(summary: Dictionary) -> Array[Dictionary]:
	if _equipment_provider == null:
		return []
	var template_ids := _select_item_reward_templates(summary)
	var result: Array[Dictionary] = []
	for template_id in template_ids:
		if template_id.is_empty():
			continue
		var tmpl: Dictionary = _equipment_provider.get_item_template(template_id)
		if tmpl.is_empty():
			continue
		result.append({
			"template_id": template_id,
			"name": str(tmpl.get("name", template_id)),
			"slot_id": str(tmpl.get("slot_id", "")),
			"rarity": str(tmpl.get("rarity", "common")),
			"set_id": str(tmpl.get("set_id", "")),
			"stat_bonus_type": str(tmpl.get("stat_bonus_type", "")),
			"stat_bonus_per_level": float(tmpl.get("stat_bonus_per_level", 0.0)),
			"level": 0,
			"source": "run_reward",
		})
	return result


func grant_item_rewards(summary: Dictionary) -> Array[Dictionary]:
	var template_ids := _select_item_reward_templates(summary)
	if template_ids.is_empty():
		return []
	var items: Array = _data.get("inventory_items", [])
	if not items is Array:
		items = []
	var granted: Array[Dictionary] = []
	for template_id in template_ids:
		if template_id.is_empty():
			continue
		var instance := create_inventory_item_instance(template_id, "run_reward")
		if instance.is_empty():
			continue
		var tmpl: Dictionary = _equipment_provider.get_item_template(template_id)
		var display := instance.duplicate(true)
		display["name"] = str(tmpl.get("name", template_id))
		display["rarity"] = str(tmpl.get("rarity", "common"))
		display["set_id"] = str(tmpl.get("set_id", ""))
		display["stat_bonus_type"] = str(tmpl.get("stat_bonus_type", ""))
		display["stat_bonus_per_level"] = float(tmpl.get("stat_bonus_per_level", 0.0))
		items.append(instance)
		granted.append(display)
	_data["inventory_items"] = items
	if not granted.is_empty():
		inventory_changed.emit("")
	return granted


func debug_get_item_reward_preview(summary: Dictionary) -> Array[Dictionary]:
	return calculate_item_rewards(summary)


# ─── Inventory Management ─────────────────────────────────────────────────────

func get_inventory_item_count() -> int:
	var items = _data.get("inventory_items", [])
	return items.size() if items is Array else 0


func get_inventory_capacity() -> int:
	return INVENTORY_CAPACITY


func _set_inventory_item_field(instance_id: String, field: String, value) -> bool:
	var items: Array = _data.get("inventory_items", [])
	if not items is Array:
		return false
	for i in range(items.size()):
		var item = items[i]
		if item is Dictionary and str(item.get("instance_id", "")) == instance_id:
			item[field] = value
			items[i] = item
			_data["inventory_items"] = items
			return true
	return false


func is_inventory_item_locked(instance_id: String) -> bool:
	var item := get_inventory_item("", instance_id)
	return bool(item.get("locked", false))


func set_inventory_item_locked(instance_id: String, locked: bool) -> bool:
	if not _set_inventory_item_field(instance_id, "locked", locked):
		return false
	inventory_changed.emit("")
	save_progress()
	return true


func toggle_inventory_item_locked(instance_id: String) -> bool:
	return set_inventory_item_locked(instance_id, not is_inventory_item_locked(instance_id))


func is_inventory_item_favorite(instance_id: String) -> bool:
	var item := get_inventory_item("", instance_id)
	return bool(item.get("favorite", false))


func set_inventory_item_favorite(instance_id: String, favorite: bool) -> bool:
	if not _set_inventory_item_field(instance_id, "favorite", favorite):
		return false
	inventory_changed.emit("")
	save_progress()
	return true


func toggle_inventory_item_favorite(instance_id: String) -> bool:
	return set_inventory_item_favorite(instance_id, not is_inventory_item_favorite(instance_id))


func _get_inventory_item_rarity(instance_id: String) -> String:
	var item := get_inventory_item("", instance_id)
	if item.is_empty():
		return "common"
	var template_id := str(item.get("template_id", ""))
	var rarity := "common"
	if _equipment_provider != null and not template_id.is_empty():
		var tmpl: Dictionary = _equipment_provider.get_item_template(template_id)
		if not tmpl.is_empty():
			rarity = str(tmpl.get("rarity", "common"))
	return rarity


func get_inventory_item_dismantle_result(instance_id: String) -> Dictionary:
	var item := get_inventory_item("", instance_id)
	if item.is_empty():
		return {"gold": 0, "materials": {}}
	var rarity := _get_inventory_item_rarity(instance_id)
	var material_id := get_material_for_rarity(rarity)
	var level := int(item.get("level", 0))
	var material_amount := int(_RARITY_MATERIAL_BASE.get(rarity, 3)) + int(floor(float(level) / 3.0))
	var gold_amount := int(_RARITY_GOLD_BASE.get(rarity, 5)) + level * 2
	return {
		"gold": gold_amount,
		"materials": {
			material_id: material_amount,
		},
	}


func get_inventory_item_dismantle_block_reason(instance_id: String) -> String:
	var item := get_inventory_item("", instance_id)
	if item.is_empty():
		return "Item not found."
	if bool(item.get("locked", false)):
		return "Locked item cannot be dismantled."
	var equipped := get_equipped_slots()
	for slot in equipped:
		if str(equipped[slot]) == instance_id:
			return "Equipped item cannot be dismantled."
	return ""


func can_dismantle_inventory_item(instance_id: String) -> bool:
	return get_inventory_item_dismantle_block_reason(instance_id).is_empty()


func dismantle_inventory_item(instance_id: String) -> Dictionary:
	var reason := get_inventory_item_dismantle_block_reason(instance_id)
	if not reason.is_empty():
		return {"success": false, "gold": 0, "materials": {}, "reason": reason, "dismantled_item": {}}
	var dismantled_item := get_inventory_item("", instance_id)
	var result := get_inventory_item_dismantle_result(instance_id)
	var items: Array = _data.get("inventory_items", [])
	if not items is Array:
		return {"success": false, "gold": 0, "materials": {}, "reason": "Inventory not initialized.", "dismantled_item": {}}
	for i in range(items.size()):
		var it = items[i]
		if it is Dictionary and str(it.get("instance_id", "")) == instance_id:
			items.remove_at(i)
			break
	_data["inventory_items"] = items
	_data["gold"] = get_gold() + int(result.get("gold", 0))
	_ensure_equipment_material_defaults()
	var current_materials: Dictionary = _data.get("equipment_materials", {})
	var reward_materials: Dictionary = result.get("materials", {}) if result.get("materials", {}) is Dictionary else {}
	for material_id in reward_materials:
		var key := str(material_id)
		if not is_valid_material_id(key):
			continue
		current_materials[key] = maxi(int(current_materials.get(key, 0)) + int(reward_materials.get(material_id, 0)), 0)
	_data["equipment_materials"] = current_materials
	inventory_changed.emit("")
	gold_changed.emit(get_gold())
	equipment_materials_changed.emit(current_materials.duplicate(true))
	save_progress()
	return {
		"success": true,
		"gold": int(result.get("gold", 0)),
		"materials": reward_materials.duplicate(true),
		"reason": "",
		"dismantled_item": dismantled_item,
	}


func get_inventory_item_sell_value(instance_id: String) -> int:
	return int(get_inventory_item_dismantle_result(instance_id).get("gold", 0))


func get_inventory_item_sell_block_reason(instance_id: String) -> String:
	var item := get_inventory_item("", instance_id)
	if item.is_empty():
		return "Item not found."
	if bool(item.get("locked", false)):
		return "Item is locked."
	var equipped := get_equipped_slots()
	for slot in equipped:
		if str(equipped[slot]) == instance_id:
			return "Item is equipped. Unequip first."
	return ""


func can_sell_inventory_item(instance_id: String) -> bool:
	return get_inventory_item_sell_block_reason(instance_id).is_empty()


func sell_inventory_item(instance_id: String) -> Dictionary:
	var reason := get_inventory_item_sell_block_reason(instance_id)
	if not reason.is_empty():
		return {"success": false, "currency_added": 0, "reason": reason, "sold_item": {}}
	var sold_item := get_inventory_item("", instance_id)
	var sell_value := get_inventory_item_sell_value(instance_id)
	var items: Array = _data.get("inventory_items", [])
	if not items is Array:
		return {"success": false, "currency_added": 0, "reason": "Inventory not initialized.", "sold_item": {}}
	for i in range(items.size()):
		var it = items[i]
		if it is Dictionary and str(it.get("instance_id", "")) == instance_id:
			items.remove_at(i)
			break
	_data["inventory_items"] = items
	add_currency(sell_value)
	inventory_changed.emit("")
	save_progress()
	return {"success": true, "currency_added": sell_value, "reason": "", "sold_item": sold_item}


func _get_item_template(template_id: String, _hero_id: String = "") -> Dictionary:
	if _equipment_provider != null:
		var tmpl: Dictionary = _equipment_provider.get_item_template(template_id)
		if not tmpl.is_empty():
			return _adapt_template_to_definition(tmpl, _hero_id)
	return {}


func _get_all_equipment_definitions() -> Array[Dictionary]:
	return []


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
	var base_cost := int(def.get("cost_base", def.get("base_cost", 25)))
	var growth := float(def.get("cost_growth", 1.35))
	if level <= 0:
		return base_cost
	return int(round(float(base_cost) * pow(growth, float(level))))


func _resolve_hero_id(hero_id: String) -> String:
	return hero_id if not hero_id.is_empty() else DEFAULT_HERO_ID


func _format_training_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(round(value)))
	return "%.2f" % value


func _is_training_node_for_hero(node_id: String, hero_id: String) -> bool:
	if _training_provider == null:
		return false
	return _training_provider.is_training_node_for_hero(node_id, _resolve_hero_id(hero_id))


# ─── Equipment Set helpers ────────────────────────────────────────────────────

func get_equipment_sets() -> Array[Dictionary]:
	if _equipment_provider != null and _equipment_provider.has_method("get_all_equipment_sets"):
		return _equipment_provider.get_all_equipment_sets()
	return []


func get_equipment_set(set_id: String) -> Dictionary:
	if _equipment_provider != null and _equipment_provider.has_method("get_equipment_set"):
		return _equipment_provider.get_equipment_set(set_id)
	return {}


func get_item_set_id(instance_id: String) -> String:
	var item := get_inventory_item("", instance_id)
	if item.is_empty():
		return ""
	var template_id := str(item.get("template_id", ""))
	if template_id.is_empty() or _equipment_provider == null:
		return ""
	var tmpl: Dictionary = _equipment_provider.get_item_template(template_id)
	return str(tmpl.get("set_id", ""))


func get_equipped_set_counts() -> Dictionary:
	var result := {}
	var equipped := get_equipped_slots()
	for slot_id in EQUIPMENT_SLOT_IDS:
		var instance_id := str(equipped.get(slot_id, ""))
		if instance_id.is_empty():
			continue
		var set_id := get_item_set_id(instance_id)
		if set_id.is_empty():
			continue
		result[set_id] = int(result.get(set_id, 0)) + 1
	return result


func get_active_set_bonuses() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if _equipment_provider == null or not _equipment_provider.has_method("get_active_set_bonuses"):
		return result
	var counts := get_equipped_set_counts()
	for set_id in counts:
		var active: Array = _equipment_provider.get_active_set_bonuses(str(set_id), int(counts.get(set_id, 0)))
		for bonus in active:
			if not bonus is Dictionary:
				continue
			var entry: Dictionary = bonus.duplicate(true)
			entry["set_id"] = str(set_id)
			entry["piece_count"] = int(counts.get(set_id, 0))
			result.append(entry)
	return result


func get_set_bonus_stat_modifiers() -> Dictionary:
	var result := {}
	for bonus in get_active_set_bonuses():
		var modifiers: Dictionary = bonus.get("modifiers", {}) if bonus.get("modifiers", {}) is Dictionary else {}
		for stat_type in modifiers:
			result[stat_type] = float(result.get(stat_type, 0.0)) + float(modifiers.get(stat_type, 0.0))
	return result


func get_equipped_set_bonus_summary() -> Array[Dictionary]:
	var counts := get_equipped_set_counts()
	var result: Array[Dictionary] = []
	for s in get_equipment_sets():
		var set_id := str(s.get("id", ""))
		var count := int(counts.get(set_id, 0))
		if count <= 0:
			continue
		var active_bonuses: Array = []
		var next_bonus := {}
		if _equipment_provider != null:
			if _equipment_provider.has_method("get_active_set_bonuses"):
				active_bonuses = _equipment_provider.get_active_set_bonuses(set_id, count)
			if _equipment_provider.has_method("get_next_set_bonus"):
				next_bonus = _equipment_provider.get_next_set_bonus(set_id, count)
		result.append({
			"set_id": set_id,
			"name": str(s.get("name", set_id)),
			"count": count,
			"max_count": EQUIPMENT_SLOT_IDS.size(),
			"color": s.get("color", Color.WHITE),
			"theme": str(s.get("theme", "")),
			"active_bonuses": active_bonuses,
			"next_bonus": next_bonus,
			"stat_modifiers": _sum_set_bonus_modifiers(active_bonuses),
		})
	return result


func get_equipped_set_summary() -> Array[Dictionary]:
	return get_equipped_set_bonus_summary()


func _sum_set_bonus_modifiers(bonuses: Array) -> Dictionary:
	var result := {}
	for bonus in bonuses:
		if not bonus is Dictionary:
			continue
		var modifiers: Dictionary = bonus.get("modifiers", {}) if bonus.get("modifiers", {}) is Dictionary else {}
		for stat_type in modifiers:
			result[stat_type] = float(result.get(stat_type, 0.0)) + float(modifiers.get(stat_type, 0.0))
	return result


# ─── Inventory read-only helpers ─────────────────────────────────────────────

func get_item_template_for_instance(hero_id: String, instance_id: String) -> Dictionary:
	var item := get_inventory_item(hero_id, instance_id)
	if item.is_empty():
		return {}
	var template_id := str(item.get("template_id", ""))
	if template_id.is_empty():
		return {}
	return _get_item_template(template_id, _resolve_hero_id(hero_id))


func get_equipped_instance_id_for_slot(_hero_id: String, slot_id: String) -> String:
	var equipped := get_equipped_slots()
	return str(equipped.get(slot_id, ""))


func get_item_stat_total(hero_id: String, instance_id: String) -> Dictionary:
	var item := get_inventory_item(hero_id, instance_id)
	if item.is_empty():
		return {}
	var level := int(item.get("level", 0))
	var template_id := str(item.get("template_id", ""))
	var tmpl := _get_item_template(template_id, _resolve_hero_id(hero_id))
	if tmpl.is_empty():
		return {}
	var stat_type := str(tmpl.get("stat_bonus_type", ""))
	var per_level := float(tmpl.get("stat_bonus_per_level", 0.0))
	return {
		"stat_type": stat_type,
		"total": per_level * float(level),
		"per_level": per_level,
		"level": level,
	}


func _sync_legacy_meta_upgrades() -> void:
	var training_by_hero: Dictionary = _data.get("training_by_hero", {})
	var default_training: Dictionary = training_by_hero.get(DEFAULT_HERO_ID, {})
	_data["meta_upgrades"] = default_training.duplicate()


# ─── Item & Loadout Power ──────────────────────────────────────────────────────
# All item templates use flat stats; weights reflect per-point impact.
# These weights affect only the UI power score — never gameplay.
const STAT_POWER_WEIGHTS := {
	"attack_damage": 10,
	"max_health": 2,
	"shield_capacity": 25,
	"impact_damage": 8,
	"mark_damage": 8,
	"support_damage": 8,
	"rage_gain": 8,
	"low_health_damage": 8,
	"ability_damage": 8,
	"ability_cooldown": 8,
	"xp_gain": 6,
	"knockback_resist": 6,
}


func get_inventory_item_power(instance_id: String) -> int:
	return int(get_inventory_item_power_details(instance_id).get("power", 0))


func get_inventory_item_power_details(instance_id: String) -> Dictionary:
	var item := get_inventory_item("", instance_id)
	if item.is_empty():
		return {"power": 0, "stat_type": "", "stat_total": 0.0, "weight": 0}
	var level := int(item.get("level", 0))
	var template_id := str(item.get("template_id", ""))
	if template_id.is_empty() or _equipment_provider == null:
		return {"power": 0, "stat_type": "", "stat_total": 0.0, "weight": 0}
	var tmpl: Dictionary = _equipment_provider.get_item_template(template_id)
	if tmpl.is_empty():
		return {"power": 0, "stat_type": "", "stat_total": 0.0, "weight": 0}
	var stat_type := str(tmpl.get("stat_bonus_type", ""))
	var per_level := float(tmpl.get("stat_bonus_per_level", 0.0))
	var stat_total := per_level * float(level)
	var weight := int(STAT_POWER_WEIGHTS.get(stat_type, 10))
	var power := maxi(int(round(stat_total * float(weight))), 0)
	return {
		"power": power,
		"stat_type": stat_type,
		"stat_total": stat_total,
		"per_level": per_level,
		"level": level,
		"weight": weight,
		"instance_id": instance_id,
	}


func get_set_bonus_power() -> int:
	var total := 0
	for detail in get_set_bonus_power_details():
		total += int(detail.get("power", 0))
	return total


func get_set_bonus_power_details() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for bonus in get_active_set_bonuses():
		var modifiers: Dictionary = bonus.get("modifiers", {}) if bonus.get("modifiers", {}) is Dictionary else {}
		var bonus_power := 0
		for stat_key in modifiers:
			var weight := int(STAT_POWER_WEIGHTS.get(str(stat_key), 10))
			bonus_power += maxi(int(round(float(modifiers.get(stat_key, 0.0)) * float(weight))), 0)
		result.append({
			"set_id": str(bonus.get("set_id", "")),
			"pieces": int(bonus.get("pieces", 0)),
			"piece_count": int(bonus.get("piece_count", 0)),
			"modifiers": modifiers.duplicate(true),
			"power": bonus_power,
		})
	return result


func get_loadout_power_score() -> int:
	return int(get_loadout_summary().get("power_score", 0))


func get_loadout_summary() -> Dictionary:
	var equipped := get_equipped_slots()
	var item_powers := {}
	var equipped_count := 0
	var empty_slots: Array[String] = []
	var all_item_entries: Array[Dictionary] = []

	for slot_id in EQUIPMENT_SLOT_IDS:
		var instance_id := str(equipped.get(slot_id, ""))
		if instance_id.is_empty():
			empty_slots.append(slot_id)
			item_powers[slot_id] = 0
		else:
			var power := get_inventory_item_power(instance_id)
			item_powers[slot_id] = power
			equipped_count += 1
			var item := get_inventory_item("", instance_id)
			var template_id := str(item.get("template_id", ""))
			var tmpl: Dictionary = {}
			if _equipment_provider != null and not template_id.is_empty():
				tmpl = _equipment_provider.get_item_template(template_id)
			all_item_entries.append({
				"slot_id": slot_id,
				"instance_id": instance_id,
				"name": str(tmpl.get("name", instance_id)) if not tmpl.is_empty() else instance_id,
				"level": int(item.get("level", 0)),
				"rarity": str(tmpl.get("rarity", "common")) if not tmpl.is_empty() else "common",
				"item_power": power,
			})

	var set_bonus_power := get_set_bonus_power()
	var total_item_power := 0
	for sid in item_powers:
		total_item_power += int(item_powers.get(sid, 0))
	var power_score := total_item_power + set_bonus_power

	var highest_item := {}
	var lowest_item := {}
	for entry in all_item_entries:
		var p := int(entry.get("item_power", 0))
		if highest_item.is_empty() or p > int(highest_item.get("item_power", 0)):
			highest_item = entry.duplicate(true)
		if lowest_item.is_empty() or p < int(lowest_item.get("item_power", 0)):
			lowest_item = entry.duplicate(true)

	return {
		"power_score": power_score,
		"equipped_count": equipped_count,
		"slot_count": EQUIPMENT_SLOT_IDS.size(),
		"empty_slots": empty_slots.duplicate(),
		"highest_item": highest_item,
		"lowest_item": lowest_item,
		"item_powers": item_powers.duplicate(true),
		"stat_modifiers": get_equipment_stat_modifiers_for_hero(DEFAULT_HERO_ID),
		"active_sets": get_equipped_set_bonus_summary(),
		"set_bonus_power": set_bonus_power,
	}


func get_loadout_stat_summary() -> Dictionary:
	return get_equipment_stat_modifiers_for_hero(DEFAULT_HERO_ID)


func get_loadout_slot_summary() -> Dictionary:
	var equipped := get_equipped_slots()
	var result := {}
	for slot_id in EQUIPMENT_SLOT_IDS:
		var instance_id := str(equipped.get(slot_id, ""))
		if instance_id.is_empty():
			result[slot_id] = {"occupied": false, "power": 0}
		else:
			result[slot_id] = {
				"occupied": true,
				"power": get_inventory_item_power(instance_id),
				"instance_id": instance_id,
			}
	return result


func get_loadout_set_summary() -> Array[Dictionary]:
	return get_equipped_set_bonus_summary()


func debug_get_loadout_summary() -> Dictionary:
	var summary := get_loadout_summary()
	summary["item_power_details"] = debug_get_item_power_summary()
	summary["set_bonus_details"] = get_set_bonus_power_details()
	return summary


func debug_get_item_power_summary() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var equipped := get_equipped_slots()
	for slot_id in EQUIPMENT_SLOT_IDS:
		var instance_id := str(equipped.get(slot_id, ""))
		if instance_id.is_empty():
			result.append({"slot_id": slot_id, "occupied": false, "power": 0})
		else:
			var details := get_inventory_item_power_details(instance_id)
			details["slot_id"] = slot_id
			details["occupied"] = true
			result.append(details)
	return result
