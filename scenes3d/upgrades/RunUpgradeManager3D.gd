class_name RunUpgradeManager3D
extends Node

var _player: Player3D
var _auto_attack: KnightMeleeAutoAttack3D
var _ability_manager: KnightAbilityManager3D
var _levels: Dictionary = {}
var _history: Array[String] = []

const UPGRADES := {
	"sword_damage": {"title": "Sword Damage", "description": "+5 melee damage.", "rarity": "common", "max_level": 8},
	"sword_speed": {"title": "Sword Speed", "description": "15% faster sword attacks.", "rarity": "common", "max_level": 6},
	"sword_radius": {"title": "Sword Reach", "description": "+0.25 melee radius.", "rarity": "rare", "max_level": 5},
	"sword_arc": {"title": "Sword Arc", "description": "+12 degrees attack arc.", "rarity": "rare", "max_level": 5},
	"sword_knockback": {"title": "Sword Knockback", "description": "+1.5 knockback force.", "rarity": "rare", "max_level": 5},
	"move_speed": {"title": "Swift Step", "description": "+0.55 movement speed.", "rarity": "common", "max_level": 5},
	"max_health": {"title": "Knight's Resolve", "description": "+20 maximum health and heal 20.", "rarity": "epic", "max_level": 5},
	"wave_damage": {"title": "Wave Force", "description": "+8 Rage Wave damage.", "rarity": "rare", "max_level": 5, "category": "active"},
	"bash_damage": {"title": "Bash Force", "description": "+10 Shield Bash damage.", "rarity": "rare", "max_level": 5, "category": "active"},
	"leap_damage": {"title": "Leap Force", "description": "+12 Crushing Leap damage.", "rarity": "epic", "max_level": 5, "category": "active"},
	"rage_max": {"title": "Burning Rage", "description": "+20 Rage maximum.", "rarity": "rare", "max_level": 4, "category": "passive"},
	"wave_radius": {"title": "Wide Wave", "description": "+0.5 Rage Wave radius.", "rarity": "rare", "max_level": 5, "category": "active"},
	"wave_cooldown": {"title": "Wave Rhythm", "description": "-0.45 Rage Wave cooldown.", "rarity": "rare", "max_level": 5, "category": "active"},
	"bash_range": {"title": "Long Bash", "description": "+0.4 Shield Bash range.", "rarity": "rare", "max_level": 5, "category": "active"},
	"bash_knockback": {"title": "Heavy Bash", "description": "+1.5 Shield Bash knockback.", "rarity": "rare", "max_level": 5, "category": "active"},
	"leap_radius": {"title": "Wide Landing", "description": "+0.4 Crushing Leap radius.", "rarity": "rare", "max_level": 5, "category": "active"},
	"leap_cooldown": {"title": "Leap Rhythm", "description": "-0.65 Crushing Leap cooldown.", "rarity": "epic", "max_level": 5, "category": "active"},
	"rage_decay": {"title": "Smoldering Rage", "description": "-0.5 Rage decay per second.", "rarity": "rare", "max_level": 5, "category": "passive"},
	"rage_multiplier": {"title": "Furious Edge", "description": "+0.05 maximum Rage damage multiplier.", "rarity": "epic", "max_level": 5, "category": "passive"},
}


func setup(player: Player3D, auto_attack: KnightMeleeAutoAttack3D, ability_manager: KnightAbilityManager3D = null) -> void:
	_player = player
	_auto_attack = auto_attack
	_ability_manager = ability_manager


func get_upgrade_options(count: int) -> Array[Dictionary]:
	var available_by_category := {"attack": [], "active": [], "passive": []}
	for upgrade_id: String in UPGRADES:
		if int(_levels.get(upgrade_id, 0)) < int(UPGRADES[upgrade_id]["max_level"]):
			available_by_category[_category_for(upgrade_id)].append(upgrade_id)
	for category: String in available_by_category:
		available_by_category[category].shuffle()
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


