class_name RunUpgradeManager3D
extends Node

var _player: Player3D
var _auto_attack: KnightMeleeAutoAttack3D
var _ability_manager: KnightAbilityManager3D
var _passive_manager: PassiveAbilityManager3D
var _levels: Dictionary = {}
var _history: Array[String] = []
var _last_random_option_ids: Array[String] = []

signal upgrade_applied(upgrade_id: String, new_level: int)

const UPGRADES: Dictionary = {
	"splash_melee_damage": {"title": "Fury Strike Power", "description": "+4 Fury Strike damage.", "rarity": "common", "max_level": 5, "category": "attack", "grid_index": 1, "evolution_id": "rage_wave_worldbreaker", "evolution_role": "attack", "owner": "auto_attack", "handler": "upgrade_fury_strike_damage"},
	"splash_melee_radius": {"title": "Wide Fury", "description": "+0.35 Fury Strike radius.", "rarity": "rare", "max_level": 4, "category": "attack", "grid_index": 2, "evolution_id": "rage_wave_earthsplitter", "evolution_role": "attack", "owner": "auto_attack", "handler": "upgrade_legacy_wide_fury"},
	"splash_melee_speed": {"title": "Fury Tempo", "description": "-0.05s Fury Strike interval, to 0.30s.", "rarity": "rare", "max_level": 4, "category": "attack", "grid_index": 3, "evolution_id": "crushing_leap_meteor_crash", "evolution_role": "attack", "owner": "auto_attack", "handler": "upgrade_fury_tempo"},
	"splash_melee_impact": {"title": "Knockback Force", "description": "+2.0 Fury Strike knockback force.", "rarity": "rare", "max_level": 3, "category": "attack", "grid_index": 4, "evolution_id": "shield_bash_rampage_impact", "evolution_role": "attack", "owner": "auto_attack", "handler": "upgrade_fury_strike_impact"},
	"splash_melee_frenzy": {"title": "Berserker Frenzy", "description": "+0.10 maximum Rage damage multiplier.", "rarity": "epic", "max_level": 3, "category": "attack", "grid_index": 5, "evolution_id": "rage_wave_crushing_storm", "evolution_role": "attack", "owner": "ability_manager", "handler": "upgrade_legacy_berserker_frenzy"},
	"splash_melee_shockwave": {"title": "Ground Shockwave", "description": "Successful Fury Strikes create a delayed 1.5x-radius shockwave for 0.5x base damage.", "rarity": "epic", "max_level": 1, "category": "attack", "grid_index": 6, "evolution_id": "mighty_clap_seismic_fan", "evolution_role": "attack", "owner": "auto_attack", "handler": "upgrade_legacy_ground_shockwave"},
	"splash_melee_lifesteal": {"title": "Blood Frenzy", "description": "+2 HP per enemy hit.", "rarity": "rare", "max_level": 3, "category": "attack", "grid_index": 7, "evolution_id": "rage_leap_blood_crater", "evolution_role": "attack", "owner": "auto_attack", "handler": "upgrade_blood_frenzy"},
	"splash_melee_combo": {"title": "Fury Combo", "description": "+0.06 damage bonus per combo stack.", "rarity": "rare", "max_level": 3, "category": "attack", "grid_index": 8, "evolution_id": "mighty_clap_rampage_impact", "evolution_role": "attack", "owner": "auto_attack", "handler": "upgrade_fury_combo"},
	"splash_melee_execute": {"title": "Finishing Blow", "description": "+0.20 low-health threshold; deal 1.45x melee damage at or below it.", "rarity": "epic", "max_level": 3, "category": "attack", "grid_index": 9, "evolution_id": "rage_leap_final_impact", "evolution_role": "attack", "owner": "auto_attack", "handler": "upgrade_finishing_blow"},
	"orbit_shields": {"title": "Orbit Shields", "description": "Orbiting charges completely block incoming hits.", "rarity": "epic", "max_level": 3, "category": "passive", "grid_index": 1, "evolution_id": "rage_wave_worldbreaker", "evolution_role": "passive", "owner": "passive_manager", "handler": "add_or_upgrade_passive"},
	"static_field": {"title": "Static Field", "description": "Periodic electric pulse around the Knight.", "rarity": "rare", "max_level": 3, "category": "passive", "grid_index": 2, "evolution_id": "rage_wave_earthsplitter", "evolution_role": "passive", "owner": "passive_manager", "handler": "add_or_upgrade_passive"},
	"time_dilator": {"title": "Time Dilator", "description": "Periodically slows enemies around the Knight.", "rarity": "rare", "max_level": 3, "category": "passive", "grid_index": 3, "evolution_id": "rage_wave_crushing_storm", "evolution_role": "passive", "owner": "passive_manager", "handler": "add_or_upgrade_passive"},
	"storm_relay": {"title": "Storm Relay", "description": "Periodically strike the nearest enemy with lightning.", "rarity": "rare", "max_level": 3, "category": "passive", "grid_index": 4, "evolution_id": "shield_bash_rampage_impact", "evolution_role": "passive", "owner": "passive_manager", "handler": "add_or_upgrade_passive"},
	"chain_lightning": {"title": "Chain Lightning", "description": "Lightning jumps through nearby enemies without repeating targets.", "rarity": "epic", "max_level": 3, "category": "passive", "grid_index": 5, "evolution_id": "mighty_clap_seismic_fan", "evolution_role": "passive", "owner": "passive_manager", "handler": "add_or_upgrade_passive"},
	"battle_focus": {"title": "Battle Focus", "description": "Periodic strike and temporary attack-speed boost.", "rarity": "rare", "max_level": 3, "category": "passive", "grid_index": 6, "evolution_id": "mighty_clap_rampage_impact", "evolution_role": "passive", "owner": "passive_manager", "handler": "add_or_upgrade_passive"},
	"magnet_core": {"title": "Magnet Core", "description": "Extends nearby experience pickup attraction.", "rarity": "common", "max_level": 3, "category": "passive", "grid_index": 7, "evolution_id": "crushing_leap_meteor_crash", "evolution_role": "passive", "owner": "passive_manager", "handler": "add_or_upgrade_passive"},
	"recovery_field": {"title": "Recovery Field", "description": "Periodically restore health.", "rarity": "common", "max_level": 3, "category": "passive", "grid_index": 8, "evolution_id": "rage_leap_blood_crater", "evolution_role": "passive", "owner": "passive_manager", "handler": "add_or_upgrade_passive"},
	"guardian_drone": {"title": "Guardian Drone", "description": "Orbiting drone periodically strikes the nearest enemy.", "rarity": "rare", "max_level": 3, "category": "passive", "grid_index": 9, "evolution_id": "rage_leap_final_impact", "evolution_role": "passive", "owner": "passive_manager", "handler": "add_or_upgrade_passive"},
	"rage_wave_power": {"title": "Wave Surge", "description": "+8 Rage Wave damage.", "rarity": "rare", "max_level": 4, "category": "active", "grid_index": 1, "evolution_id": "rage_wave_worldbreaker", "evolution_role": "active", "owner": "ability_manager", "handler": "upgrade_rage_wave_power"},
	"rage_wave_radius": {"title": "Wave Reach", "description": "+0.75 Rage Wave radius and +0.04 Rage radius scaling.", "rarity": "rare", "max_level": 3, "category": "active", "grid_index": 2, "evolution_id": "rage_wave_earthsplitter", "evolution_role": "active", "owner": "ability_manager", "handler": "upgrade_legacy_wave_reach"},
	"rage_wave_deep_slow": {"title": "Crushing Current", "description": "+0.8s slow, -0.06 speed, -0.5s cooldown, +0.04 Rage radius scaling.", "rarity": "epic", "max_level": 3, "category": "active", "grid_index": 3, "evolution_id": "rage_wave_crushing_storm", "evolution_role": "active", "owner": "ability_manager", "handler": "upgrade_legacy_crushing_current"},
	"mighty_clap_power": {"title": "Clap Force", "description": "+9 Shield Bash damage.", "rarity": "common", "max_level": 4, "category": "active", "grid_index": 4, "evolution_id": "shield_bash_rampage_impact", "evolution_role": "active", "owner": "ability_manager", "handler": "upgrade_mighty_clap_power"},
	"mighty_clap_range": {"title": "Wide Clap", "description": "+0.625 Shield Bash range and +6 degrees cone angle.", "rarity": "rare", "max_level": 3, "category": "active", "grid_index": 5, "evolution_id": "mighty_clap_seismic_fan", "evolution_role": "active", "owner": "ability_manager", "handler": "upgrade_legacy_wide_clap"},
	"mighty_clap_shockwave": {"title": "Impact Wave", "description": "+1.5 Shield Bash knockback and -0.7s cooldown.", "rarity": "epic", "max_level": 3, "category": "active", "grid_index": 6, "evolution_id": "mighty_clap_rampage_impact", "evolution_role": "active", "owner": "ability_manager", "handler": "upgrade_impact_wave"},
	"rage_leap_power": {"title": "Leap Impact", "description": "+10 Crushing Leap damage.", "rarity": "epic", "max_level": 4, "category": "active", "grid_index": 7, "evolution_id": "crushing_leap_meteor_crash", "evolution_role": "active", "owner": "ability_manager", "handler": "upgrade_rage_leap_power"},
	"rage_leap_radius": {"title": "Wide Landing", "description": "+0.55 Crushing Leap radius.", "rarity": "rare", "max_level": 3, "category": "active", "grid_index": 8, "evolution_id": "rage_leap_blood_crater", "evolution_role": "active", "owner": "ability_manager", "handler": "upgrade_legacy_leap_radius"},
	"rage_leap_cooldown": {"title": "Leap Ready", "description": "-1.2s Crushing Leap cooldown and +0.5 Leap distance.", "rarity": "epic", "max_level": 3, "category": "active", "grid_index": 9, "evolution_id": "rage_leap_final_impact", "evolution_role": "active", "owner": "ability_manager", "handler": "upgrade_legacy_leap_ready"},
}
const VALID_OWNER_HANDLERS := {
	"auto_attack": ["upgrade_fury_strike_damage", "upgrade_legacy_wide_fury", "upgrade_fury_tempo", "upgrade_fury_strike_impact", "upgrade_legacy_ground_shockwave", "upgrade_blood_frenzy", "upgrade_fury_combo", "upgrade_finishing_blow"],
	"ability_manager": ["upgrade_legacy_berserker_frenzy", "upgrade_rage_wave_power", "upgrade_legacy_wave_reach", "upgrade_legacy_crushing_current", "upgrade_mighty_clap_power", "upgrade_legacy_wide_clap", "upgrade_impact_wave", "upgrade_rage_leap_power", "upgrade_legacy_leap_radius", "upgrade_legacy_leap_ready"],
	"passive_manager": ["add_or_upgrade_passive"],
}
const MAX_LEVEL := 5
const LEVEL_TUNING := {
	"splash_melee_damage": {"damage": [4, 8, 12, 16, 20]}, "splash_melee_radius": {"radius": [0.28, 0.56, 0.84, 1.12, 1.40]}, "splash_melee_speed": {"interval": [0.04, 0.08, 0.12, 0.16, 0.20]}, "splash_melee_impact": {"force": [1.2, 2.4, 3.6, 4.8, 6.0]}, "splash_melee_frenzy": {"multiplier": [0.06, 0.12, 0.18, 0.24, 0.30]}, "splash_melee_shockwave": {"damage_multiplier": [0.30, 0.35, 0.40, 0.45, 0.50], "radius_multiplier": [1.25, 1.32, 1.38, 1.44, 1.50], "delay": [0.26, 0.24, 0.22, 0.20, 0.18]}, "splash_melee_lifesteal": {"healing": [1, 2, 3, 4, 6]}, "splash_melee_combo": {"bonus": [0.04, 0.08, 0.11, 0.14, 0.18]}, "splash_melee_execute": {"threshold": [0.12, 0.24, 0.36, 0.48, 0.60]},
	"rage_wave_power": {"damage": [6, 12, 18, 25, 32]}, "rage_wave_radius": {"radius": [0.45, 0.90, 1.35, 1.80, 2.25], "rage_radius": [0.024, 0.048, 0.072, 0.096, 0.120]}, "rage_wave_deep_slow": {"duration": [0.48, 0.96, 1.44, 1.92, 2.40], "slow_reduction": [0.036, 0.072, 0.108, 0.144, 0.180], "cooldown": [0.30, 0.60, 0.90, 1.20, 1.50], "rage_radius": [0.024, 0.048, 0.072, 0.096, 0.120]}, "mighty_clap_power": {"damage": [7, 14, 21, 28, 36]}, "mighty_clap_range": {"range": [0.375, 0.750, 1.125, 1.500, 1.875], "angle": [3.6, 7.2, 10.8, 14.4, 18.0]}, "mighty_clap_shockwave": {"knockback": [0.9, 1.8, 2.7, 3.6, 4.5], "cooldown": [0.42, 0.84, 1.26, 1.68, 2.10]}, "rage_leap_power": {"damage": [8, 16, 24, 32, 40]}, "rage_leap_radius": {"radius": [0.33, 0.66, 0.99, 1.32, 1.65]}, "rage_leap_cooldown": {"cooldown": [0.72, 1.44, 2.16, 2.88, 3.60], "distance": [0.30, 0.60, 0.90, 1.20, 1.50]},
}


