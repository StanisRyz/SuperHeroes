extends Node

const DEFAULT_HERO_ID := "guardian"

var _heroes: Array[Dictionary] = [
	{
		"id": "guardian",
		"display_name": "Solar Guardian",
		"subtitle": "Skyborne powerhouse",
		"description": "A radiant protector built around durability, strength, and focused solar abilities.",
		"playstyle": "Durable / beam / impact",
		"unlocked_by_default": true,
		"unlock_cost": 0,
		"stats": {
			"max_health": 130,
			"speed": 250.0,
			"attack_damage_bonus": 2,
			"attack_interval_multiplier": 1.0,
		},
		"ability_names": {
			1: {"display_name": "Solar Beam", "short_name": "Beam"},
			2: {"display_name": "Frost Breath", "short_name": "Frost"},
			3: {"display_name": "Death Dash", "short_name": "Dash"},
		},
		"kit_id": "solar_guardian",
		"ability_kit": {
			"passive_name": "Solar Energy",
			"passive_description": "Gain 2 Solar Energy per second. At 100 Energy, enter a 15-second empowered state that doubles all damage.",
		},
		"primary_weapon": {
			"weapon_id": "solar_ray",
			"display_name": "Solar Ray",
			"direct_beam": true,
		},
		"starting_modifiers": {"bonus": "Focused beam autoattack, Solar Energy empowerment, and area-denial frost and dash abilities."},
		"color": Color(1.0, 0.72, 0.22, 1.0),
	},
	{
		"id": "blaster",
		"display_name": "Night Tactician",
		"subtitle": "Rocket tactician",
		"description": "A shadowed operator who fires homing rockets, blankets the field in smoke, plants explosive traps, and closes with a grappling hook to mark and eliminate targets.",
		"playstyle": "Rockets / marks / tactical area control",
		"unlocked_by_default": true,
		"unlock_cost": 100,
		"stats": {
			"max_health": 90,
			"speed": 275.0,
			"attack_damage_bonus": 2,
			"projectile_count_bonus": 1,
			"attack_interval_multiplier": 0.98,
			"ability_cooldown_multiplier": 0.95,
		},
		"ability_names": {
			1: {"display_name": "Smoke Screen", "short_name": "Smoke"},
			2: {"display_name": "Explosive Trap", "short_name": "Trap"},
			3: {"display_name": "Grappling Hook", "short_name": "Hook"},
		},
		"kit_id": "night_tactician",
		"ability_kit": {
			"passive_name": "Tactical Mark",
			"passive_description": "Active abilities apply Tactical Mark to enemies hit. Marked enemies take bonus damage from Night Tactician homing rockets.",
		},
		"primary_weapon": {
			"weapon_id": "homing_rockets",
			"display_name": "Homing Rockets",
			"projectile_speed": 560.0,
			"projectile_size_multiplier": 0.9,
		},
		"starting_modifiers": {"bonus": "Fires homing rockets at up to 7 targets. Uses Smoke Screen, Explosive Trap, and Grappling Hook to mark and control the battlefield."},
		"color": Color(0.28, 0.30, 0.42, 1.0),
	},
	{
		"id": "vanguard",
		"display_name": "Fury Vanguard",
		"subtitle": "Rage bruiser",
		"description": "A heavy close-range brawler who absorbs punishment, builds Rage from every hit taken and given, then unleashes devastating ground strikes, clap blasts, and rage-fuelled leaps.",
		"playstyle": "Durable / rage / melee splash",
		"unlocked_by_default": true,
		"unlock_cost": 150,
		"stats": {
			"max_health": 125,
			"speed": 245.0,
			"attack_damage_bonus": 2,
			"attack_interval_multiplier": 1.08,
			"ability_cooldown_multiplier": 0.98,
		},
		"ability_names": {
			1: {"display_name": "Rage Wave", "short_name": "Wave"},
			2: {"display_name": "Mighty Clap", "short_name": "Clap"},
			3: {"display_name": "Rage Leap", "short_name": "Leap"},
		},
		"kit_id": "fury_vanguard",
		"ability_kit": {
			"passive_name": "Rage",
			"passive_description": "Rage builds when taking damage and when dealing damage with autoattacks or abilities. Rage decays over time. Higher Rage increases autoattack and ability damage.",
		},
		"primary_weapon": {
			"weapon_id": "splash_melee",
			"display_name": "Fury Strikes",
			"attack_range": 115.0,
			"direct_damage": true,
		},
		"starting_modifiers": {"bonus": "Close-range splash melee autoattack. Rage Wave, Mighty Clap, and Rage Leap active abilities. Rage passive builds from damage taken and dealt."},
		"color": Color(0.62, 0.22, 0.18, 1.0),
	},
]


func get_all_heroes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for hero in _heroes:
		result.append(hero.duplicate(true))
	return result


func get_hero(hero_id: String) -> Dictionary:
	for hero in _heroes:
		if str(hero.get("id", "")) == hero_id:
			return hero.duplicate(true)
	return {}


func get_default_hero() -> Dictionary:
	var hero := get_hero(DEFAULT_HERO_ID)
	if not hero.is_empty():
		return hero
	return _heroes[0].duplicate(true) if not _heroes.is_empty() else {}


func is_valid_hero(hero_id: String) -> bool:
	return not get_hero(hero_id).is_empty()
