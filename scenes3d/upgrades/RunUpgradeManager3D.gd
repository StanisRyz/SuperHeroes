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
}


func setup(player: Player3D, auto_attack: KnightMeleeAutoAttack3D, ability_manager: KnightAbilityManager3D = null) -> void:
	_player = player
	_auto_attack = auto_attack
	_ability_manager = ability_manager


func get_upgrade_options(count: int) -> Array[Dictionary]:
	var available: Array[String] = []
	for upgrade_id: String in UPGRADES:
		if int(_levels.get(upgrade_id, 0)) < int(UPGRADES[upgrade_id]["max_level"]):
			available.append(upgrade_id)
	available.shuffle()
	var options: Array[Dictionary] = []
	for upgrade_id: String in available.slice(0, mini(count, available.size())):
		var definition: Dictionary = UPGRADES[upgrade_id]
		options.append({"id": upgrade_id, "title": definition["title"], "description": definition["description"], "rarity": definition["rarity"], "level": int(_levels.get(upgrade_id, 0)), "max_level": int(definition["max_level"]), "slot_category": str(definition.get("category", "attack" if upgrade_id.begins_with("sword") else "passive"))})
	return options


func apply_upgrade(upgrade_id: String) -> void:
	if not UPGRADES.has(upgrade_id) or _player == null or _auto_attack == null:
		return
	var level := int(_levels.get(upgrade_id, 0))
	if level >= int(UPGRADES[upgrade_id]["max_level"]):
		return
	_levels[upgrade_id] = level + 1
	_history.append(upgrade_id)
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