func setup(player: Player3D, auto_attack: KnightMeleeAutoAttack3D, ability_manager: KnightAbilityManager3D = null, passive_manager: PassiveAbilityManager3D = null) -> void:
	_player = player
	_auto_attack = auto_attack
	_ability_manager = ability_manager
	_passive_manager = passive_manager
	reset_run_state()


func reset_run_state() -> void:
	_levels.clear()
	_history.clear()


func get_upgrade_options(count: int) -> Array[Dictionary]:
	var eligible_ids: Array[String] = []
	for upgrade_id: String in UPGRADES:
		if is_upgrade_eligible(upgrade_id):
			eligible_ids.append(upgrade_id)
	eligible_ids.shuffle()
	var options: Array[Dictionary] = []
	for index in range(mini(count, eligible_ids.size())):
		options.append(_make_option(eligible_ids[index]))
	_last_random_option_ids = []
	for option: Dictionary in options:
		_last_random_option_ids.append(str(option["id"]))
	return options


func get_progression_debug_state() -> Dictionary:
	return {"last_random_option_ids": _last_random_option_ids.duplicate(), "selection_mode": "uniform_eligible_random"}


func apply_upgrade(upgrade_id: String) -> bool:
	if not UPGRADES.has(upgrade_id) or not _has_dependencies(upgrade_id) or is_upgrade_maxed(upgrade_id):
		return false
	var next_level := get_upgrade_level(upgrade_id) + 1
	if not _apply_upgrade_handler(upgrade_id, next_level):
		return false
	_levels[upgrade_id] = next_level
	_history.append(upgrade_id)
	upgrade_applied.emit(upgrade_id, next_level)
	return true


