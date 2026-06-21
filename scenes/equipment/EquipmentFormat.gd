extends RefCounted

const PERCENT_STATS = [
	"ability_cooldown", "ability_damage", "xp_gain", "low_health_damage",
	"mark_damage", "support_damage", "rage_gain", "impact_damage", "knockback_resist",
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


static func item_display_line(item_or_template: Dictionary) -> String:
	var iname := str(item_or_template.get("name",
		item_or_template.get("display_name",
		item_or_template.get("template_id", "?"))))
	var slot := slot_display_name(str(item_or_template.get("slot_id", "")))
	var rarity := rarity_display_name(str(item_or_template.get("rarity", "common")))
	return "%s  —  %s  —  %s" % [iname, slot, rarity]
