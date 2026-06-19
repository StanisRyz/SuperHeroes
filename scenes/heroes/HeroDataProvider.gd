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
		"starting_modifiers": {"bonus": "Higher durability, focused beam power, and radiant impact abilities."},
		"color": Color(1.0, 0.72, 0.22, 1.0),
	},
	{
		"id": "blaster",
		"display_name": "Blaster",
		"subtitle": "Projectile specialist",
		"description": "Projectile-focused hero. Starts with extra firepower and one additional projectile.",
		"playstyle": "Projectile-focused",
		"unlocked_by_default": true,
		"unlock_cost": 100,
		"stats": {
			"max_health": 90,
			"speed": 265.0,
			"attack_damage_bonus": 3,
			"projectile_count_bonus": 1,
			"attack_interval_multiplier": 1.05,
		},
		"starting_modifiers": {"bonus": "Starts with +1 projectile."},
		"color": Color(0.95, 0.42, 0.12, 1.0),
	},
	{
		"id": "vanguard",
		"display_name": "Vanguard",
		"subtitle": "Burst ability striker",
		"description": "Ability-focused hero. Trades no durability for stronger bursts and faster cooldowns.",
		"playstyle": "Ability / burst-focused",
		"unlocked_by_default": true,
		"unlock_cost": 150,
		"stats": {
			"max_health": 100,
			"speed": 275.0,
			"ability_cooldown_multiplier": 0.9,
			"nova_damage_bonus": 4,
			"slam_damage_bonus": 6,
		},
		"starting_modifiers": {"bonus": "Stronger active abilities and slightly faster cooldowns."},
		"color": Color(0.22, 0.8, 0.62, 1.0),
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