func make_upgrade_options(upgrade_ids: Array[String]) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	var seen := {}
	for upgrade_id: String in upgrade_ids:
		if seen.has(upgrade_id) or not is_upgrade_eligible(upgrade_id):
			continue
		seen[upgrade_id] = true
		options.append(_make_option(upgrade_id))
	return options


func is_upgrade_eligible(upgrade_id: String) -> bool:
	if not UPGRADES.has(upgrade_id) or is_upgrade_maxed(upgrade_id) or not _has_dependencies(upgrade_id):
		return false
	var owner := _get_owner(upgrade_id)
	return owner != null and owner.has_method(str(UPGRADES[upgrade_id]["handler"]))


func has_upgrade(upgrade_id: String) -> bool:
	return UPGRADES.has(upgrade_id)


func get_upgrade_level(upgrade_id: String) -> int:
	return int(_levels.get(upgrade_id, 0))


func get_upgrade_max_level(upgrade_id: String) -> int:
	return MAX_LEVEL if UPGRADES.has(upgrade_id) else 0


func is_upgrade_maxed(upgrade_id: String) -> bool:
	var maximum := get_upgrade_max_level(upgrade_id)
	return maximum > 0 and get_upgrade_level(upgrade_id) >= maximum


func get_upgrade_definition(upgrade_id: String) -> Dictionary:
	if not UPGRADES.has(upgrade_id):
		return {}
	var definition: Dictionary = UPGRADES[upgrade_id].duplicate()
	definition["id"] = upgrade_id
	definition["level"] = get_upgrade_level(upgrade_id)
	definition["next_level"] = mini(definition["level"] + 1, MAX_LEVEL)
	definition["max_level"] = MAX_LEVEL
	definition["required_level"] = MAX_LEVEL
	definition["current_effect_summary"] = _effect_summary(upgrade_id, definition["level"])
	definition["next_effect_summary"] = _effect_summary(upgrade_id, definition["next_level"])
	return definition


