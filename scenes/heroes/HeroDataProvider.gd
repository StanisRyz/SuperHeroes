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
			"attack_damage_bonus": 1,
			"attack_interval_multiplier": 1.0,
			"ability_cooldown_multiplier": 0.98,
			"nova_damage_bonus": 3,
			"nova_radius_bonus": 15.0,
			"laser_damage_bonus": 5,
			"laser_width_bonus": 10.0,
			"slam_damage_bonus": 6,
			"slam_radius_bonus": 10.0,
		},
		"ability_names": {
			1: {"display_name": "Solar Burst", "short_name": "Burst"},
			2: {"display_name": "Solar Beam", "short_name": "Beam"},
			3: {"display_name": "Aerial Impact", "short_name": "Impact"},
		},
		"kit_id": "solar_guardian",
		"ability_kit": {
			"passive_name": "Solar Charge",
			"passive_description": "Ability hits build charge. High charge empowers Solar Burst, Solar Beam, and Aerial Impact.",
		},
		"starting_modifiers": {"bonus": "Higher durability, focused beam power, and radiant impact abilities."},
		"color": Color(1.0, 0.72, 0.22, 1.0),
	},
	{
		"id": "blaster",
		"display_name": "Night Tactician",
		"subtitle": "Gadget control specialist",
		"description": "A disciplined operator who wins with precision tools, tactical mobility, and controlled burst damage.",
		"playstyle": "Gadgets / precision / mobility",
		"unlocked_by_default": true,
		"unlock_cost": 100,
		"stats": {
			"max_health": 90,
			"speed": 275.0,
			"attack_damage_bonus": 2,
			"projectile_count_bonus": 1,
			"attack_interval_multiplier": 0.98,
			"ability_cooldown_multiplier": 0.95,
			"nova_radius_bonus": 10.0,
			"laser_damage_bonus": 4,
			"laser_width_bonus": -8.0,
			"slam_damage_bonus": 3,
			"slam_radius_bonus": 8.0,
		},
		"ability_names": {
			1: {"display_name": "Smoke Charge", "short_name": "Smoke"},
			2: {"display_name": "Grapnel Shot", "short_name": "Grapnel"},
			3: {"display_name": "Shock Trap", "short_name": "Trap"},
		},
		"kit_id": "night_tactician",
		"ability_kit": {
			"passive_name": "Tactical Mark",
			"passive_description": "Ability logic marks a priority target. Grapnel Shot and Shock Trap deal bonus damage to the mark.",
		},
		"starting_modifiers": {"bonus": "Uses tactical tools, quick movement, and precise controlled strikes."},
		"color": Color(0.28, 0.30, 0.42, 1.0),
	},
	{
		"id": "vanguard",
		"display_name": "Fury Vanguard",
		"subtitle": "Rage bruiser",
		"description": "A heavy close-range brawler who absorbs punishment, surges forward, and ends fights with brutal ground-shaking impacts.",
		"playstyle": "Durable / rage / close burst",
		"unlocked_by_default": true,
		"unlock_cost": 150,
		"stats": {
			"max_health": 125,
			"speed": 245.0,
			"attack_damage_bonus": 2,
			"attack_interval_multiplier": 1.08,
			"ability_cooldown_multiplier": 0.98,
			"nova_damage_bonus": 5,
			"nova_radius_bonus": 20.0,
			"laser_damage_bonus": 2,
			"laser_width_bonus": 18.0,
			"slam_damage_bonus": 8,
			"slam_radius_bonus": 20.0,
		},
		"ability_names": {
			1: {"display_name": "Rage Burst", "short_name": "Rage"},
			2: {"display_name": "Crushing Leap", "short_name": "Leap"},
			3: {"display_name": "Titan Slam", "short_name": "Slam"},
		},
		"kit_id": "fury_vanguard",
		"ability_kit": {
			"passive_name": "Rage",
			"passive_description": "Taking damage and landing ability hits build Rage. Rage empowers bruiser impacts.",
		},
		"starting_modifiers": {"bonus": "Higher durability, heavier close-range impacts, and slower bruiser movement."},
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
