extends Node

const MAX_ITEM_LEVEL := 10
const SLOT_IDS: Array[String] = ["core", "suit", "emblem", "gauntlets", "boots", "artifact"]
const RARITIES: Array[String] = ["common", "uncommon", "rare", "epic", "legendary", "mythic"]
const SET_IDS: Array[String] = ["storm_set", "titan_set", "solar_set", "tactical_set", "fury_set"]

var _templates: Array[Dictionary] = []
var _template_index: Dictionary = {}
var _sets: Array[Dictionary] = []
var _set_index: Dictionary = {}


func _ready() -> void:
	_sets = _build_sets()
	for s in _sets:
		var sid := str(s.get("id", ""))
		if not sid.is_empty():
			_set_index[sid] = s
	_templates = _build_templates()
	for tmpl in _templates:
		var tid := str(tmpl.get("id", ""))
		if not tid.is_empty():
			_template_index[tid] = tmpl


# ─── Item Template API ────────────────────────────────────────────────────────

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


func get_templates_for_set(set_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for tmpl in _templates:
		if str(tmpl.get("set_id", "")) == set_id:
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


# ─── Equipment Set API ────────────────────────────────────────────────────────

func get_all_equipment_sets() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for s in _sets:
		result.append(s.duplicate(true))
	return result


func get_equipment_set(set_id: String) -> Dictionary:
	var s: Dictionary = _set_index.get(set_id, {})
	return s.duplicate(true) if not s.is_empty() else {}


func get_equipment_set_display_name(set_id: String) -> String:
	var s: Dictionary = _set_index.get(set_id, {})
	if s.is_empty():
		return "No Set" if set_id.is_empty() else set_id.replace("_", " ").capitalize()
	return str(s.get("name", set_id))


func get_equipment_set_color(set_id: String) -> Color:
	var s: Dictionary = _set_index.get(set_id, {})
	if s.is_empty():
		return Color(0.7, 0.75, 0.8, 1.0)
	var c = s.get("color", Color.WHITE)
	return c as Color


func get_equipment_set_bonuses(set_id: String) -> Array[Dictionary]:
	var s: Dictionary = _set_index.get(set_id, {})
	if s.is_empty():
		return []
	var result: Array[Dictionary] = []
	var bonuses: Array = s.get("bonuses", [])
	for bonus in bonuses:
		if bonus is Dictionary:
			result.append(bonus.duplicate(true))
	return result


func get_active_set_bonuses(set_id: String, piece_count: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for bonus in get_equipment_set_bonuses(set_id):
		if int(bonus.get("pieces", 0)) <= piece_count:
			result.append(bonus.duplicate(true))
	return result


func get_next_set_bonus(set_id: String, piece_count: int) -> Dictionary:
	for bonus in get_equipment_set_bonuses(set_id):
		if int(bonus.get("pieces", 0)) > piece_count:
			return bonus.duplicate(true)
	return {}


func get_set_bonus_thresholds(set_id: String) -> Array[int]:
	var result: Array[int] = []
	for bonus in get_equipment_set_bonuses(set_id):
		var pieces := int(bonus.get("pieces", 0))
		if pieces > 0:
			result.append(pieces)
	result.sort()
	return result


func is_valid_set_id(set_id: String) -> bool:
	return _set_index.has(set_id)


# ─── Debug ────────────────────────────────────────────────────────────────────

func debug_get_item_template_summary() -> Dictionary:
	var by_slot := {}
	var by_rarity := {}
	var by_set := {}
	for slot in SLOT_IDS:
		by_slot[slot] = 0
	for rarity in RARITIES:
		by_rarity[rarity] = 0
	for set_id in SET_IDS:
		by_set[set_id] = 0
	for tmpl in _templates:
		var slot := str(tmpl.get("slot_id", ""))
		var rarity := str(tmpl.get("rarity", ""))
		var set_id := str(tmpl.get("set_id", ""))
		if by_slot.has(slot):
			by_slot[slot] += 1
		if by_rarity.has(rarity):
			by_rarity[rarity] += 1
		if by_set.has(set_id):
			by_set[set_id] += 1
	return {
		"total_templates": _templates.size(),
		"by_slot": by_slot,
		"by_rarity": by_rarity,
		"by_set": by_set,
		"total_sets": _sets.size(),
		"max_item_level": MAX_ITEM_LEVEL,
		"supported_rarities": RARITIES.duplicate(),
		"slot_ids": SLOT_IDS.duplicate(),
		"set_ids": SET_IDS.duplicate(),
	}


# ─── Data builders ────────────────────────────────────────────────────────────

func _build_templates() -> Array[Dictionary]:
	return [
		#                  id                         name                   slot         rarity      set_id          stat_bonus_type      per_lvl  cost  growth  tags
		_t("power_core_common",       "Power Core",         "core",      "common",   "fury_set",     "attack_damage",    1.0,   50,  1.35, ["offense"]),
		_t("cooldown_core_uncommon",  "Cooldown Core",      "core",      "uncommon", "storm_set",    "ability_cooldown", 0.008, 65,  1.37, ["ability"]),
		_t("reinforced_suit_common",  "Reinforced Suit",    "suit",      "common",   "titan_set",    "max_health",       5.0,   50,  1.34, ["defense"]),
		_t("vitality_suit_uncommon",  "Vitality Suit",      "suit",      "uncommon", "titan_set",    "max_health",       7.0,   65,  1.36, ["defense"]),
		_t("awareness_emblem_common", "Awareness Emblem",   "emblem",    "common",   "storm_set",    "xp_gain",          0.01,  45,  1.33, ["utility"]),
		_t("battle_emblem_uncommon",  "Battle Emblem",      "emblem",    "uncommon", "tactical_set", "attack_damage",    1.5,   60,  1.35, ["offense"]),
		_t("striker_gauntlets_common","Striker Gauntlets",  "gauntlets", "common",   "fury_set",     "attack_damage",    1.0,   55,  1.35, ["offense"]),
		_t("force_gauntlets_uncommon","Force Gauntlets",    "gauntlets", "uncommon", "solar_set",    "ability_damage",   0.015, 70,  1.37, ["ability"]),
		_t("runner_boots_common",     "Runner Boots",       "boots",     "common",   "storm_set",    "move_speed",       3.0,   45,  1.32, ["mobility"]),
		_t("momentum_boots_uncommon", "Momentum Boots",     "boots",     "uncommon", "storm_set",    "move_speed",       4.0,   60,  1.34, ["mobility"]),
		_t("shield_artifact_common",  "Shield Artifact",    "artifact",  "common",   "solar_set",    "shield_capacity",  1.0,   70,  1.40, ["support"]),
		_t("fury_artifact_uncommon",  "Fury Artifact",      "artifact",  "uncommon", "fury_set",     "low_health_damage",0.02,  85,  1.40, ["offense"]),
		_t("apex_artifact_rare",      "Apex Artifact",      "artifact",  "rare",     "solar_set",    "ability_damage",   0.025, 110, 1.45, ["ability"]),
	]


func _build_sets() -> Array[Dictionary]:
	return [
		_s("storm_set",    "Storm Set",    "speed / cooldown / ability flow",   Color(0.30, 0.70, 1.00, 1.0), ["speed", "ability", "cooldown"], [
			_b(2, {"move_speed": 0.05}),
			_b(4, {"ability_cooldown": 0.08}),
			_b(6, {"ability_damage": 0.10, "move_speed": 0.05}),
		]),
		_s("titan_set",    "Titan Set",    "health / resist / heavy impact",     Color(0.50, 0.75, 0.40, 1.0), ["defense", "health"], [
			_b(2, {"max_health": 15.0}),
			_b(4, {"knockback_resist": 0.10}),
			_b(6, {"max_health": 25.0, "shield_capacity": 2.0}),
		]),
		_s("solar_set",    "Solar Set",    "ability damage / shield / radiance", Color(1.00, 0.82, 0.20, 1.0), ["ability", "shield"], [
			_b(2, {"ability_damage": 0.06}),
			_b(4, {"shield_capacity": 2.0}),
			_b(6, {"ability_damage": 0.12, "low_health_damage": 0.08}),
		]),
		_s("tactical_set", "Tactical Set", "mark damage / support / precision",  Color(0.70, 0.45, 1.00, 1.0), ["support", "precision"], [
			_b(2, {"xp_gain": 0.05}),
			_b(4, {"mark_damage": 0.10}),
			_b(6, {"support_damage": 0.12, "ability_cooldown": 0.05}),
		]),
		_s("fury_set",     "Fury Set",     "rage / low-health damage / impact",  Color(1.00, 0.45, 0.20, 1.0), ["offense", "impact"], [
			_b(2, {"attack_damage": 3.0}),
			_b(4, {"rage_gain": 0.10}),
			_b(6, {"low_health_damage": 0.15, "impact_damage": 0.10}),
		]),
	]


func _t(id: String, item_name: String, slot_id: String, rarity: String, set_id: String, stat_bonus_type: String, stat_bonus_per_level: float, base_cost: int, cost_growth: float, tags: Array) -> Dictionary:
	return {
		"id": id,
		"name": item_name,
		"slot_id": slot_id,
		"rarity": rarity,
		"set_id": set_id,
		"stat_bonus_type": stat_bonus_type,
		"stat_bonus_per_level": stat_bonus_per_level,
		"base_cost": base_cost,
		"cost_growth": cost_growth,
		"tags": tags,
	}


func _s(id: String, sname: String, theme: String, color: Color, tags: Array, bonuses: Array) -> Dictionary:
	return {
		"id": id,
		"name": sname,
		"theme": theme,
		"color": color,
		"tags": tags,
		"bonuses": bonuses,
	}


func _b(pieces: int, modifiers: Dictionary) -> Dictionary:
	return {
		"pieces": pieces,
		"modifiers": modifiers,
	}