func get_progression_matrix_validation_errors(evolution_definitions: Array[Dictionary]) -> Array[String]:
	var errors: Array[String] = []
	var category_counts := {"attack": 0, "passive": 0, "active": 0}
	var grid_indexes := {"attack": {}, "passive": {}, "active": {}}
	var use_counts := {}
	for upgrade_id: String in UPGRADES:
		var definition: Dictionary = UPGRADES[upgrade_id]
		var category := str(definition.get("category", ""))
		if not category_counts.has(category):
			errors.append("%s has invalid category '%s'." % [upgrade_id, category])
			continue
		category_counts[category] = int(category_counts[category]) + 1
		var grid_index := int(definition.get("grid_index", 0))
		if grid_index < 1 or grid_index > 9 or grid_indexes[category].has(grid_index):
			errors.append("%s has invalid or duplicate %s grid index." % [upgrade_id, category])
		grid_indexes[category][grid_index] = true
		if str(definition.get("evolution_role", "")) != category or str(definition.get("evolution_id", "")).is_empty() or get_upgrade_max_level(upgrade_id) != MAX_LEVEL:
			errors.append("%s has invalid canonical metadata." % upgrade_id)
		if not _has_declared_handler(definition):
			errors.append("%s has no valid owner handler." % upgrade_id)
		use_counts[upgrade_id] = 0
	if UPGRADES.size() != 27:
		errors.append("Upgrade count is %d, expected 27." % UPGRADES.size())
	for category: String in category_counts:
		if int(category_counts[category]) != 9:
			errors.append("%s count is %d, expected 9." % [category, category_counts[category]])
	if evolution_definitions.size() != 9:
		errors.append("Evolution count is %d, expected 9." % evolution_definitions.size())
	for evolution: Dictionary in evolution_definitions:
		var evolution_id := str(evolution.get("id", ""))
		var prerequisites: Array = evolution.get("prerequisites", [])
		var prerequisite_categories := {"attack": 0, "passive": 0, "active": 0}
		if prerequisites.size() != 3:
			errors.append("%s has %d prerequisites, expected 3." % [evolution_id, prerequisites.size()])
		for upgrade_id: String in prerequisites:
			if not UPGRADES.has(upgrade_id):
				errors.append("%s references missing upgrade %s." % [evolution_id, upgrade_id])
				continue
			use_counts[upgrade_id] = int(use_counts[upgrade_id]) + 1
			var category := str(UPGRADES[upgrade_id]["category"])
			prerequisite_categories[category] = int(prerequisite_categories[category]) + 1
			if str(UPGRADES[upgrade_id]["evolution_id"]) != evolution_id:
				errors.append("%s metadata points to a different evolution." % upgrade_id)
		for category: String in prerequisite_categories:
			if int(prerequisite_categories[category]) != 1:
				errors.append("%s requires %d %s upgrades, expected 1." % [evolution_id, prerequisite_categories[category], category])
	for upgrade_id: String in use_counts:
		if int(use_counts[upgrade_id]) != 1:
			errors.append("%s is used %d times, expected once." % [upgrade_id, use_counts[upgrade_id]])
	for upgrade_id: String in LEVEL_TUNING:
		for values: Array in LEVEL_TUNING[upgrade_id].values():
			if values.size() != MAX_LEVEL:
				errors.append("%s has invalid five-level tuning." % upgrade_id)
	if _passive_manager != null and _passive_manager.has_method("get_passive_max_level"):
		for upgrade_id: String in UPGRADES:
			if str(UPGRADES[upgrade_id]["owner"]) == "passive_manager" and _passive_manager.get_passive_max_level(upgrade_id) != MAX_LEVEL:
				errors.append("%s passive tuning is not five levels." % upgrade_id)
	for upgrade_id: String in UPGRADES:
		var owner := _get_owner(upgrade_id)
		if owner != null and not owner.has_method(str(UPGRADES[upgrade_id]["handler"])):
			errors.append("%s owner does not expose %s." % [upgrade_id, UPGRADES[upgrade_id]["handler"]])
	return errors


