class_name RunUpgradeManager3D
extends Node

var _player: Player3D
var _auto_attack: KnightMeleeAutoAttack3D
var _ability_manager: KnightAbilityManager3D
var _passive_manager: PassiveAbilityManager3D
var _levels: Dictionary = {}
var _history: Array[String] = []

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
	var available_by_category := {"attack": [], "active": [], "passive": []}
	for upgrade_id: String in UPGRADES:
		if int(_levels.get(upgrade_id, 0)) < get_upgrade_max_level(upgrade_id):
			available_by_category[str(UPGRADES[upgrade_id]["category"])].append(upgrade_id)
	for category: String in available_by_category:
		available_by_category[category] = _prioritize_started_lines(available_by_category[category])
	var options: Array[Dictionary] = []
	if count >= 3:
		for category in ["attack", "active", "passive"]:
			if not available_by_category[category].is_empty():
				options.append(_make_option(available_by_category[category].pop_back()))
	var remaining: Array[String] = []
	for category: String in available_by_category:
		remaining.append_array(available_by_category[category])
	remaining.shuffle()
	while options.size() < count and not remaining.is_empty():
		options.append(_make_option(remaining.pop_back()))
	return options


func apply_upgrade(upgrade_id: String) -> void:
	if not UPGRADES.has(upgrade_id) or not _has_dependencies(upgrade_id) or is_upgrade_maxed(upgrade_id):
		return
	if not _apply_upgrade_handler(upgrade_id):
		return
	_levels[upgrade_id] = get_upgrade_level(upgrade_id) + 1
	_history.append(upgrade_id)


func has_upgrade(upgrade_id: String) -> bool:
	return UPGRADES.has(upgrade_id)


func get_upgrade_level(upgrade_id: String) -> int:
	return int(_levels.get(upgrade_id, 0))


func get_upgrade_max_level(upgrade_id: String) -> int:
	return int(UPGRADES.get(upgrade_id, {}).get("max_level", 0))


func is_upgrade_maxed(upgrade_id: String) -> bool:
	var maximum := get_upgrade_max_level(upgrade_id)
	return maximum > 0 and get_upgrade_level(upgrade_id) >= maximum


func get_upgrade_definition(upgrade_id: String) -> Dictionary:
	if not UPGRADES.has(upgrade_id):
		return {}
	var definition: Dictionary = UPGRADES[upgrade_id].duplicate()
	definition["id"] = upgrade_id
	definition["level"] = get_upgrade_level(upgrade_id)
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
		if str(definition.get("evolution_role", "")) != category or str(definition.get("evolution_id", "")).is_empty() or int(definition.get("max_level", 0)) <= 0:
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
	return errors


func get_run_summary() -> Dictionary:
	var category_counts := {"attack": 0, "passive": 0, "active": 0}
	for upgrade_id: String in _history:
		var category := str(UPGRADES[upgrade_id]["category"])
		category_counts[category] = int(category_counts[category]) + 1
	return {"selected_upgrade_count": _history.size(), "selected_upgrade_history": _history.duplicate(), "upgrade_levels": _levels.duplicate(), "dominant_archetype": "melee", "selected_attack_line_count": category_counts["attack"], "selected_passive_line_count": category_counts["passive"], "selected_active_line_count": category_counts["active"]}


func _make_option(upgrade_id: String) -> Dictionary:
	var definition: Dictionary = UPGRADES[upgrade_id]
	return {"id": upgrade_id, "title": definition["title"], "description": definition["description"], "rarity": definition["rarity"], "level": get_upgrade_level(upgrade_id), "max_level": get_upgrade_max_level(upgrade_id), "slot_category": definition["category"]}


func _has_dependencies(upgrade_id: String) -> bool:
	if _player == null or not UPGRADES.has(upgrade_id):
		return false
	match str(UPGRADES[upgrade_id]["owner"]):
		"auto_attack": return _auto_attack != null
		"ability_manager": return _ability_manager != null
		"passive_manager": return _passive_manager != null
		_: return false


func _apply_upgrade_handler(upgrade_id: String) -> bool:
	match upgrade_id:
		"splash_melee_damage": return _auto_attack.upgrade_fury_strike_damage(4)
		"splash_melee_radius": return _auto_attack.upgrade_legacy_wide_fury(0.35)
		"splash_melee_speed": return _auto_attack.upgrade_fury_tempo(0.05, 0.30)
		"splash_melee_impact": return _auto_attack.upgrade_fury_strike_impact(2.0)
		"splash_melee_frenzy": return _ability_manager.upgrade_legacy_berserker_frenzy(0.10)
		"splash_melee_shockwave": return _auto_attack.upgrade_legacy_ground_shockwave()
		"splash_melee_lifesteal": return _auto_attack.upgrade_blood_frenzy(2.0)
		"splash_melee_combo": return _auto_attack.upgrade_fury_combo(0.06)
		"splash_melee_execute": return _auto_attack.upgrade_finishing_blow(0.20)
		"rage_wave_power": return _ability_manager.upgrade_rage_wave_power(8)
		"rage_wave_radius": return _ability_manager.upgrade_legacy_wave_reach(0.75, 0.04)
		"rage_wave_deep_slow": return _ability_manager.upgrade_legacy_crushing_current()
		"mighty_clap_power": return _ability_manager.upgrade_mighty_clap_power(9)
		"mighty_clap_range": return _ability_manager.upgrade_legacy_wide_clap(0.625, 6.0)
		"mighty_clap_shockwave": return _ability_manager.upgrade_impact_wave(1.5, 0.7)
		"rage_leap_power": return _ability_manager.upgrade_rage_leap_power(10)
		"rage_leap_radius": return _ability_manager.upgrade_legacy_leap_radius(0.55)
		"rage_leap_cooldown": return _ability_manager.upgrade_legacy_leap_ready(1.2, 0.5)
		_:
			return _passive_manager.add_or_upgrade_passive(upgrade_id) if str(UPGRADES[upgrade_id]["owner"]) == "passive_manager" else false


func _has_declared_handler(definition: Dictionary) -> bool:
	var owner := str(definition.get("owner", ""))
	return VALID_OWNER_HANDLERS.has(owner) and str(definition.get("handler", "")) in VALID_OWNER_HANDLERS[owner]


func _prioritize_started_lines(upgrade_ids: Array) -> Array:
	var started: Array = []
	for upgrade_id: String in upgrade_ids:
		if get_upgrade_level(upgrade_id) > 0 and not is_upgrade_maxed(upgrade_id):
			started.append(upgrade_id)
	if not started.is_empty():
		started.shuffle()
		return started
	upgrade_ids.shuffle()
	return upgrade_ids
