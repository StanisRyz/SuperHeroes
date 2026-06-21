extends Node

const MAX_ITEM_LEVEL := 10
const SLOT_IDS: Array[String] = ["core", "suit", "emblem", "gauntlets", "boots", "artifact"]
const RARITIES: Array[String] = ["common", "uncommon", "rare", "epic", "legendary", "mythic"]

var _templates: Array[Dictionary] = []
var _template_index: Dictionary = {}


func _ready() -> void:
	_templates = _build_templates()
	for tmpl in _templates:
		var tid := str(tmpl.get("id", ""))
		if not tid.is_empty():
			_template_index[tid] = tmpl


func get_all_item_templates() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for tmpl in _templates:
		result.append(tmpl.duplicate(true))
	return result


func get_item_template(template_id: String) -> Dictionary:
	var tmpl: Dictionary = _template_index.get(template_id, {})
	return tmpl.duplicate(true) if not tmpl.is_empty() else {}


func get_templates_for_slot(slot_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for tmpl in _templates:
		if str(tmpl.get("slot_id", "")) == slot_id:
			result.append(tmpl.duplicate(true))
	return result


func get_templates_by_rarity(rarity: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for tmpl in _templates:
		if str(tmpl.get("rarity", "")) == rarity:
			result.append(tmpl.duplicate(true))
	return result


func get_rarity_values() -> Array[String]:
	return RARITIES.duplicate()


func get_slot_ids() -> Array[String]:
	return SLOT_IDS.duplicate()


func get_max_item_level() -> int:
	return MAX_ITEM_LEVEL


func is_valid_slot(slot_id: String) -> bool:
	return slot_id in SLOT_IDS


func is_valid_rarity(rarity: String) -> bool:
	return rarity in RARITIES


func is_valid_template_id(template_id: String) -> bool:
	return _template_index.has(template_id)


func debug_get_item_template_summary() -> Dictionary:
	var by_slot := {}
	var by_rarity := {}
	for slot in SLOT_IDS:
		by_slot[slot] = 0
	for rarity in RARITIES:
		by_rarity[rarity] = 0
	for tmpl in _templates:
		var slot := str(tmpl.get("slot_id", ""))
		var rarity := str(tmpl.get("rarity", ""))
		if by_slot.has(slot):
			by_slot[slot] += 1
		if by_rarity.has(rarity):
			by_rarity[rarity] += 1
	return {
		"total_templates": _templates.size(),
		"by_slot": by_slot,
		"by_rarity": by_rarity,
		"max_item_level": MAX_ITEM_LEVEL,
		"supported_rarities": RARITIES.duplicate(),
		"slot_ids": SLOT_IDS.duplicate(),
	}


func _build_templates() -> Array[Dictionary]:
	return [
		_t("power_core_common",       "Power Core",         "core",      "common",   "attack_damage",    1.0,   50,  1.35, ["offense"]),
		_t("cooldown_core_uncommon",  "Cooldown Core",      "core",      "uncommon", "ability_cooldown", 0.008, 65,  1.37, ["ability"]),
		_t("reinforced_suit_common",  "Reinforced Suit",    "suit",      "common",   "max_health",       5.0,   50,  1.34, ["defense"]),
		_t("vitality_suit_uncommon",  "Vitality Suit",      "suit",      "uncommon", "max_health",       7.0,   65,  1.36, ["defense"]),
		_t("awareness_emblem_common", "Awareness Emblem",   "emblem",    "common",   "xp_gain",          0.01,  45,  1.33, ["utility"]),
		_t("battle_emblem_uncommon",  "Battle Emblem",      "emblem",    "uncommon", "attack_damage",    1.5,   60,  1.35, ["offense"]),
		_t("striker_gauntlets_common","Striker Gauntlets",  "gauntlets", "common",   "attack_damage",    1.0,   55,  1.35, ["offense"]),
		_t("force_gauntlets_uncommon","Force Gauntlets",    "gauntlets", "uncommon", "ability_damage",   0.015, 70,  1.37, ["ability"]),
		_t("runner_boots_common",     "Runner Boots",       "boots",     "common",   "move_speed",       3.0,   45,  1.32, ["mobility"]),
		_t("momentum_boots_uncommon", "Momentum Boots",     "boots",     "uncommon", "move_speed",       4.0,   60,  1.34, ["mobility"]),
		_t("shield_artifact_common",  "Shield Artifact",    "artifact",  "common",   "shield_capacity",  1.0,   70,  1.40, ["support"]),
		_t("fury_artifact_uncommon",  "Fury Artifact",      "artifact",  "uncommon", "low_health_damage",0.02,  85,  1.40, ["offense"]),
		_t("apex_artifact_rare",      "Apex Artifact",      "artifact",  "rare",     "ability_damage",   0.025, 110, 1.45, ["ability"]),
	]


func _t(id: String, name: String, slot_id: String, rarity: String, stat_bonus_type: String, stat_bonus_per_level: float, base_cost: int, cost_growth: float, tags: Array) -> Dictionary:
	return {
		"id": id,
		"name": name,
		"slot_id": slot_id,
		"rarity": rarity,
		"stat_bonus_type": stat_bonus_type,
		"stat_bonus_per_level": stat_bonus_per_level,
		"base_cost": base_cost,
		"cost_growth": cost_growth,
		"tags": tags,
	}