func get_run_summary() -> Dictionary:
	var category_counts := {"attack": 0, "passive": 0, "active": 0}
	for upgrade_id: String in _history:
		var category := str(UPGRADES[upgrade_id]["category"])
		category_counts[category] = int(category_counts[category]) + 1
	return {"selected_upgrade_count": _history.size(), "selected_upgrade_history": _history.duplicate(), "upgrade_levels": _levels.duplicate(), "dominant_archetype": "melee", "selected_attack_line_count": category_counts["attack"], "selected_passive_line_count": category_counts["passive"], "selected_active_line_count": category_counts["active"]}


func _make_option(upgrade_id: String) -> Dictionary:
	var definition: Dictionary = UPGRADES[upgrade_id]
	var current_level := get_upgrade_level(upgrade_id)
	var next_level := current_level + 1
	return {"id": upgrade_id, "title": definition["title"], "description": _effect_summary(upgrade_id, next_level) if not _effect_summary(upgrade_id, next_level).is_empty() else definition["description"], "rarity": definition["rarity"], "level": current_level, "next_level": next_level, "max_level": MAX_LEVEL, "required_level": MAX_LEVEL, "current_effect_summary": _effect_summary(upgrade_id, current_level), "next_effect_summary": _effect_summary(upgrade_id, next_level), "evolution_id": definition["evolution_id"], "slot_category": definition["category"]}


