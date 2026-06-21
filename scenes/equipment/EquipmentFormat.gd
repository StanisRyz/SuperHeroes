extends RefCounted

const PERCENT_STATS = [
	"ability_cooldown", "ability_damage", "xp_gain", "low_health_damage",
]


static func rarity_display_name(rarity: String) -> String:
	match rarity:
		"common": return "Common"
		"uncommon": return "Uncommon"
		"rare": return "Rare"
		"epic": return "Epic"
		"legendary": return "Legendary"
		"mythic": return "Mythic"
		_: return rarity.capitalize()


static func rarity_short(rarity: String) -> String:
	match rarity:
		"common": return "Cmn"
		"uncommon": return "Unc"
		"rare": return "Rar"
		"epic": return "Epc"
		"legendary": return "Lgd"
		"mythic": return "Mth"
		_: return rarity.left(3).capitalize()


static func rarity_color(rarity: String) -> Color:
	match rarity:
		"common": return Color(0.78, 0.80, 0.85, 1.0)
		"uncommon": return Color(0.35, 0.88, 0.45, 1.0)
		"rare": return Color(0.35, 0.65, 1.00, 1.0)
		"epic": return Color(0.80, 0.40, 1.00, 1.0)
		"legendary": return Color(1.00, 0.72, 0.15, 1.0)
		"mythic": return Color(1.00, 0.35, 0.85, 1.0)
		_: return Color.WHITE


static func rarity_order(rarity: String) -> int:
	match rarity:
		"mythic": return 5
		"legendary": return 4
		"epic": return 3
		"rare": return 2
		"uncommon": return 1
		"common": return 0
		_: return -1


static func slot_display_name(slot_id: String) -> String:
	match slot_id:
		"core": return "Core"
		"suit": return "Suit"
		"emblem": return "Emblem"
		"gauntlets": return "Gauntlets"
		"boots": return "Boots"
		"artifact": return "Artifact"
		_: return slot_id.capitalize()


static func stat_display_name(stat_bonus_type: String) -> String:
	match stat_bonus_type:
		"attack_damage": return "Attack Damage"
		"ability_damage": return "Ability Damage"
		"ability_cooldown": return "Ability Cooldown"
		"xp_gain": return "XP Gain"
		"max_health": return "Max HP"
		"move_speed": return "Move Speed"
		"shield_capacity": return "Shield Capacity"
		"low_health_damage": return "Low Health Damage"
		"mark_damage": return "Mark Damage"
		"support_damage": return "Support Damage"
		"rage_gain": return "Rage Gain"
		"impact_damage": return "Impact Damage"
		"knockback_resist": return "Knockback Resist"
		_: return stat_bonus_type.replace("_", " ").capitalize()


static func _fmt(v: float) -> String:
	var r := roundf(v * 10.0) / 10.0
	if is_equal_approx(r, float(int(r))):
		return str(int(r))
	return "%.1f" % r


static func stat_value_text(stat_bonus_type: String, value: float) -> String:
	var sname := stat_display_name(stat_bonus_type)
	var is_pct: bool = stat_bonus_type in PERCENT_STATS
	if not is_pct and abs(value) > 0.0 and abs(value) < 1.0:
		is_pct = true
	if stat_bonus_type == "ability_cooldown":
		return "-%s%% %s" % [_fmt(abs(value) * 100.0), sname]
	if is_pct:
		return "+%s%% %s" % [_fmt(value * 100.0), sname]
	return "+%s %s" % [_fmt(value), sname]


static func stat_total_text(stat_bonus_type: String, value_per_level: float, level: int) -> String:
	if level <= 0:
		return stat_value_text(stat_bonus_type, value_per_level) + " / level"
	return stat_value_text(stat_bonus_type, value_per_level * float(level))


static func stat_next_text(stat_bonus_type: String, value_per_level: float, level: int) -> String:
	return stat_value_text(stat_bonus_type, value_per_level * float(level + 1))


static func set_display_name(set_id: String, provider: Node = null) -> String:
	if provider != null and provider.has_method("get_equipment_set_display_name"):
		return str(provider.get_equipment_set_display_name(set_id))
	match set_id:
		"storm_set":    return "Storm Set"
		"titan_set":    return "Titan Set"
		"solar_set":    return "Solar Set"
		"tactical_set": return "Tactical Set"
		"fury_set":     return "Fury Set"
		"":             return "No Set"
		_:              return set_id.replace("_", " ").capitalize()


static func set_color(set_id: String, provider: Node = null) -> Color:
	if provider != null and provider.has_method("get_equipment_set_color"):
		return provider.get_equipment_set_color(set_id)
	match set_id:
		"storm_set":    return Color(0.30, 0.70, 1.00, 1.0)
		"titan_set":    return Color(0.50, 0.75, 0.40, 1.0)
		"solar_set":    return Color(1.00, 0.82, 0.20, 1.0)
		"tactical_set": return Color(0.70, 0.45, 1.00, 1.0)
		"fury_set":     return Color(1.00, 0.45, 0.20, 1.0)
		_:              return Color(0.70, 0.75, 0.80, 1.0)


static func modifiers_text(modifiers: Dictionary) -> String:
	if modifiers.is_empty():
		return ""
	var keys := modifiers.keys()
	keys.sort()
	var parts: PackedStringArray = []
	for stat_id in keys:
		var stat_key := str(stat_id)
		parts.append(stat_value_text(stat_key, float(modifiers.get(stat_id, 0.0))))
	return ", ".join(parts)


static func set_bonus_text(bonus: Dictionary) -> String:
	if bonus.is_empty():
		return ""
	var pieces := int(bonus.get("pieces", 0))
	var text := modifiers_text(bonus.get("modifiers", {}) if bonus.get("modifiers", {}) is Dictionary else {})
	if text.is_empty():
		return "%d: none" % pieces
	return "%d: %s" % [pieces, text]


static func item_display_line(item_or_template: Dictionary) -> String:
	var iname := str(item_or_template.get("name",
		item_or_template.get("display_name",
		item_or_template.get("template_id", "?"))))
	var slot := slot_display_name(str(item_or_template.get("slot_id", "")))
	var rarity := rarity_display_name(str(item_or_template.get("rarity", "common")))
	return "%s  —  %s  —  %s" % [iname, slot, rarity]


static func power_text(value: int) -> String:
	return "Power: %d" % value