func _make_option(upgrade_id: String) -> Dictionary:
	var definition: Dictionary = UPGRADES[upgrade_id]
	return {"id": upgrade_id, "title": definition["title"], "description": definition["description"], "rarity": definition["rarity"], "level": int(_levels.get(upgrade_id, 0)), "max_level": int(definition["max_level"]), "slot_category": _category_for(upgrade_id)}


func _category_for(upgrade_id: String) -> String:
	return str(UPGRADES[upgrade_id].get("category", "attack" if upgrade_id.begins_with("sword") else "passive"))


func apply_upgrade(upgrade_id: String) -> void:
	if not UPGRADES.has(upgrade_id) or not _has_dependencies(upgrade_id):
		return
	var level := int(_levels.get(upgrade_id, 0))
	if level >= int(UPGRADES[upgrade_id]["max_level"]):
		return
	match upgrade_id:
		"sword_damage": _auto_attack.attack_damage += 5
		"sword_speed": _auto_attack.attack_interval = maxf(0.18, _auto_attack.attack_interval * 0.85)
		"sword_radius": _auto_attack.attack_radius += 0.25
		"sword_arc": _auto_attack.attack_arc = minf(220.0, _auto_attack.attack_arc + 12.0)
		"sword_knockback": _auto_attack.knockback_force += 1.5
		"move_speed": _player.movement_speed += 0.55
		"max_health":
			_player.max_health += 20
			_player.heal(20)
		"wave_damage": _ability_manager.wave_damage += 8
		"bash_damage": _ability_manager.bash_damage += 10
		"leap_damage": _ability_manager.leap_damage += 12
		"rage_max": _ability_manager.maximum_rage += 20.0
		"wave_radius": _ability_manager.wave_radius += 0.5
		"wave_cooldown": _ability_manager.wave_cooldown = maxf(2.0, _ability_manager.wave_cooldown - 0.45)
		"bash_range": _ability_manager.bash_range += 0.4
		"bash_knockback": _ability_manager.bash_knockback_force += 1.5
		"leap_radius": _ability_manager.leap_radius += 0.4
		"leap_cooldown": _ability_manager.leap_cooldown = maxf(3.0, _ability_manager.leap_cooldown - 0.65)
		"rage_decay": _ability_manager.rage_decay_per_second = maxf(0.0, _ability_manager.rage_decay_per_second - 0.5)
		"rage_multiplier": _ability_manager.maximum_damage_multiplier = minf(1.7, _ability_manager.maximum_damage_multiplier + 0.05)
	if upgrade_id in ["rage_max", "rage_decay", "rage_multiplier"] and _ability_manager != null:
		_ability_manager.refresh_rage_state()
	_levels[upgrade_id] = level + 1
	_history.append(upgrade_id)


func _has_dependencies(upgrade_id: String) -> bool:
	if _player == null:
		return false
	if upgrade_id.begins_with("sword"):
		return _auto_attack != null
	return _ability_manager != null if upgrade_id in ["wave_damage", "bash_damage", "leap_damage", "rage_max", "wave_radius", "wave_cooldown", "bash_range", "bash_knockback", "leap_radius", "leap_cooldown", "rage_decay", "rage_multiplier"] else true


func get_run_summary() -> Dictionary:
	var attack_count := 0
	var passive_count := 0
	var active_count := 0
	for upgrade_id: String in _history:
		var category := str(UPGRADES[upgrade_id].get("category", "attack" if upgrade_id.begins_with("sword") else "passive"))
		if category == "attack":
			attack_count += 1
		elif category == "active":
			active_count += 1
		else:
			passive_count += 1
	return {"selected_upgrade_count": _history.size(), "selected_upgrade_history": _history.duplicate(), "upgrade_levels": _levels.duplicate(), "dominant_archetype": "melee", "selected_attack_line_count": attack_count, "selected_passive_line_count": passive_count, "selected_active_line_count": active_count}