func _has_dependencies(upgrade_id: String) -> bool:
	if _player == null or not UPGRADES.has(upgrade_id):
		return false
	match str(UPGRADES[upgrade_id]["owner"]):
		"auto_attack": return _auto_attack != null
		"ability_manager": return _ability_manager != null
		"passive_manager": return _passive_manager != null
		_: return false


func _apply_upgrade_handler(upgrade_id: String, next_level: int) -> bool:
	match upgrade_id:
		"splash_melee_damage": return _auto_attack.upgrade_fury_strike_damage(roundi(_delta(upgrade_id, "damage", next_level)))
		"splash_melee_radius": return _auto_attack.upgrade_legacy_wide_fury(_delta(upgrade_id, "radius", next_level))
		"splash_melee_speed": return _auto_attack.upgrade_fury_tempo(_delta(upgrade_id, "interval", next_level), 0.30)
		"splash_melee_impact": return _auto_attack.upgrade_fury_strike_impact(_delta(upgrade_id, "force", next_level))
		"splash_melee_frenzy": return _ability_manager.upgrade_legacy_berserker_frenzy(_delta(upgrade_id, "multiplier", next_level))
		"splash_melee_shockwave": return _auto_attack.upgrade_ground_shockwave(_tuning(upgrade_id, "damage_multiplier", next_level), _tuning(upgrade_id, "radius_multiplier", next_level), _tuning(upgrade_id, "delay", next_level))
		"splash_melee_lifesteal": return _auto_attack.upgrade_blood_frenzy(_delta(upgrade_id, "healing", next_level))
		"splash_melee_combo": return _auto_attack.upgrade_fury_combo(_delta(upgrade_id, "bonus", next_level))
		"splash_melee_execute": return _auto_attack.upgrade_finishing_blow(_delta(upgrade_id, "threshold", next_level))
		"rage_wave_power": return _ability_manager.upgrade_rage_wave_power(roundi(_delta(upgrade_id, "damage", next_level)))
		"rage_wave_radius": return _ability_manager.upgrade_legacy_wave_reach(_delta(upgrade_id, "radius", next_level), _delta(upgrade_id, "rage_radius", next_level))
		"rage_wave_deep_slow": return _ability_manager.upgrade_crushing_current(_delta(upgrade_id, "duration", next_level), _delta(upgrade_id, "slow_reduction", next_level), _delta(upgrade_id, "cooldown", next_level), _delta(upgrade_id, "rage_radius", next_level))
		"mighty_clap_power": return _ability_manager.upgrade_mighty_clap_power(roundi(_delta(upgrade_id, "damage", next_level)))
		"mighty_clap_range": return _ability_manager.upgrade_legacy_wide_clap(_delta(upgrade_id, "range", next_level), _delta(upgrade_id, "angle", next_level))
		"mighty_clap_shockwave": return _ability_manager.upgrade_impact_wave(_delta(upgrade_id, "knockback", next_level), _delta(upgrade_id, "cooldown", next_level))
		"rage_leap_power": return _ability_manager.upgrade_rage_leap_power(roundi(_delta(upgrade_id, "damage", next_level)))
		"rage_leap_radius": return _ability_manager.upgrade_legacy_leap_radius(_delta(upgrade_id, "radius", next_level))
		"rage_leap_cooldown": return _ability_manager.upgrade_legacy_leap_ready(_delta(upgrade_id, "cooldown", next_level), _delta(upgrade_id, "distance", next_level))
		_:
			return _passive_manager.add_or_upgrade_passive(upgrade_id) if str(UPGRADES[upgrade_id]["owner"]) == "passive_manager" else false


func _tuning(upgrade_id: String, key: String, level: int) -> float:
	return float(LEVEL_TUNING[upgrade_id][key][level - 1])


func _delta(upgrade_id: String, key: String, next_level: int) -> float:
	return _tuning(upgrade_id, key, next_level) - (_tuning(upgrade_id, key, next_level - 1) if next_level > 1 else 0.0)


func _effect_summary(upgrade_id: String, level: int) -> String:
	if level <= 0 or not LEVEL_TUNING.has(upgrade_id):
		return ""
	var values: Dictionary = LEVEL_TUNING[upgrade_id]
	var parts: Array[String] = []
	for key: String in values:
		parts.append("%s %s" % [key.replace("_", " "), _tuning(upgrade_id, key, level)])
	return ", ".join(parts)


func _get_owner(upgrade_id: String) -> Node:
	match str(UPGRADES[upgrade_id]["owner"]):
		"auto_attack": return _auto_attack
		"ability_manager": return _ability_manager
		"passive_manager": return _passive_manager
		_: return null


func _has_declared_handler(definition: Dictionary) -> bool:
	var owner := str(definition.get("owner", ""))
	return VALID_OWNER_HANDLERS.has(owner) and str(definition.get("handler", "")) in VALID_OWNER_HANDLERS[owner]

