extends Node

signal build_changed(dominant_archetype: String, points: Dictionary)

const ATTACK_INTERVAL_MIN := 0.2
const NOVA_COOLDOWN_MIN := 2.0
const LASER_COOLDOWN_MIN := 3.0
const SLAM_COOLDOWN_MIN := 3.5
const DASH_COOLDOWN_MIN := 0.45
const DASH_INVULNERABILITY_MAX := 0.6
const PROJECTILE_COUNT_MAX := 7
const PROJECTILE_SIZE_MAX := 2.0
const PROJECTILE_EXPLOSION_RADIUS_MAX := 180.0
const PROJECTILE_BOUNCE_MAX := 5
const SLOT_CATEGORY_ATTACK := "attack"
const SLOT_CATEGORY_PASSIVE := "passive"
const SLOT_CATEGORY_ACTIVE := "active"
const VALID_SLOT_CATEGORIES := [SLOT_CATEGORY_ATTACK, SLOT_CATEGORY_PASSIVE, SLOT_CATEGORY_ACTIVE]
const EVOLUTION_ROLE_ATTACK := "attack"
const EVOLUTION_ROLE_PASSIVE := "passive"
const EVOLUTION_ROLE_ACTIVE := "active"
const VALID_EVOLUTION_ROLES := [EVOLUTION_ROLE_ATTACK, EVOLUTION_ROLE_PASSIVE, EVOLUTION_ROLE_ACTIVE]
const SOURCE_TYPE_AUTOATTACK := "autoattack"
const SOURCE_TYPE_PASSIVE := "passive"
const SOURCE_TYPE_ABILITY := "ability"
const SOURCE_TYPE_GENERIC := "generic"
const VALID_SOURCE_TYPES := [SOURCE_TYPE_AUTOATTACK, SOURCE_TYPE_PASSIVE, SOURCE_TYPE_ABILITY, SOURCE_TYPE_GENERIC]
const HERO_IDS := ["guardian", "blaster", "vanguard"]
const MAX_ATTACK_LINES := 4
const MAX_PASSIVE_LINES := 4
const MAX_ACTIVE_LINES := 4
const TARGET_ATTACK_LINES_PER_HERO := 9
const TARGET_ACTIVE_LINES_PER_HERO := 9
const TARGET_SHARED_PASSIVE_LINES := 9

const HERO_UPGRADE_FLAVOR := {
	"guardian": {
		"titles": {
			"attack_damage_up": "Radiant Strike",
			"attack_speed_up": "Solar Tempo",
			"attack_range_up": "Sunray Reach",
			"move_speed_up": "Aerial Momentum",
			"max_health_up": "Solar Fortitude",
			"shielded_dash": "Dawn Guard Dash",
			"heroic_endurance": "Solar Endurance",
			"power_collector": "Sunlit Collector",
			"dash_damage_trail": "Comet Guard",
			"solar_ray_damage": "Sunray Power",
			"solar_ray_range": "Skyline Reach",
			"solar_ray_width": "Wide Sunray",
			"solar_ray_pierce_burn": "Scorching Ray",
			"solar_beam_damage_up": "Solar Beam Focus",
			"solar_beam_range_up": "Extended Sunray",
			"frost_breath_power": "Deep Freeze",
			"frost_breath_cone_up": "Arctic Spread",
			"death_dash_power": "Death Drive",
			"death_dash_cooldown_down": "Reaper's Stride",
			"solar_empower_boost": "Radiant Surge",
		},
		"descriptions": {
			"attack_damage_up": "Increase Solar Ray beam damage by %s.",
			"attack_speed_up": "Reduce Solar Ray attack interval by %ss.",
			"attack_range_up": "Increase Solar Ray beam targeting range by %s.",
			"move_speed_up": "Increase aerial movement speed by %s.",
			"max_health_up": "Increase solar durability and heal by %s.",
			"shielded_dash": "Extend guarded dash invulnerability and trim dash cooldown.",
			"heroic_endurance": "Increase solar max health by %s and restore HP.",
			"power_collector": "Increase movement speed for better radiant pickup reach.",
		},
	},
	"blaster": {
		"titles": {
			"attack_damage_up": "Rocket Striker",
			"attack_speed_up": "Tactical Tempo",
			"attack_range_up": "Optic Rangefinder",
			"move_speed_up": "Shadow Step",
			"max_health_up": "Armored Lining",
			"projectile_speed_up": "Quick Rocket",
			"shielded_dash": "Evasive Guard",
			"heroic_endurance": "Reinforced Kit",
			"power_collector": "Utility Sweep",
			"dash_damage_trail": "Tactical Exit",
			"rocket_damage": "Rocket Payload",
			"rocket_count": "Multi-Rocket",
			"rocket_explosion_radius": "Impact Warhead",
			"rocket_reload": "Reload Cycle",
			"marked_target_payload": "Mark Amplifier",
			"smoke_screen_radius": "Wide Cover",
			"smoke_screen_duration": "Lingering Smoke",
			"smoke_screen_slow": "Thick Haze",
			"smoke_screen_damage_reduction": "Smoke Cover",
			"trap_radius": "Big Blast",
			"trap_damage": "Overcharge Trap",
			"trap_cooldown_down": "Trap Ready",
			"trap_mark_bonus": "Marked Detonation",
			"hook_damage": "Heavy Hook",
			"hook_range": "Extended Cable",
			"hook_cooldown_down": "Quick Hook",
			"hook_mark_bonus": "Reel & Mark",
		},
		"descriptions": {
			"attack_damage_up": "Increase homing rocket base damage by %s.",
			"attack_speed_up": "Reduce rocket fire interval by %ss.",
			"attack_range_up": "Increase rocket targeting range by %s.",
			"move_speed_up": "Increase tactical movement speed by %s.",
			"max_health_up": "Increase armor reserves and heal by %s.",
			"projectile_speed_up": "Increase homing rocket travel speed by %s.",
			"shielded_dash": "Extend evasive invulnerability and trim dash cooldown.",
			"heroic_endurance": "Increase reinforced max health by %s and restore HP.",
			"power_collector": "Increase movement speed for cleaner pickup routes.",
			"rocket_damage": "Increase homing rocket impact damage by %s.",
			"rocket_count": "Fire +%s additional homing rocket per attack.",
			"rocket_explosion_radius": "Rockets explode on impact, adding +%s blast radius.",
			"rocket_reload": "Reduce rocket fire interval by %ss.",
			"marked_target_payload": "Increase Tactical Mark autoattack damage bonus.",
		},
	},
	"vanguard": {
		"titles": {
			"attack_damage_up": "Bruiser Blow",
			"attack_speed_up": "Fury Tempo",
			"attack_range_up": "Long Swing",
			"move_speed_up": "Heavy Charge",
			"max_health_up": "Thick Hide",
			"shielded_dash": "Braced Charge",
			"heroic_endurance": "Bruiser Endurance",
			"power_collector": "Power Rush",
			"dash_damage_trail": "Rampage Dash",
			"splash_melee_damage": "Fury Strike Power",
			"splash_melee_radius": "Wide Fury",
			"splash_melee_speed": "Fury Tempo",
			"splash_melee_impact": "Knockback Force",
			"splash_melee_frenzy": "Berserker Frenzy",
			"rage_wave_power": "Wave Surge",
			"rage_wave_radius": "Wave Reach",
			"rage_wave_cooldown": "Wave Recovery",
			"rage_wave_deep_slow": "Crushing Current",
			"rage_wave_chain": "Chain Wave",
			"mighty_clap_power": "Clap Force",
			"mighty_clap_range": "Wide Clap",
			"mighty_clap_cooldown": "Clap Ready",
			"mighty_clap_shockwave": "Impact Wave",
			"rage_leap_power": "Leap Impact",
			"rage_leap_radius": "Wide Landing",
			"rage_leap_cooldown": "Leap Ready",
		},
		"descriptions": {
			"attack_damage_up": "Increase fury strike autoattack damage by %s.",
			"attack_speed_up": "Reduce fury strike attack interval by %ss.",
			"attack_range_up": "Increase close-combat targeting range by %s.",
			"move_speed_up": "Increase charging movement speed by %s.",
			"max_health_up": "Increase bruiser max health and heal by %s.",
			"shielded_dash": "Extend braced dash invulnerability and trim dash cooldown.",
			"heroic_endurance": "Increase bruiser max health by %s and restore HP.",
			"power_collector": "Increase movement speed for aggressive pickup reach.",
		},
	},
}

var player: Node
var auto_attack: Node
var ability_manager: Node
var passive_ability_manager: Node
var hero_data: Dictionary = {}
var upgrade_levels: Dictionary = {}
var archetype_points: Dictionary = {}
var selected_upgrade_history: Array[Dictionary] = []
var selected_attack_lines: Array[String] = []
var selected_passive_lines: Array[String] = []
var selected_active_lines: Array[String] = []

# Upgrade definitions are hardcoded for now. Archetypes drive build identity,
# prerequisites unlock synergies, and build-defining entries reshape a run.
var _upgrade_definitions: Array[Dictionary] = [
	# ── BASE UPGRADES ───────────────────────────────────────────────────────────
	{
		"id": "attack_damage_up",
		"title": "Power Bolt",
		"rarity": "common",
		"weight": 1.0,
		"max_level": 5,
		"description_template": "Increase autoattack damage by %s.",
		"effect_value": 2,
		"archetype": "projectile",
		"tags": ["weapon", "damage"]
	},
	{
		"id": "attack_speed_up",
		"title": "Quick Charge",
		"rarity": "rare",
		"weight": 0.75,
		"max_level": 5,
		"description_template": "Reduce autoattack interval by %ss.",
		"effect_value": 0.08,
		"archetype": "projectile",
		"tags": ["weapon", "speed"]
	},
	{
		"id": "attack_range_up",
		"title": "Long Reach",
		"rarity": "rare",
		"weight": 0.75,
		"max_level": 4,
		"description_template": "Increase autoattack targeting range by %s.",
		"effect_value": 45.0,
		"archetype": "projectile",
		"tags": ["weapon", "range"]
	},
	{
		"id": "move_speed_up",
		"title": "Hero Sprint",
		"rarity": "common",
		"weight": 1.0,
		"max_level": 5,
		"description_template": "Increase movement speed by %s.",
		"effect_value": 25.0,
		"archetype": "speed",
		"tags": ["mobility", "speed"]
	},
	{
		"id": "max_health_up",
		"title": "Iron Resolve",
		"rarity": "common",
		"weight": 1.0,
		"max_level": 5,
		"description_template": "Increase maximum HP and heal by %s.",
		"effect_value": 20,
		"archetype": "tank",
		"tags": ["defense", "health"]
	},
	{
		"id": "projectile_speed_up",
		"title": "Faster Bolts",
		"rarity": "rare",
		"weight": 0.75,
		"max_level": 4,
		"description_template": "Increase speed of newly fired projectiles by %s.",
		"effect_value": 80.0,
		"archetype": "projectile",
		"tags": ["weapon", "speed"],
		"hero_exclude": ["guardian", "vanguard"]
	},
	{
		"id": "orbit_shields",
		"title": "Orbit Shields",
		"rarity": "rare",
		"weight": 0.55,
		"max_level": 3,
		"description_template": "Regenerate blocking shield charges over time.",
		"effect_value": 0,
		"archetype": "tank",
		"type": "passive",
		"category": "passive",
		"slot_category": "passive",
		"upgrade_line_id": "orbit_shields",
		"source_type": "passive",
		"source_skill_id": "orbit_shields",
		"grid_index": 1,
		"evolution_role": "passive",
		"tags": ["passive", "defense", "shield"]
	},
	{
		"id": "storm_relay",
		"title": "Storm Relay",
		"rarity": "rare",
		"weight": 0.55,
		"max_level": 3,
		"description_template": "Automatically strike the nearest enemy with lightning.",
		"effect_value": 0,
		"archetype": "utility",
		"type": "passive",
		"category": "passive",
		"slot_category": "passive",
		"upgrade_line_id": "storm_relay",
		"source_type": "passive",
		"source_skill_id": "storm_relay",
		"grid_index": 2,
		"evolution_role": "passive",
		"tags": ["passive", "damage", "lightning"]
	},
	{
		"id": "guardian_drone",
		"title": "Guardian Drone",
		"rarity": "common",
		"weight": 0.65,
		"max_level": 3,
		"description_template": "A support drone periodically attacks nearby enemies.",
		"effect_value": 0,
		"archetype": "projectile",
		"type": "passive",
		"category": "passive",
		"slot_category": "passive",
		"upgrade_line_id": "guardian_drone",
		"source_type": "passive",
		"source_skill_id": "guardian_drone",
		"grid_index": 3,
		"evolution_role": "passive",
		"tags": ["passive", "damage", "drone"]
	},
	{
		"id": "magnet_core",
		"title": "Magnet Core",
		"rarity": "common",
		"weight": 0.65,
		"max_level": 3,
		"description_template": "Increase XP gem and pickup magnet reach.",
		"effect_value": 0,
		"archetype": "utility",
		"type": "passive",
		"category": "passive",
		"slot_category": "passive",
		"upgrade_line_id": "magnet_core",
		"source_type": "passive",
		"source_skill_id": "magnet_core",
		"grid_index": 4,
		"evolution_role": "passive",
		"tags": ["passive", "pickup", "magnet"]
	},
	{
		"id": "chain_lightning",
		"title": "Chain Lightning",
		"rarity": "rare",
		"weight": 0.52,
		"max_level": 3,
		"description_template": "Periodically strike one enemy, then bounce lightning to nearby enemies.",
		"effect_value": 0,
		"archetype": "utility",
		"type": "passive",
		"category": "passive",
		"slot_category": "passive",
		"upgrade_line_id": "chain_lightning",
		"source_type": "passive",
		"source_skill_id": "chain_lightning",
		"grid_index": 5,
		"evolution_role": "passive",
		"tags": ["passive", "damage", "lightning", "chain"]
	},
	{
		"id": "recovery_field",
		"title": "Recovery Field",
		"rarity": "common",
		"weight": 0.58,
		"max_level": 3,
		"description_template": "Periodically emit a recovery pulse that restores a small amount of HP.",
		"effect_value": 0,
		"archetype": "tank",
		"type": "passive",
		"category": "passive",
		"slot_category": "passive",
		"upgrade_line_id": "recovery_field",
		"source_type": "passive",
		"source_skill_id": "recovery_field",
		"grid_index": 6,
		"evolution_role": "passive",
		"tags": ["passive", "healing", "defense"]
	},
	{
		"id": "battle_focus",
		"title": "Battle Focus",
		"rarity": "rare",
		"weight": 0.5,
		"max_level": 3,
		"description_template": "Periodically land a focus strike and gain a short attack speed boost.",
		"effect_value": 0,
		"archetype": "speed",
		"type": "passive",
		"category": "passive",
		"slot_category": "passive",
		"upgrade_line_id": "battle_focus",
		"source_type": "passive",
		"source_skill_id": "battle_focus",
		"grid_index": 7,
		"evolution_role": "passive",
		"tags": ["passive", "buff", "speed", "damage"]
	},
	{
		"id": "static_field",
		"title": "Static Field",
		"rarity": "common",
		"weight": 0.56,
		"max_level": 3,
		"description_template": "Periodically shock enemies in a small radius around the player.",
		"effect_value": 0,
		"archetype": "utility",
		"type": "passive",
		"category": "passive",
		"slot_category": "passive",
		"upgrade_line_id": "static_field",
		"source_type": "passive",
		"source_skill_id": "static_field",
		"grid_index": 8,
		"evolution_role": "passive",
		"tags": ["passive", "damage", "aoe", "lightning"]
	},
	{
		"id": "time_dilator",
		"title": "Time Dilator",
		"rarity": "rare",
		"weight": 0.5,
		"max_level": 3,
		"description_template": "Periodically slow nearby enemies with a visible time pulse.",
		"effect_value": 0,
		"archetype": "utility",
		"type": "passive",
		"category": "passive",
		"slot_category": "passive",
		"upgrade_line_id": "time_dilator",
		"source_type": "passive",
		"source_skill_id": "time_dilator",
		"grid_index": 9,
		"evolution_role": "passive",
		"tags": ["passive", "slow", "control", "utility"]
	},
	{
		"id": "nova_damage_up",
		"title": "Nova Surge",
		"rarity": "epic",
		"weight": 0.45,
		"max_level": 4,
		"description_template": "Increase Nova Pulse damage by %s.",
		"effect_value": 5,
		"archetype": "nova",
		"tags": ["ability", "damage", "aoe"],
		"hero_exclude": ["guardian", "blaster", "vanguard"]
	},
	{
		"id": "nova_cooldown_down",
		"title": "Pulse Rhythm",
		"rarity": "epic",
		"weight": 0.45,
		"max_level": 4,
		"description_template": "Reduce Nova Pulse cooldown by %ss.",
		"effect_value": 0.5,
		"archetype": "nova",
		"tags": ["ability", "cooldown"],
		"hero_exclude": ["guardian", "blaster", "vanguard"]
	},
	{
		"id": "dash_cooldown_down",
		"title": "Quick Escape",
		"rarity": "rare",
		"weight": 0.7,
		"max_level": 4,
		"description_template": "Reduce dash cooldown by %ss.",
		"effect_value": 0.15,
		"archetype": "dash",
		"tags": ["defense", "mobility"]
	},
	{
		"id": "dash_invulnerability_up",
		"title": "Hero Reflex",
		"rarity": "epic",
		"weight": 0.45,
		"max_level": 3,
		"description_template": "Increase dash invulnerability by %ss.",
		"effect_value": 0.08,
		"archetype": "dash",
		"tags": ["defense", "mobility"]
	},
	{
		"id": "projectile_pierce_up",
		"title": "Piercing Bolts",
		"rarity": "rare",
		"weight": 0.65,
		"max_level": 4,
		"description_template": "Increase projectile pierce by %s.",
		"effect_value": 1,
		"archetype": "projectile",
		"tags": ["weapon", "pierce"],
		"hero_exclude": ["guardian", "blaster", "vanguard"]
	},
	{
		"id": "multishot_up",
		"title": "Hero Barrage",
		"rarity": "epic",
		"weight": 0.35,
		"max_level": 3,
		"description_template": "Fire +%s projectile per attack.",
		"effect_value": 1,
		"archetype": "projectile",
		"tags": ["weapon", "projectile_count"],
		"hero_exclude": ["guardian", "vanguard"]
	},
	{
		"id": "spread_up",
		"title": "Wide Angle",
		"rarity": "rare",
		"weight": 0.65,
		"max_level": 4,
		"description_template": "Increase projectile spread angle by %s degrees.",
		"effect_value": 8.0,
		"archetype": "projectile",
		"tags": ["weapon", "spread"],
		"hero_exclude": ["guardian", "vanguard"]
	},
	{
		"id": "projectile_size_up",
		"title": "Heavy Bolts",
		"rarity": "common",
		"weight": 0.8,
		"max_level": 4,
		"description_template": "Increase projectile size by %s.",
		"effect_value": 0.15,
		"archetype": "projectile",
		"tags": ["weapon", "size"],
		"hero_exclude": ["guardian", "vanguard"]
	},
	{
		"id": "explosive_projectiles",
		"title": "Impact Burst",
		"rarity": "epic",
		"weight": 0.35,
		"max_level": 3,
		"description_template": "Increase projectile explosion radius by %s.",
		"effect_value": 45.0,
		"archetype": "projectile",
		"tags": ["weapon", "explosion"],
		"hero_exclude": ["guardian", "vanguard"]
	},
	{
		"id": "laser_damage_up",
		"title": "Laser Focus",
		"rarity": "epic",
		"weight": 0.45,
		"max_level": 4,
		"description_template": "Increase Laser Beam damage by %s.",
		"effect_value": 8,
		"archetype": "laser",
		"tags": ["ability", "damage"],
		"hero_exclude": ["guardian", "blaster", "vanguard"]
	},
	{
		"id": "laser_cooldown_down",
		"title": "Laser Capacitor",
		"rarity": "epic",
		"weight": 0.4,
		"max_level": 4,
		"description_template": "Reduce Laser Beam cooldown by %ss.",
		"effect_value": 0.5,
		"archetype": "laser",
		"tags": ["ability", "cooldown"],
		"hero_exclude": ["guardian", "blaster", "vanguard"]
	},
	{
		"id": "laser_width_up",
		"title": "Wide Beam",
		"rarity": "rare",
		"weight": 0.65,
		"max_level": 4,
		"description_template": "Increase Laser Beam width by %s.",
		"effect_value": 20.0,
		"archetype": "laser",
		"tags": ["ability", "area"],
		"hero_exclude": ["guardian", "blaster", "vanguard"]
	},
	{
		"id": "slam_damage_up",
		"title": "Impact Force",
		"rarity": "epic",
		"weight": 0.45,
		"max_level": 4,
		"description_template": "Increase Hero Slam damage by %s.",
		"effect_value": 10,
		"archetype": "slam",
		"tags": ["ability", "damage"],
		"hero_exclude": ["guardian", "blaster", "vanguard"]
	},
	{
		"id": "slam_radius_up",
		"title": "Shockwave",
		"rarity": "rare",
		"weight": 0.65,
		"max_level": 4,
		"description_template": "Increase Hero Slam radius by %s.",
		"effect_value": 25.0,
		"archetype": "slam",
		"tags": ["ability", "aoe"],
		"hero_exclude": ["guardian", "blaster", "vanguard"]
	},
	{
		"id": "slam_cooldown_down",
		"title": "Slam Ready",
		"rarity": "epic",
		"weight": 0.4,
		"max_level": 4,
		"description_template": "Reduce Hero Slam cooldown by %ss.",
		"effect_value": 0.6,
		"archetype": "slam",
		"tags": ["ability", "cooldown"],
		"hero_exclude": ["guardian", "blaster", "vanguard"]
	},
	# ── PROJECTILE SYNERGY UPGRADES ─────────────────────────────────────────────
	{
		"id": "split_barrage",
		"title": "Split Barrage",
		"rarity": "epic",
		"weight": 0.3,
		"max_level": 2,
		"description_template": "Fire +1 projectile and widen spread angle.",
		"effect_value": 0,
		"archetype": "projectile",
		"tags": ["weapon", "synergy", "multishot"],
		"hero_exclude": ["guardian", "vanguard"],
		"prerequisites": {
			"upgrade_levels": {"multishot_up": 1},
			"archetype_points": {"projectile": 2}
		},
		"effects": [
			{"target": "auto_attack", "property": "projectile_count", "operation": "add", "value": 1, "max_value": 7},
			{"target": "auto_attack", "property": "projectile_spread_degrees", "operation": "add", "value": 6.0}
		]
	},
	{
		"id": "shrapnel_burst",
		"title": "Shrapnel Burst",
		"rarity": "epic",
		"weight": 0.3,
		"max_level": 2,
		"description_template": "Expand explosion radius and boost explosion power.",
		"effect_value": 0,
		"archetype": "projectile",
		"tags": ["weapon", "synergy", "explosion"],
		"hero_exclude": ["guardian", "vanguard"],
		"prerequisites": {
			"upgrade_levels": {"explosive_projectiles": 1},
			"archetype_points": {"projectile": 2}
		},
		"effects": [
			{"target": "auto_attack", "property": "projectile_explosion_radius", "operation": "add", "value": 25.0, "max_value": 180.0},
			{"target": "auto_attack", "property": "projectile_explosion_damage_multiplier", "operation": "add", "value": 0.08}
		]
	},
	{
		"id": "heavy_piercer",
		"title": "Heavy Piercer",
		"rarity": "rare",
		"weight": 0.4,
		"max_level": 2,
		"description_template": "Gain +1 pierce and fire larger projectiles.",
		"effect_value": 0,
		"archetype": "projectile",
		"tags": ["weapon", "synergy", "pierce"],
		"hero_exclude": ["guardian", "blaster", "vanguard"],
		"prerequisites": {
			"upgrade_levels": {"projectile_pierce_up": 1}
		},
		"effects": [
			{"target": "auto_attack", "property": "projectile_pierce", "operation": "add", "value": 1},
			{"target": "auto_attack", "property": "projectile_size_multiplier", "operation": "add", "value": 0.1, "max_value": 2.0}
		]
	},
	# ── ABILITY SYNERGY UPGRADES ─────────────────────────────────────────────────
	{
		"id": "nova_aftershock",
		"title": "Nova Aftershock",
		"rarity": "epic",
		"weight": 0.3,
		"max_level": 2,
		"description_template": "Expand Nova Pulse radius and boost its damage.",
		"effect_value": 0,
		"archetype": "nova",
		"tags": ["ability", "synergy", "aoe"],
		"hero_exclude": ["guardian", "blaster", "vanguard"],
		"prerequisites": {
			"archetype_points": {"nova": 2}
		},
		"effects": [
			{"target": "ability_manager", "property": "nova_radius", "operation": "add", "value": 30.0},
			{"target": "ability_manager", "property": "nova_damage", "operation": "add", "value": 6}
		]
	},
	{
		"id": "laser_overcharge",
		"title": "Laser Overcharge",
		"rarity": "epic",
		"weight": 0.3,
		"max_level": 2,
		"description_template": "Boost Laser Beam damage and extend its range.",
		"effect_value": 0,
		"archetype": "laser",
		"tags": ["ability", "synergy", "beam"],
		"hero_exclude": ["guardian", "blaster", "vanguard"],
		"prerequisites": {
			"archetype_points": {"laser": 2}
		},
		"effects": [
			{"target": "ability_manager", "property": "laser_damage", "operation": "add", "value": 10},
			{"target": "ability_manager", "property": "laser_range", "operation": "add", "value": 60.0}
		]
	},
	{
		"id": "slam_quake",
		"title": "Slam Quake",
		"rarity": "epic",
		"weight": 0.3,
		"max_level": 2,
		"description_template": "Expand Hero Slam radius and increase its damage.",
		"effect_value": 0,
		"archetype": "slam",
		"tags": ["ability", "synergy", "aoe"],
		"hero_exclude": ["guardian", "blaster", "vanguard"],
		"prerequisites": {
			"archetype_points": {"slam": 2}
		},
		"effects": [
			{"target": "ability_manager", "property": "slam_radius", "operation": "add", "value": 30.0},
			{"target": "ability_manager", "property": "slam_damage", "operation": "add", "value": 12}
		]
	},
	# ── DEFENSIVE / SURVIVAL SYNERGY UPGRADES ────────────────────────────────────
	{
		"id": "shielded_dash",
		"title": "Shielded Dash",
		"rarity": "epic",
		"weight": 0.3,
		"max_level": 2,
		"description_template": "Extend dash invulnerability and trim dash cooldown.",
		"effect_value": 0,
		"archetype": "dash",
		"tags": ["defense", "mobility", "synergy"],
		"prerequisites": {
			"archetype_points": {"dash": 2}
		},
		"effects": [
			{"target": "player", "property": "dash_invulnerability_duration", "operation": "add", "value": 0.1, "max_value": 0.6},
			{"target": "player", "property": "dash_cooldown", "operation": "subtract", "value": 0.1, "min_value": 0.45}
		]
	},
	{
		"id": "heroic_endurance",
		"title": "Heroic Endurance",
		"rarity": "rare",
		"weight": 0.35,
		"max_level": 3,
		"description_template": "Increase max health by %s and restore HP.",
		"effect_value": 30,
		"archetype": "tank",
		"tags": ["defense", "health", "survival"],
		"prerequisites": {
			"upgrade_levels": {"max_health_up": 2}
		}
	},
	{
		"id": "power_collector",
		"title": "Power Collector",
		"rarity": "rare",
		"weight": 0.35,
		"max_level": 2,
		"description_template": "Increase movement speed for better pickup reach.",
		"effect_value": 0,
		"archetype": "utility",
		"tags": ["pickup", "powerup", "magnet"],
		"prerequisites": {
			"any_archetype_points": {"utility": 1, "speed": 1}
		},
		"effects": [
			{"target": "player", "property": "speed", "operation": "add", "value": 18.0}
		]
	},
	# в”Ђв”Ђ BUILD-DEFINING SYNERGY UPGRADES v4 в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
	{
		"id": "nova_aftershock_zone",
		"title": "Aftershock Zone",
		"rarity": "epic",
		"weight": 0.24,
		"max_level": 2,
		"description_template": "Nova Pulse creates a delayed aftershock zone.",
		"effect_value": 0,
		"archetype": "nova",
		"tags": ["ability", "synergy", "aoe", "build_defining"],
		"is_build_defining": true,
		"hero_exclude": ["guardian", "blaster", "vanguard"],
		"prerequisites": {
			"any_of": [
				{"upgrade_levels": {"nova_aftershock": 1}},
				{"archetype_points": {"nova": 3}}
			]
		},
		"effects": [
			{"target": "ability_manager", "property": "nova_aftershock_enabled", "operation": "set", "value": true},
			{"target": "ability_manager", "property": "nova_aftershock_damage", "operation": "add", "value": 4},
			{"target": "ability_manager", "property": "nova_aftershock_radius", "operation": "add", "value": 20.0}
		]
	},
	{
		"id": "laser_double_pulse",
		"title": "Double Pulse",
		"rarity": "epic",
		"weight": 0.24,
		"max_level": 2,
		"description_template": "Laser Beam fires a delayed weaker second pulse.",
		"effect_value": 0,
		"archetype": "laser",
		"tags": ["ability", "synergy", "beam", "build_defining"],
		"is_build_defining": true,
		"hero_exclude": ["guardian", "blaster", "vanguard"],
		"prerequisites": {"archetype_points": {"laser": 3}},
		"effects": [
			{"target": "ability_manager", "property": "laser_double_pulse_enabled", "operation": "set", "value": true},
			{"target": "ability_manager", "property": "laser_second_pulse_damage_multiplier", "operation": "add", "value": 0.1, "max_value": 0.85}
		]
	},
	{
		"id": "slam_second_wave",
		"title": "Seismic Echo",
		"rarity": "epic",
		"weight": 0.24,
		"max_level": 2,
		"description_template": "Hero Slam creates a delayed second wave at the cast position.",
		"effect_value": 0,
		"archetype": "slam",
		"tags": ["ability", "synergy", "aoe", "build_defining"],
		"is_build_defining": true,
		"hero_exclude": ["guardian", "blaster", "vanguard"],
		"prerequisites": {"archetype_points": {"slam": 3}},
		"effects": [
			{"target": "ability_manager", "property": "slam_second_wave_enabled", "operation": "set", "value": true},
			{"target": "ability_manager", "property": "slam_second_wave_damage_multiplier", "operation": "add", "value": 0.1, "max_value": 0.85},
			{"target": "ability_manager", "property": "slam_second_wave_radius_multiplier", "operation": "add", "value": 0.1, "max_value": 1.6}
		]
	},
	{
		"id": "dash_damage_trail",
		"title": "Comet Dash",
		"rarity": "epic",
		"weight": 0.26,
		"max_level": 2,
		"description_template": "Dash end damages nearby enemies.",
		"effect_value": 0,
		"archetype": "dash",
		"tags": ["mobility", "damage", "synergy", "build_defining"],
		"is_build_defining": true,
		"prerequisites": {"archetype_points": {"dash": 2}},
		"effects": [
			{"target": "player", "property": "dash_damage_trail_enabled", "operation": "set", "value": true},
			{"target": "player", "property": "dash_trail_damage", "operation": "add", "value": 8},
			{"target": "player", "property": "dash_trail_radius", "operation": "add", "value": 15.0}
		]
	},
	{
		"id": "bouncing_bolts",
		"title": "Bouncing Bolts",
		"rarity": "epic",
		"weight": 0.26,
		"max_level": 3,
		"description_template": "Projectiles can bounce to another nearby enemy.",
		"effect_value": 0,
		"archetype": "projectile",
		"tags": ["weapon", "bounce", "synergy", "build_defining"],
		"is_build_defining": true,
		"hero_exclude": ["guardian", "blaster", "vanguard"],
		"prerequisites": {
			"archetype_points": {"projectile": 3},
			"any_upgrade_levels": {"projectile_pierce_up": 1, "multishot_up": 1}
		},
		"effects": [
			{"target": "auto_attack", "property": "projectile_bounce", "operation": "add", "value": 1, "max_value": 5}
		]
	},
	# ── SOLAR GUARDIAN: ATTACK UPGRADES (solar_ray beam) ─────────────────────────
	{
		"id": "solar_ray_damage",
		"title": "Sunray Power",
		"rarity": "common",
		"weight": 0.9,
		"max_level": 5,
		"description_template": "Increase Solar Ray beam damage by %s.",
		"effect_value": 2,
		"archetype": "solar_ray",
		"tags": ["weapon", "damage"],
		"hero_only": ["guardian"]
	},
	{
		"id": "solar_ray_range",
		"title": "Skyline Reach",
		"rarity": "rare",
		"weight": 0.75,
		"max_level": 4,
		"description_template": "Increase Solar Ray beam targeting range by %s.",
		"effect_value": 50.0,
		"archetype": "solar_ray",
		"tags": ["weapon", "range"],
		"hero_only": ["guardian"]
	},
	{
		"id": "solar_ray_width",
		"title": "Wide Sunray",
		"rarity": "rare",
		"weight": 0.7,
		"max_level": 4,
		"description_template": "Increase Solar Ray beam hit corridor by %s.",
		"effect_value": 8.0,
		"archetype": "solar_ray",
		"tags": ["weapon", "area"],
		"hero_only": ["guardian"]
	},
	{
		"id": "solar_ray_pierce_burn",
		"title": "Scorching Ray",
		"rarity": "epic",
		"weight": 0.45,
		"max_level": 3,
		"description_template": "Increase Solar Ray burn intensity, adding %s bonus damage.",
		"effect_value": 3,
		"archetype": "solar_ray",
		"tags": ["weapon", "damage"],
		"hero_only": ["guardian"]
	},
	# ── SOLAR GUARDIAN: ACTIVE UPGRADES ─────────────────────────────────────────
	{
		"id": "solar_beam_damage_up",
		"title": "Solar Beam Focus",
		"rarity": "epic",
		"weight": 0.5,
		"max_level": 4,
		"description_template": "Increase Solar Beam ability damage by %s.",
		"effect_value": 7,
		"archetype": "solar_beam",
		"tags": ["ability", "damage"],
		"hero_only": ["guardian"],
		"effects": [
			{"target": "ability_manager", "property": "solar_beam_damage", "operation": "add", "value": 7}
		]
	},
	{
		"id": "solar_beam_range_up",
		"title": "Extended Sunray",
		"rarity": "rare",
		"weight": 0.65,
		"max_level": 4,
		"description_template": "Increase Solar Beam ability range by %s.",
		"effect_value": 55.0,
		"archetype": "solar_beam",
		"tags": ["ability", "area"],
		"hero_only": ["guardian"],
		"effects": [
			{"target": "ability_manager", "property": "solar_beam_range", "operation": "add", "value": 55.0},
			{"target": "ability_manager", "property": "solar_beam_width", "operation": "add", "value": 10.0}
		]
	},
	{
		"id": "frost_breath_power",
		"title": "Deep Freeze",
		"rarity": "epic",
		"weight": 0.5,
		"max_level": 4,
		"description_template": "Increase Frost Breath damage by %s and extend slow duration.",
		"effect_value": 6,
		"archetype": "frost_breath",
		"tags": ["ability", "damage"],
		"hero_only": ["guardian"],
		"effects": [
			{"target": "ability_manager", "property": "frost_breath_damage", "operation": "add", "value": 6},
			{"target": "ability_manager", "property": "frost_breath_slow_duration", "operation": "add", "value": 0.4}
		]
	},
	{
		"id": "frost_breath_cone_up",
		"title": "Arctic Spread",
		"rarity": "rare",
		"weight": 0.6,
		"max_level": 3,
		"description_template": "Widen Frost Breath cone and increase its range by %s.",
		"effect_value": 30.0,
		"archetype": "frost_breath",
		"tags": ["ability", "area"],
		"hero_only": ["guardian"],
		"effects": [
			{"target": "ability_manager", "property": "frost_breath_cone_degrees", "operation": "add", "value": 14.0},
			{"target": "ability_manager", "property": "frost_breath_range", "operation": "add", "value": 30.0}
		]
	},
	{
		"id": "death_dash_power",
		"title": "Death Drive",
		"rarity": "epic",
		"weight": 0.5,
		"max_level": 4,
		"description_template": "Increase Death Dash path damage by %s and extend dash distance.",
		"effect_value": 8,
		"archetype": "death_dash",
		"tags": ["ability", "damage"],
		"hero_only": ["guardian"],
		"effects": [
			{"target": "ability_manager", "property": "death_dash_damage", "operation": "add", "value": 8},
			{"target": "ability_manager", "property": "death_dash_distance", "operation": "add", "value": 30.0}
		]
	},
	{
		"id": "death_dash_cooldown_down",
		"title": "Reaper's Stride",
		"rarity": "epic",
		"weight": 0.45,
		"max_level": 3,
		"description_template": "Reduce Death Dash cooldown by %ss.",
		"effect_value": 0.8,
		"archetype": "death_dash",
		"tags": ["ability", "cooldown"],
		"hero_only": ["guardian"]
	},
	{
		"id": "solar_empower_boost",
		"title": "Radiant Surge",
		"rarity": "epic",
		"weight": 0.4,
		"max_level": 3,
		"description_template": "Increase Solar Empowered damage multiplier and extend duration.",
		"effect_value": 0,
		"archetype": "solar_ray",
		"tags": ["ability", "damage", "synergy"],
		"hero_only": ["guardian"],
		"effects": [
			{"target": "ability_manager", "property": "solar_empowered_damage_multiplier", "operation": "add", "value": 0.25},
			{"target": "ability_manager", "property": "solar_empowered_duration", "operation": "add", "value": 3.0}
		]
	},
	# ── NIGHT TACTICIAN: ATTACK UPGRADES (homing_rockets) ────────────────────────
	{
		"id": "rocket_damage",
		"title": "Warhead Payload",
		"rarity": "common",
		"weight": 0.9,
		"max_level": 5,
		"description_template": "Increase homing rocket damage by %s.",
		"effect_value": 4,
		"archetype": "rocket",
		"slot_category": "attack",
		"tags": ["weapon", "damage"],
		"hero_only": ["blaster"],
		"effects": [
			{"target": "auto_attack", "property": "attack_damage", "operation": "add", "value": 4}
		]
	},
	{
		"id": "rocket_count",
		"title": "Rocket Barrage",
		"rarity": "rare",
		"weight": 0.7,
		"max_level": 3,
		"description_template": "Fire %s additional homing rocket per volley.",
		"effect_value": 1,
		"archetype": "rocket",
		"slot_category": "attack",
		"tags": ["weapon", "multishot"],
		"hero_only": ["blaster"],
		"effects": [
			{"target": "auto_attack", "property": "projectile_count", "operation": "add", "value": 1, "max_value": 7}
		]
	},
	{
		"id": "rocket_explosion_radius",
		"title": "Blast Radius",
		"rarity": "rare",
		"weight": 0.65,
		"max_level": 4,
		"description_template": "Increase rocket explosion radius by %s.",
		"effect_value": 20.0,
		"archetype": "rocket",
		"slot_category": "attack",
		"tags": ["weapon", "area"],
		"hero_only": ["blaster"],
		"effects": [
			{"target": "auto_attack", "property": "projectile_aoe_radius", "operation": "add", "value": 20.0}
		]
	},
	{
		"id": "rocket_reload",
		"title": "Fast Reload",
		"rarity": "rare",
		"weight": 0.7,
		"max_level": 4,
		"description_template": "Reduce rocket fire interval by %ss.",
		"effect_value": 0.08,
		"archetype": "rocket",
		"slot_category": "attack",
		"tags": ["weapon", "speed"],
		"hero_only": ["blaster"],
		"effects": [
			{"target": "auto_attack", "property": "attack_interval", "operation": "subtract", "value": 0.08, "min_value": 0.25}
		]
	},
	{
		"id": "marked_target_payload",
		"title": "Marked Target Protocol",
		"rarity": "epic",
		"weight": 0.4,
		"max_level": 3,
		"description_template": "Increase bonus damage multiplier on Tactically Marked enemies by %s%%.",
		"effect_value": 10,
		"archetype": "rocket",
		"slot_category": "attack",
		"tags": ["weapon", "damage", "synergy"],
		"hero_only": ["blaster"],
		"effects": [
			{"target": "ability_manager", "property": "tactical_mark_autoattack_damage_multiplier", "operation": "add", "value": 0.10, "max_value": 2.0}
		]
	},
	# ── NIGHT TACTICIAN: ACTIVE UPGRADES (Smoke Screen) ──────────────────────────
	{
		"id": "smoke_screen_radius",
		"title": "Wide Smoke",
		"rarity": "rare",
		"weight": 0.7,
		"max_level": 4,
		"description_template": "Increase Smoke Screen radius by %s.",
		"effect_value": 40.0,
		"archetype": "smoke",
		"slot_category": "active",
		"tags": ["ability", "area"],
		"hero_only": ["blaster"],
		"effects": [
			{"target": "ability_manager", "property": "smoke_screen_radius", "operation": "add", "value": 40.0}
		]
	},
	{
		"id": "smoke_screen_duration",
		"title": "Lingering Haze",
		"rarity": "rare",
		"weight": 0.65,
		"max_level": 4,
		"description_template": "Extend Smoke Screen duration by %ss.",
		"effect_value": 1.0,
		"archetype": "smoke",
		"slot_category": "active",
		"tags": ["ability", "duration"],
		"hero_only": ["blaster"],
		"effects": [
			{"target": "ability_manager", "property": "smoke_screen_duration", "operation": "add", "value": 1.0}
		]
	},
	{
		"id": "smoke_screen_slow",
		"title": "Choking Cloud",
		"rarity": "epic",
		"weight": 0.5,
		"max_level": 3,
		"description_template": "Increase Smoke Screen slow potency by %s%%.",
		"effect_value": 10,
		"archetype": "smoke",
		"slot_category": "active",
		"tags": ["ability", "slow"],
		"hero_only": ["blaster"],
		"effects": [
			{"target": "ability_manager", "property": "smoke_screen_slow_multiplier", "operation": "subtract", "value": 0.10, "min_value": 0.10}
		]
	},
	{
		"id": "smoke_screen_damage_reduction",
		"title": "Tactical Cover",
		"rarity": "epic",
		"weight": 0.45,
		"max_level": 3,
		"description_template": "Increase damage reduction inside Smoke Screen by %s%%.",
		"effect_value": 10,
		"archetype": "smoke",
		"slot_category": "active",
		"tags": ["ability", "defense"],
		"hero_only": ["blaster"],
		"effects": [
			{"target": "ability_manager", "property": "smoke_screen_damage_reduction", "operation": "add", "value": 0.10, "max_value": 0.70}
		]
	},
	# ── NIGHT TACTICIAN: ACTIVE UPGRADES (Explosive Trap) ────────────────────────
	{
		"id": "trap_radius",
		"title": "Wide Detonation",
		"rarity": "rare",
		"weight": 0.7,
		"max_level": 4,
		"description_template": "Increase Explosive Trap blast radius by %s.",
		"effect_value": 25.0,
		"archetype": "trap",
		"slot_category": "active",
		"tags": ["ability", "area"],
		"hero_only": ["blaster"],
		"effects": [
			{"target": "ability_manager", "property": "explosive_trap_explosion_radius", "operation": "add", "value": 25.0}
		]
	},
	{
		"id": "trap_damage",
		"title": "Overcharged Warhead",
		"rarity": "rare",
		"weight": 0.65,
		"max_level": 4,
		"description_template": "Increase Explosive Trap damage by %s.",
		"effect_value": 10,
		"archetype": "trap",
		"slot_category": "active",
		"tags": ["ability", "damage"],
		"hero_only": ["blaster"],
		"effects": [
			{"target": "ability_manager", "property": "explosive_trap_damage", "operation": "add", "value": 10}
		]
	},
	{
		"id": "trap_cooldown_down",
		"title": "Fast Deployment",
		"rarity": "epic",
		"weight": 0.5,
		"max_level": 3,
		"description_template": "Reduce Explosive Trap cooldown by %ss.",
		"effect_value": 1.2,
		"archetype": "trap",
		"slot_category": "active",
		"tags": ["ability", "cooldown"],
		"hero_only": ["blaster"],
		"effects": [
			{"target": "ability_manager", "property": "explosive_trap_cooldown", "operation": "subtract", "value": 1.2, "min_value": 3.0}
		]
	},
	{
		"id": "trap_mark_bonus",
		"title": "Blast Marking",
		"rarity": "epic",
		"weight": 0.45,
		"max_level": 3,
		"description_template": "Extend Tactical Mark duration from Explosive Trap by %ss.",
		"effect_value": 1.5,
		"archetype": "trap",
		"slot_category": "active",
		"tags": ["ability", "synergy"],
		"hero_only": ["blaster"],
		"effects": [
			{"target": "ability_manager", "property": "tactical_mark_duration", "operation": "add", "value": 1.5}
		]
	},
	# ── NIGHT TACTICIAN: ACTIVE UPGRADES (Grappling Hook) ────────────────────────
	{
		"id": "hook_damage",
		"title": "Impact Strike",
		"rarity": "rare",
		"weight": 0.65,
		"max_level": 4,
		"description_template": "Increase Grappling Hook impact damage by %s.",
		"effect_value": 12,
		"archetype": "hook",
		"slot_category": "active",
		"tags": ["ability", "damage"],
		"hero_only": ["blaster"],
		"effects": [
			{"target": "ability_manager", "property": "grappling_hook_damage", "operation": "add", "value": 12}
		]
	},
	{
		"id": "hook_range",
		"title": "Extended Line",
		"rarity": "rare",
		"weight": 0.7,
		"max_level": 3,
		"description_template": "Increase Grappling Hook targeting range by %s.",
		"effect_value": 60.0,
		"archetype": "hook",
		"slot_category": "active",
		"tags": ["ability", "range"],
		"hero_only": ["blaster"],
		"effects": [
			{"target": "ability_manager", "property": "grappling_hook_range", "operation": "add", "value": 60.0}
		]
	},
	{
		"id": "hook_cooldown_down",
		"title": "Rapid Grapple",
		"rarity": "epic",
		"weight": 0.5,
		"max_level": 3,
		"description_template": "Reduce Grappling Hook cooldown by %ss.",
		"effect_value": 1.2,
		"archetype": "hook",
		"slot_category": "active",
		"tags": ["ability", "cooldown"],
		"hero_only": ["blaster"],
		"effects": [
			{"target": "ability_manager", "property": "grappling_hook_cooldown", "operation": "subtract", "value": 1.2, "min_value": 3.0}
		]
	},
	{
		"id": "hook_mark_bonus",
		"title": "Marking Strike",
		"rarity": "epic",
		"weight": 0.45,
		"max_level": 3,
		"description_template": "Extend Tactical Mark duration from Grappling Hook by %ss.",
		"effect_value": 1.5,
		"archetype": "hook",
		"slot_category": "active",
		"tags": ["ability", "synergy"],
		"hero_only": ["blaster"],
		"effects": [
			{"target": "ability_manager", "property": "tactical_mark_duration", "operation": "add", "value": 1.5}
		]
	},
	# ── FURY VANGUARD: ATTACK UPGRADES (splash_melee) ────────────────────────────
	{
		"id": "splash_melee_damage",
		"title": "Fury Strike Power",
		"rarity": "common",
		"weight": 0.8,
		"max_level": 5,
		"description_template": "Increase Fury Strike autoattack damage by %s.",
		"effect_value": 4,
		"archetype": "splash_melee",
		"slot_category": "attack",
		"tags": ["weapon", "damage"],
		"hero_only": ["vanguard"],
		"effects": [
			{"target": "auto_attack", "property": "attack_damage", "operation": "add", "value": 4}
		]
	},
	{
		"id": "splash_melee_radius",
		"title": "Wide Fury",
		"rarity": "rare",
		"weight": 0.65,
		"max_level": 4,
		"description_template": "Increase Fury Strike splash radius by %s.",
		"effect_value": 14.0,
		"archetype": "splash_melee",
		"slot_category": "attack",
		"tags": ["weapon", "aoe"],
		"hero_only": ["vanguard"],
		"effects": [
			{"target": "auto_attack", "property": "splash_melee_radius", "operation": "add", "value": 14.0}
		]
	},
	{
		"id": "splash_melee_speed",
		"title": "Fury Tempo",
		"rarity": "rare",
		"weight": 0.65,
		"max_level": 4,
		"description_template": "Reduce Fury Strike attack interval by %ss.",
		"effect_value": 0.05,
		"archetype": "splash_melee",
		"slot_category": "attack",
		"tags": ["weapon", "speed"],
		"hero_only": ["vanguard"],
		"effects": [
			{"target": "auto_attack", "property": "attack_interval", "operation": "subtract", "value": 0.05, "min_value": 0.3}
		]
	},
	{
		"id": "splash_melee_impact",
		"title": "Knockback Force",
		"rarity": "epic",
		"weight": 0.4,
		"max_level": 3,
		"description_template": "Fury Strikes knock back enemies by %s.",
		"effect_value": 80.0,
		"archetype": "splash_melee",
		"slot_category": "attack",
		"tags": ["weapon", "knockback"],
		"hero_only": ["vanguard"],
		"effects": [
			{"target": "auto_attack", "property": "splash_melee_knockback", "operation": "add", "value": 80.0}
		]
	},
	{
		"id": "splash_melee_frenzy",
		"title": "Berserker Frenzy",
		"rarity": "epic",
		"weight": 0.35,
		"max_level": 3,
		"description_template": "Gain +%s attack damage bonus per Rage unit.",
		"effect_value": 0,
		"archetype": "splash_melee",
		"slot_category": "attack",
		"tags": ["weapon", "damage", "synergy", "build_defining"],
		"is_build_defining": true,
		"hero_only": ["vanguard"],
		"prerequisites": {"archetype_points": {"splash_melee": 3}},
		"effects": [
			{"target": "ability_manager", "property": "rage_damage_multiplier_at_max", "operation": "add", "value": 0.10, "max_value": 1.95}
		]
	},
	# ── FURY VANGUARD: ACTIVE UPGRADES (Rage Wave) ───────────────────────────────
	{
		"id": "rage_wave_power",
		"title": "Wave Surge",
		"rarity": "common",
		"weight": 0.8,
		"max_level": 4,
		"description_template": "Increase Rage Wave damage by %s.",
		"effect_value": 8,
		"archetype": "rage_wave",
		"slot_category": "active",
		"tags": ["ability", "damage"],
		"hero_only": ["vanguard"],
		"effects": [
			{"target": "ability_manager", "property": "rage_wave_damage", "operation": "add", "value": 8}
		]
	},
	{
		"id": "rage_wave_radius",
		"title": "Wave Reach",
		"rarity": "rare",
		"weight": 0.6,
		"max_level": 3,
		"description_template": "Increase Rage Wave radius by %s.",
		"effect_value": 30.0,
		"archetype": "rage_wave",
		"slot_category": "active",
		"tags": ["ability", "aoe"],
		"hero_only": ["vanguard"],
		"effects": [
			{"target": "ability_manager", "property": "rage_wave_radius", "operation": "add", "value": 30.0}
		]
	},
	{
		"id": "rage_wave_cooldown",
		"title": "Wave Recovery",
		"rarity": "rare",
		"weight": 0.6,
		"max_level": 3,
		"description_template": "Reduce Rage Wave cooldown by %ss.",
		"effect_value": 0.8,
		"archetype": "rage_wave",
		"slot_category": "active",
		"tags": ["ability", "cooldown"],
		"hero_only": ["vanguard"],
		"effects": [
			{"target": "ability_manager", "property": "rage_wave_cooldown", "operation": "subtract", "value": 0.8, "min_value": 2.5}
		]
	},
	{
		"id": "rage_wave_deep_slow",
		"title": "Crushing Current",
		"rarity": "epic",
		"weight": 0.4,
		"max_level": 3,
		"description_template": "Increase Rage Wave slow duration by %ss and deepen slow.",
		"effect_value": 0.8,
		"archetype": "rage_wave",
		"slot_category": "active",
		"tags": ["ability", "slow", "synergy"],
		"hero_only": ["vanguard"],
		"effects": [
			{"target": "ability_manager", "property": "rage_wave_slow_duration", "operation": "add", "value": 0.8},
			{"target": "ability_manager", "property": "rage_wave_slow_multiplier", "operation": "subtract", "value": 0.06, "min_value": 0.20}
		]
	},
	{
		"id": "rage_wave_chain",
		"title": "Chain Wave",
		"rarity": "epic",
		"weight": 0.35,
		"max_level": 3,
		"description_template": "Rage Wave radius scales more with Rage.",
		"effect_value": 0,
		"archetype": "rage_wave",
		"slot_category": "active",
		"tags": ["ability", "synergy", "aoe", "build_defining"],
		"is_build_defining": true,
		"hero_only": ["vanguard"],
		"prerequisites": {"archetype_points": {"rage_wave": 2}},
		"effects": [
			{"target": "ability_manager", "property": "rage_wave_radius_rage_bonus", "operation": "add", "value": 0.08}
		]
	},
	# ── FURY VANGUARD: ACTIVE UPGRADES (Mighty Clap) ─────────────────────────────
	{
		"id": "mighty_clap_power",
		"title": "Clap Force",
		"rarity": "common",
		"weight": 0.8,
		"max_level": 4,
		"description_template": "Increase Mighty Clap damage by %s.",
		"effect_value": 9,
		"archetype": "mighty_clap",
		"slot_category": "active",
		"tags": ["ability", "damage"],
		"hero_only": ["vanguard"],
		"effects": [
			{"target": "ability_manager", "property": "mighty_clap_damage", "operation": "add", "value": 9}
		]
	},
	{
		"id": "mighty_clap_range",
		"title": "Wide Clap",
		"rarity": "rare",
		"weight": 0.6,
		"max_level": 3,
		"description_template": "Increase Mighty Clap cone range by %s.",
		"effect_value": 25.0,
		"archetype": "mighty_clap",
		"slot_category": "active",
		"tags": ["ability", "range"],
		"hero_only": ["vanguard"],
		"effects": [
			{"target": "ability_manager", "property": "mighty_clap_range", "operation": "add", "value": 25.0}
		]
	},
	{
		"id": "mighty_clap_cooldown",
		"title": "Clap Ready",
		"rarity": "rare",
		"weight": 0.6,
		"max_level": 3,
		"description_template": "Reduce Mighty Clap cooldown by %ss.",
		"effect_value": 1.0,
		"archetype": "mighty_clap",
		"slot_category": "active",
		"tags": ["ability", "cooldown"],
		"hero_only": ["vanguard"],
		"effects": [
			{"target": "ability_manager", "property": "mighty_clap_cooldown", "operation": "subtract", "value": 1.0, "min_value": 3.0}
		]
	},
	{
		"id": "mighty_clap_shockwave",
		"title": "Impact Wave",
		"rarity": "epic",
		"weight": 0.35,
		"max_level": 3,
		"description_template": "Mighty Clap knockback force increased by %s.",
		"effect_value": 60.0,
		"archetype": "mighty_clap",
		"slot_category": "active",
		"tags": ["ability", "knockback", "synergy", "build_defining"],
		"is_build_defining": true,
		"hero_only": ["vanguard"],
		"prerequisites": {"archetype_points": {"mighty_clap": 2}},
		"effects": [
			{"target": "ability_manager", "property": "mighty_clap_knockback_force", "operation": "add", "value": 60.0}
		]
	},
	# ── FURY VANGUARD: ACTIVE UPGRADES (Rage Leap) ───────────────────────────────
	{
		"id": "rage_leap_power",
		"title": "Leap Impact",
		"rarity": "common",
		"weight": 0.8,
		"max_level": 4,
		"description_template": "Increase Rage Leap landing damage by %s.",
		"effect_value": 10,
		"archetype": "rage_leap",
		"slot_category": "active",
		"tags": ["ability", "damage"],
		"hero_only": ["vanguard"],
		"effects": [
			{"target": "ability_manager", "property": "rage_leap_damage", "operation": "add", "value": 10}
		]
	},
	{
		"id": "rage_leap_radius",
		"title": "Wide Landing",
		"rarity": "rare",
		"weight": 0.6,
		"max_level": 3,
		"description_template": "Increase Rage Leap landing radius by %s.",
		"effect_value": 22.0,
		"archetype": "rage_leap",
		"slot_category": "active",
		"tags": ["ability", "aoe"],
		"hero_only": ["vanguard"],
		"effects": [
			{"target": "ability_manager", "property": "rage_leap_radius", "operation": "add", "value": 22.0}
		]
	},
	{
		"id": "rage_leap_cooldown",
		"title": "Leap Ready",
		"rarity": "epic",
		"weight": 0.5,
		"max_level": 3,
		"description_template": "Reduce Rage Leap cooldown by %ss.",
		"effect_value": 1.2,
		"archetype": "rage_leap",
		"slot_category": "active",
		"tags": ["ability", "cooldown"],
		"hero_only": ["vanguard"],
		"effects": [
			{"target": "ability_manager", "property": "rage_leap_cooldown", "operation": "subtract", "value": 1.2, "min_value": 3.5}
		]
	}
]


func setup(new_player: Node, new_auto_attack: Node, new_ability_manager: Node = null, new_hero_data: Dictionary = {}, new_passive_ability_manager: Node = null) -> void:
	player = new_player
	auto_attack = new_auto_attack
	ability_manager = new_ability_manager
	hero_data = new_hero_data.duplicate(true)
	passive_ability_manager = new_passive_ability_manager
	_normalize_upgrade_definitions()


func get_upgrade_options(count: int = 3) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for definition in _upgrade_definitions:
		if is_upgrade_available(str(definition.get("id", ""))):
			candidates.append(definition)

	if candidates.size() <= count:
		var all_options: Array[Dictionary] = []
		for def in candidates:
			all_options.append(_build_option(def))
		return all_options

	var options: Array[Dictionary] = []
	var dominant := get_dominant_archetype()

	# Diversity: try to ensure at least 1 off-dominant option when alternatives exist
	if not dominant.is_empty():
		var off_candidates: Array[Dictionary] = []
		for def in candidates:
			if str(def.get("archetype", "")) != dominant:
				off_candidates.append(def)

		if not off_candidates.is_empty():
			var off_pick := _pick_weighted_definition(off_candidates)
			if not off_pick.is_empty():
				options.append(_build_option(off_pick))
				candidates.erase(off_pick)

	while not candidates.is_empty() and options.size() < count:
		var selected := _pick_weighted_definition(candidates)
		if selected.is_empty():
			break
		options.append(_build_option(selected))
		candidates.erase(selected)

	return options


func apply_upgrade(upgrade_id: String) -> void:
	if not is_upgrade_available(upgrade_id):
		push_warning("Upgrade is unavailable or maxed: %s" % upgrade_id)
		return

	var definition := _get_upgrade_definition(upgrade_id)
	if definition.is_empty():
		push_warning("Unknown upgrade id: %s" % upgrade_id)
		return

	var applied := false

	if _is_passive_definition(definition):
		applied = _apply_passive_upgrade(upgrade_id)

	# Synergy upgrades with an effects array use the generic applicator
	var effects_array: Array = definition.get("effects", [])
	if not applied and not effects_array.is_empty():
		applied = _apply_effects_array(effects_array)
	elif not applied and not _is_passive_definition(definition):
		# Legacy per-upgrade application for base upgrades
		var effect_value = definition.get("effect_value", 0.0)
		match upgrade_id:
			"attack_damage_up":
				applied = _apply_auto_attack_number("attack_damage", effect_value)
			"attack_speed_up":
				applied = _apply_attack_speed_upgrade(effect_value)
			"attack_range_up":
				applied = _apply_auto_attack_number("attack_range", effect_value)
				if applied and auto_attack != null and auto_attack.has_method("refresh_attack_range"):
					auto_attack.refresh_attack_range()
			"move_speed_up":
				applied = _apply_player_number("speed", effect_value)
			"max_health_up":
				applied = _apply_max_health_upgrade(effect_value)
			"projectile_speed_up":
				applied = _apply_auto_attack_number("projectile_speed", effect_value)
			"nova_damage_up":
				applied = _apply_ability_number("nova_damage", effect_value)
			"nova_cooldown_down":
				applied = _apply_nova_cooldown_upgrade(effect_value)
			"dash_cooldown_down":
				applied = _apply_dash_cooldown_upgrade(effect_value)
			"dash_invulnerability_up":
				applied = _apply_dash_invulnerability_upgrade(effect_value)
			"projectile_pierce_up":
				applied = _apply_auto_attack_number("projectile_pierce", effect_value)
			"multishot_up":
				applied = _apply_projectile_count_upgrade(effect_value)
			"spread_up":
				applied = _apply_auto_attack_number("projectile_spread_degrees", effect_value)
			"projectile_size_up":
				applied = _apply_projectile_size_upgrade(effect_value)
			"explosive_projectiles":
				applied = _apply_explosive_projectiles_upgrade(effect_value)
			"laser_damage_up":
				applied = _apply_ability_number("laser_damage", effect_value)
			"laser_cooldown_down":
				applied = _apply_laser_cooldown_upgrade(effect_value)
			"laser_width_up":
				applied = _apply_ability_number("laser_width", effect_value)
			"slam_damage_up":
				applied = _apply_ability_number("slam_damage", effect_value)
			"slam_radius_up":
				applied = _apply_ability_number("slam_radius", effect_value)
			"slam_cooldown_down":
				applied = _apply_slam_cooldown_upgrade(effect_value)
			"heroic_endurance":
				applied = _apply_max_health_upgrade(effect_value)
			"solar_ray_damage":
				applied = _apply_auto_attack_number("attack_damage", effect_value)
			"solar_ray_range":
				applied = _apply_auto_attack_number("attack_range", effect_value)
				if applied and auto_attack != null and auto_attack.has_method("refresh_attack_range"):
					auto_attack.refresh_attack_range()
			"solar_ray_width":
				applied = _apply_auto_attack_number("solar_ray_width", effect_value)
			"solar_ray_pierce_burn":
				applied = _apply_auto_attack_number("attack_damage", effect_value)
			"death_dash_cooldown_down":
				applied = _apply_ability_number("death_dash_cooldown", -float(effect_value))
			_:
				push_warning("Unknown upgrade id: %s" % upgrade_id)

	if applied:
		_increment_upgrade_level(upgrade_id)


func get_upgrade_level(upgrade_id: String) -> int:
	return int(upgrade_levels.get(upgrade_id, 0))


func has_upgrade(upgrade_id: String, min_level: int = 1) -> bool:
	return get_upgrade_level(upgrade_id) >= min_level


func get_selected_upgrade_ids() -> Array[String]:
	var ids: Array[String] = []
	for entry in selected_upgrade_history:
		ids.append(str(entry.get("id", "")))
	return ids


func is_upgrade_available(upgrade_id: String) -> bool:
	var definition := _get_upgrade_definition(upgrade_id)
	if definition.is_empty():
		return false
	if get_upgrade_level(upgrade_id) >= int(definition.get("max_level", 1)):
		return false
	if not _meets_prerequisites(definition):
		return false
	var hero_id := str(hero_data.get("id", ""))
	var hero_only: Array = definition.get("hero_only", [])
	if not hero_only.is_empty() and not hero_only.has(hero_id):
		return false
	var hero_ids := get_upgrade_hero_ids(definition)
	if not hero_id.is_empty() and not hero_ids.is_empty() and not hero_ids.has(hero_id):
		return false
	var hero_exclude: Array = definition.get("hero_exclude", [])
	if hero_exclude.has(hero_id):
		return false
	var upgrade_line_id := get_upgrade_line_id(definition)
	if _is_selected_upgrade_line(upgrade_line_id):
		return true
	var slot_category := get_upgrade_slot_category(definition)
	if slot_category.is_empty():
		return false
	return _get_selected_slot_lines(slot_category).size() < _get_slot_category_max(slot_category)


# ── BUILD STATE ──────────────────────────────────────────────────────────────

func get_archetype_points() -> Dictionary:
	return archetype_points.duplicate()


func get_dominant_archetype() -> String:
	var best := ""
	var best_count := 0
	for arch in archetype_points:
		var count := int(archetype_points[arch])
		if count > best_count:
			best_count = count
			best = str(arch)
	return best


func get_selected_upgrade_history() -> Array:
	return selected_upgrade_history.duplicate()


func get_upgrade_definition_summary(upgrade_id: String) -> Dictionary:
	var definition := _get_upgrade_definition(upgrade_id)
	if definition.is_empty():
		return {}
	var slot_category := get_upgrade_slot_category(definition)
	return {
		"id": upgrade_id,
		"upgrade_line_id": get_upgrade_line_id(definition),
		"title": definition.get("title", ""),
		"rarity": definition.get("rarity", "common"),
		"archetype": definition.get("archetype", ""),
		"tags": definition.get("tags", []),
		"slot_category": slot_category,
		"hero_ids": get_upgrade_hero_ids(definition),
		"source_type": get_upgrade_source_type(definition),
		"source_skill_id": get_upgrade_source_skill_id(definition),
		"grid_index": get_upgrade_grid_index(definition),
		"triple_id": get_upgrade_triple_id(definition),
		"evolution_role": get_upgrade_evolution_role(definition),
		"evolution_target_active_skill": get_upgrade_evolution_target(definition),
		"max_level": definition.get("max_level", 1),
		"current_level": get_upgrade_level(upgrade_id),
		"prerequisites": definition.get("prerequisites", {})
	}


func get_upgrade_line_id(definition: Dictionary) -> String:
	return str(definition.get("upgrade_line_id", definition.get("id", "")))


func get_upgrade_slot_category(definition: Dictionary) -> String:
	return _infer_slot_category(definition, false)


func get_upgrade_hero_ids(definition: Dictionary) -> Array:
	if definition.has("hero_ids"):
		var hero_ids_value = definition.get("hero_ids", [])
		if hero_ids_value is Array:
			return (hero_ids_value as Array).duplicate()
	if definition.has("hero_id"):
		var hero_id := str(definition.get("hero_id", ""))
		return [hero_id] if not hero_id.is_empty() else []
	if definition.has("hero_only"):
		var hero_only_value = definition.get("hero_only", [])
		if hero_only_value is Array:
			return (hero_only_value as Array).duplicate()

	var ids := HERO_IDS.duplicate()
	var excluded: Array = definition.get("hero_exclude", [])
	for hero_id in excluded:
		ids.erase(str(hero_id))
	return ids


func get_upgrade_source_type(definition: Dictionary) -> String:
	var explicit := str(definition.get("source_type", ""))
	if VALID_SOURCE_TYPES.has(explicit):
		return explicit
	if _is_passive_definition(definition):
		return SOURCE_TYPE_PASSIVE
	if _definition_targets(definition, "ability_manager") or get_upgrade_slot_category(definition) == SLOT_CATEGORY_ACTIVE:
		return SOURCE_TYPE_ABILITY
	if _definition_targets(definition, "auto_attack") or get_upgrade_slot_category(definition) == SLOT_CATEGORY_ATTACK:
		return SOURCE_TYPE_AUTOATTACK
	return SOURCE_TYPE_GENERIC


func get_upgrade_source_skill_id(definition: Dictionary) -> String:
	var explicit := str(definition.get("source_skill_id", ""))
	if not explicit.is_empty():
		return explicit
	match get_upgrade_source_type(definition):
		SOURCE_TYPE_PASSIVE:
			return str(definition.get("id", ""))
		SOURCE_TYPE_ABILITY, SOURCE_TYPE_AUTOATTACK:
			var archetype := str(definition.get("archetype", ""))
			return archetype if not archetype.is_empty() else get_upgrade_line_id(definition)
	return ""


func get_upgrade_grid_index(definition: Dictionary) -> int:
	return int(definition.get("grid_index", 0))


func get_upgrade_triple_id(definition: Dictionary) -> String:
	return str(definition.get("triple_id", ""))


func get_upgrade_evolution_role(definition: Dictionary) -> String:
	return str(definition.get("evolution_role", ""))


func get_upgrade_evolution_target(definition: Dictionary) -> String:
	return str(definition.get("evolution_target_active_skill", ""))


# ── PREREQUISITE HELPERS ─────────────────────────────────────────────────────

func _meets_prerequisites(definition: Dictionary) -> bool:
	var prerequisites: Dictionary = definition.get("prerequisites", {})
	if prerequisites.is_empty():
		return true
	if prerequisites.has("any_of"):
		var any_of: Array = prerequisites["any_of"]
		var any_nested_met := false
		for nested in any_of:
			if nested is Dictionary and _meets_prerequisites({"prerequisites": nested}):
				any_nested_met = true
				break
		if not any_nested_met:
			return false

	# All listed archetype point thresholds must be met (AND)
	if prerequisites.has("archetype_points"):
		var arch_reqs: Dictionary = prerequisites["archetype_points"]
		for arch in arch_reqs:
			if _get_archetype_count(str(arch)) < int(arch_reqs[arch]):
				return false

	# All listed upgrade level thresholds must be met (AND)
	if prerequisites.has("upgrade_levels"):
		var level_reqs: Dictionary = prerequisites["upgrade_levels"]
		for upg_id in level_reqs:
			if not _has_upgrade_level(str(upg_id), int(level_reqs[upg_id])):
				return false
	if prerequisites.has("any_upgrade_levels"):
		var level_reqs: Dictionary = prerequisites["any_upgrade_levels"]
		var any_met := false
		for upg_id in level_reqs:
			if _has_upgrade_level(str(upg_id), int(level_reqs[upg_id])):
				any_met = true
				break
		if not any_met:
			return false

	# At least one of the listed archetype point thresholds must be met (OR)
	if prerequisites.has("any_archetype_points"):
		var arch_reqs: Dictionary = prerequisites["any_archetype_points"]
		var any_met := false
		for arch in arch_reqs:
			if _get_archetype_count(str(arch)) >= int(arch_reqs[arch]):
				any_met = true
				break
		if not any_met:
			return false

	return true


func _get_tag_count(tag: String) -> int:
	var count := 0
	for entry in selected_upgrade_history:
		var tags: Array = entry.get("tags", [])
		if tags.has(tag):
			count += 1
	return count


func _get_archetype_count(archetype: String) -> int:
	return int(archetype_points.get(archetype, 0))


func _has_upgrade_level(upgrade_id: String, min_level: int = 1) -> bool:
	return get_upgrade_level(upgrade_id) >= min_level


# ── DEBUG HELPERS ─────────────────────────────────────────────────────────────

func debug_get_build_state() -> Dictionary:
	var synergy_ids: Array[String] = []
	var build_defining_available: Array[String] = []
	var build_defining_selected: Array[String] = []
	for definition in _upgrade_definitions:
		var uid := str(definition.get("id", ""))
		var tags: Array = definition.get("tags", [])
		if tags.has("synergy") and get_upgrade_level(uid) > 0:
			synergy_ids.append(uid)
		if bool(definition.get("is_build_defining", false)):
			if is_upgrade_available(uid):
				build_defining_available.append(uid)
			if get_upgrade_level(uid) > 0:
				build_defining_selected.append(uid)

	return {
		"dominant_archetype": get_dominant_archetype(),
		"archetype_points": archetype_points.duplicate(),
		"selected_upgrade_history_size": selected_upgrade_history.size(),
		"available_upgrade_count": debug_get_available_upgrade_ids().size(),
		"unlocked_synergy_upgrade_ids": synergy_ids,
		"unlocked_build_defining_upgrade_ids": build_defining_available,
		"selected_build_defining_upgrade_ids": build_defining_selected,
		"slot_state": debug_get_slot_state(),
		"upgrade_grid_state": debug_get_upgrade_grid_state(),
	}


func debug_get_slot_state() -> Dictionary:
	return get_slot_state()


func get_slot_state() -> Dictionary:
	return {
		SLOT_CATEGORY_ATTACK: {
			"selected": selected_attack_lines.duplicate(),
			"used": selected_attack_lines.size(),
			"max": MAX_ATTACK_LINES,
		},
		SLOT_CATEGORY_PASSIVE: {
			"selected": selected_passive_lines.duplicate(),
			"used": selected_passive_lines.size(),
			"max": MAX_PASSIVE_LINES,
		},
		SLOT_CATEGORY_ACTIVE: {
			"selected": selected_active_lines.duplicate(),
			"used": selected_active_lines.size(),
			"max": MAX_ACTIVE_LINES,
		},
		"total_used": selected_attack_lines.size() + selected_passive_lines.size() + selected_active_lines.size(),
		"total_max": MAX_ATTACK_LINES + MAX_PASSIVE_LINES + MAX_ACTIVE_LINES,
	}


func validate_upgrade_grid(strict: bool = false) -> Dictionary:
	return _validate_upgrade_grid_for_heroes(HERO_IDS, strict)


func validate_upgrade_grid_for_hero(hero_id: String, strict: bool = false) -> Dictionary:
	return _validate_upgrade_grid_for_heroes([hero_id], strict)


func debug_get_upgrade_grid_state() -> Dictionary:
	var selected_hero_id := str(hero_data.get("id", ""))
	var audit := validate_upgrade_grid(false)
	var hero_counts: Dictionary = {}
	if not selected_hero_id.is_empty():
		hero_counts = validate_upgrade_grid_for_hero(selected_hero_id, false).get("line_counts", {}).get(selected_hero_id, {})
	return {
		"schema_warning_count": int(audit.get("warning_count", 0)),
		"schema_error_count": int(audit.get("error_count", 0)),
		"current_hero_id": selected_hero_id,
		"current_hero_line_counts": hero_counts,
		"target_counts": audit.get("target_counts", {}),
		"warnings": audit.get("warnings", []),
		"errors": audit.get("errors", []),
	}


func debug_get_available_upgrade_ids() -> Array[String]:
	var ids: Array[String] = []
	for definition in _upgrade_definitions:
		var uid := str(definition.get("id", ""))
		if is_upgrade_available(uid):
			ids.append(uid)
	return ids


func debug_print_upgrade_pool() -> void:
	print("=== UpgradeManager pool ===")
	for definition in _upgrade_definitions:
		var uid := str(definition.get("id", ""))
		var level := get_upgrade_level(uid)
		var max_level := int(definition.get("max_level", 1))
		var available := is_upgrade_available(uid)
		var prereqs_met := _meets_prerequisites(definition)
		var maxed := level >= max_level
		print("  %s | lvl %d/%d | avail=%s | prereqs=%s | maxed=%s" % [
			uid, level, max_level, available, prereqs_met, maxed
		])
	print("  archetype_points: %s" % str(archetype_points))
	print("  dominant: %s" % get_dominant_archetype())
	print("===========================")


# ── INTERNAL ─────────────────────────────────────────────────────────────────

func _normalize_upgrade_definitions() -> void:
	for definition in _upgrade_definitions:
		if not definition.has("upgrade_line_id"):
			definition["upgrade_line_id"] = str(definition.get("id", ""))
		if not definition.has("slot_category"):
			var slot_category := _infer_slot_category(definition, false)
			if not slot_category.is_empty():
				definition["slot_category"] = slot_category
		if not definition.has("source_type"):
			definition["source_type"] = get_upgrade_source_type(definition)
		if not definition.has("source_skill_id"):
			var source_skill_id := get_upgrade_source_skill_id(definition)
			if not source_skill_id.is_empty():
				definition["source_skill_id"] = source_skill_id


func _validate_upgrade_grid_for_heroes(hero_scope: Array, strict: bool) -> Dictionary:
	var errors: Array = []
	var warnings: Array = []
	var line_seen: Dictionary = {}
	var grid_seen: Dictionary = {}
	var triple_roles: Dictionary = {}
	var line_triples: Dictionary = {}
	var line_counts: Dictionary = {}
	var shared_passive_lines: Array[String] = []

	for hero_id in hero_scope:
		line_counts[str(hero_id)] = {
			SLOT_CATEGORY_ATTACK: [],
			SLOT_CATEGORY_PASSIVE: [],
			SLOT_CATEGORY_ACTIVE: [],
		}

	for definition in _upgrade_definitions:
		var upgrade_id := str(definition.get("id", ""))
		var explicit_slot_category := str(definition.get("slot_category", ""))
		var slot_category := get_upgrade_slot_category(definition)
		if explicit_slot_category.is_empty() and slot_category.is_empty():
			_record_grid_issue(errors, warnings, true, "missing_slot_category", upgrade_id, "", "", "Upgrade has no slot category and could not be inferred.")
			continue
		if not explicit_slot_category.is_empty() and not VALID_SLOT_CATEGORIES.has(explicit_slot_category):
			_record_grid_issue(errors, warnings, true, "invalid_slot_category", upgrade_id, "", explicit_slot_category, "Upgrade has an invalid slot category.")
			continue
		if slot_category.is_empty():
			continue

		var upgrade_line_id := get_upgrade_line_id(definition)
		if upgrade_line_id.is_empty():
			_record_grid_issue(errors, warnings, true, "missing_upgrade_line_id", upgrade_id, "", slot_category, "Upgrade has no upgrade_line_id or id fallback.")
			continue

		if slot_category == SLOT_CATEGORY_PASSIVE and _definition_has_hero_specific_marker(definition):
			_record_grid_issue(errors, warnings, strict, "hero_specific_passive_line", upgrade_id, "", slot_category, "Passive upgrade lines should stay shared.")

		var applicable_heroes := get_upgrade_hero_ids(definition)
		for scoped_hero_id in hero_scope:
			var hero_id := str(scoped_hero_id)
			if not applicable_heroes.is_empty() and not applicable_heroes.has(hero_id):
				continue

			var line_key := "%s|%s|%s" % [hero_id, slot_category, upgrade_line_id]
			if line_seen.has(line_key):
				_record_grid_issue(errors, warnings, true, "duplicate_upgrade_line_id", upgrade_id, hero_id, slot_category, "Duplicate upgrade_line_id '%s' in this hero/category." % upgrade_line_id)
			else:
				line_seen[line_key] = upgrade_id
				var category_lines: Array = line_counts[hero_id][slot_category]
				category_lines.append(upgrade_line_id)

			var grid_index := get_upgrade_grid_index(definition)
			if grid_index != 0:
				if grid_index < 1 or grid_index > 9:
					_record_grid_issue(errors, warnings, true, "invalid_grid_index", upgrade_id, hero_id, slot_category, "grid_index must be 1-9.")
				else:
					var grid_key := "%s|%s|%d" % [hero_id, slot_category, grid_index]
					if grid_seen.has(grid_key):
						_record_grid_issue(errors, warnings, true, "duplicate_grid_index", upgrade_id, hero_id, slot_category, "Duplicate grid_index %d in this hero/category." % grid_index)
					else:
						grid_seen[grid_key] = upgrade_id

			var triple_id := get_upgrade_triple_id(definition)
			var evolution_role := get_upgrade_evolution_role(definition)
			if not triple_id.is_empty():
				if not VALID_EVOLUTION_ROLES.has(evolution_role):
					_record_grid_issue(errors, warnings, true, "invalid_evolution_role", upgrade_id, hero_id, slot_category, "Triple member has an invalid or missing evolution_role.")
				else:
					var triple_key := "%s|%s" % [hero_id, triple_id]
					if not triple_roles.has(triple_key):
						triple_roles[triple_key] = {}
					var roles: Dictionary = triple_roles[triple_key]
					if not roles.has(evolution_role):
						roles[evolution_role] = []
					var role_lines: Array = roles[evolution_role]
					role_lines.append(upgrade_line_id)
					if role_lines.size() > 1:
						_record_grid_issue(errors, warnings, true, "duplicate_triple_role", upgrade_id, hero_id, slot_category, "Triple '%s' has more than one %s line." % [triple_id, evolution_role])

					var hero_line_key := "%s|%s" % [hero_id, upgrade_line_id]
					if not line_triples.has(hero_line_key):
						line_triples[hero_line_key] = []
					var triples: Array = line_triples[hero_line_key]
					if not triples.has(triple_id):
						triples.append(triple_id)
					if triples.size() > 1:
						_record_grid_issue(errors, warnings, true, "line_used_in_multiple_triples", upgrade_id, hero_id, slot_category, "Upgrade line '%s' is used in multiple triples." % upgrade_line_id)

					if evolution_role == EVOLUTION_ROLE_ACTIVE and get_upgrade_evolution_target(definition).is_empty():
						_record_grid_issue(errors, warnings, true, "active_triple_missing_target", upgrade_id, hero_id, slot_category, "Active triple member is missing evolution_target_active_skill.")

		if slot_category == SLOT_CATEGORY_PASSIVE and not shared_passive_lines.has(upgrade_line_id):
			shared_passive_lines.append(upgrade_line_id)

	for hero_id in hero_scope:
		var hero_key := str(hero_id)
		var counts: Dictionary = line_counts.get(hero_key, {})
		_validate_target_count(errors, warnings, strict, hero_key, SLOT_CATEGORY_ATTACK, counts.get(SLOT_CATEGORY_ATTACK, []).size(), TARGET_ATTACK_LINES_PER_HERO)
		_validate_target_count(errors, warnings, strict, hero_key, SLOT_CATEGORY_ACTIVE, counts.get(SLOT_CATEGORY_ACTIVE, []).size(), TARGET_ACTIVE_LINES_PER_HERO)

	_validate_target_count(errors, warnings, strict, "shared", SLOT_CATEGORY_PASSIVE, shared_passive_lines.size(), TARGET_SHARED_PASSIVE_LINES)

	return {
		"ok": errors.is_empty(),
		"strict": strict,
		"errors": errors,
		"warnings": warnings,
		"error_count": errors.size(),
		"warning_count": warnings.size(),
		"heroes": hero_scope.duplicate(),
		"line_counts": line_counts,
		"shared_passive_line_count": shared_passive_lines.size(),
		"target_counts": {
			SLOT_CATEGORY_ATTACK: TARGET_ATTACK_LINES_PER_HERO,
			SLOT_CATEGORY_PASSIVE: TARGET_SHARED_PASSIVE_LINES,
			SLOT_CATEGORY_ACTIVE: TARGET_ACTIVE_LINES_PER_HERO,
		},
	}


func _validate_target_count(errors: Array, warnings: Array, strict: bool, hero_id: String, slot_category: String, actual: int, target: int) -> void:
	if actual == target:
		return
	var issue_code := "target_line_count_incomplete" if actual < target else "target_line_count_exceeded"
	var message := "%s has %d/%d %s upgrade lines." % [hero_id, actual, target, slot_category]
	_record_grid_issue(errors, warnings, strict, issue_code, "", hero_id, slot_category, message)


func _record_grid_issue(errors: Array, warnings: Array, as_error: bool, code: String, upgrade_id: String, hero_id: String, slot_category: String, message: String) -> void:
	var issue := {
		"code": code,
		"upgrade_id": upgrade_id,
		"hero_id": hero_id,
		"slot_category": slot_category,
		"message": message,
	}
	if as_error:
		errors.append(issue)
	else:
		warnings.append(issue)


func _definition_has_hero_specific_marker(definition: Dictionary) -> bool:
	return definition.has("hero_id") or definition.has("hero_ids") or definition.has("hero_only")


func _increment_upgrade_level(upgrade_id: String) -> void:
	var definition := _get_upgrade_definition(upgrade_id)
	var upgrade_line_id := get_upgrade_line_id(definition)
	var was_new_line := get_upgrade_level(upgrade_id) <= 0
	if was_new_line:
		_add_selected_slot_line(upgrade_line_id, get_upgrade_slot_category(definition))

	upgrade_levels[upgrade_id] = get_upgrade_level(upgrade_id) + 1

	var archetype := str(definition.get("archetype", ""))
	if not archetype.is_empty():
		archetype_points[archetype] = int(archetype_points.get(archetype, 0)) + 1

	var slot_category := get_upgrade_slot_category(definition)
	selected_upgrade_history.append({
		"id": upgrade_id,
		"upgrade_line_id": upgrade_line_id,
		"title": str(definition.get("title", upgrade_id)),
		"archetype": archetype,
		"slot_category": slot_category,
		"tags": definition.get("tags", []),
		"level_after_pick": get_upgrade_level(upgrade_id)
	})

	build_changed.emit(get_dominant_archetype(), archetype_points.duplicate())


func _build_option(definition: Dictionary) -> Dictionary:
	var upgrade_id := str(definition.get("id", ""))
	var current_level := get_upgrade_level(upgrade_id)
	var next_level := current_level + 1
	var max_level := int(definition.get("max_level", 1))
	var tags: Array = definition.get("tags", [])
	var is_synergy := tags.has("synergy")
	var is_passive := _is_passive_definition(definition)
	var slot_category := get_upgrade_slot_category(definition)
	var selected_lines := _get_selected_slot_lines(slot_category)
	var is_new_line := not _is_selected_upgrade_line(get_upgrade_line_id(definition))

	var description: String
	var effect_text := ""
	var effects_array: Array = definition.get("effects", [])
	if is_passive or not effects_array.is_empty():
		description = str(definition.get("description_template", "Upgrade."))
	else:
		effect_text = _format_effect_value(definition.get("effect_value", 0.0))
		description = str(definition.get("description_template", "Upgrade by %s.")) % effect_text
	description = _apply_hero_flavor_to_description(upgrade_id, description, effect_text)
	description = _apply_ability_display_names_to_text(description)
	description = "%s Level %d / %d." % [description, next_level, max_level]

	return {
		"id": upgrade_id,
		"upgrade_line_id": get_upgrade_line_id(definition),
		"title": _get_flavored_upgrade_title(upgrade_id, str(definition.get("title", "Upgrade"))),
		"rarity": definition.get("rarity", "common"),
		"archetype": definition.get("archetype", ""),
		"tags": tags,
		"type": definition.get("type", definition.get("category", "")),
		"slot_category": slot_category,
		"is_new_line": is_new_line,
		"category_slots_used": selected_lines.size(),
		"category_slots_max": _get_slot_category_max(slot_category),
		"level": current_level,
		"max_level": max_level,
		"description": description,
		"is_passive": is_passive,
		"is_synergy": is_synergy,
		"is_build_defining": bool(definition.get("is_build_defining", false))
	}


func _is_passive_definition(definition: Dictionary) -> bool:
	var tags: Array = definition.get("tags", [])
	return str(definition.get("type", definition.get("category", ""))) == "passive" or tags.has("passive")


func _get_slot_category(definition: Dictionary) -> String:
	return get_upgrade_slot_category(definition)


func _infer_slot_category(definition: Dictionary, warn_on_missing: bool = true) -> String:
	var explicit := str(definition.get("slot_category", ""))
	if VALID_SLOT_CATEGORIES.has(explicit):
		return explicit

	var tags: Array = definition.get("tags", [])
	var archetype := str(definition.get("archetype", ""))
	if _is_passive_definition(definition):
		return SLOT_CATEGORY_PASSIVE
	if tags.has("weapon") or tags.has("projectile") or tags.has("primary") or _definition_targets(definition, "auto_attack"):
		return SLOT_CATEGORY_ATTACK
	if tags.has("ability") or ["nova", "laser", "slam"].has(archetype) or _definition_targets(definition, "ability_manager"):
		return SLOT_CATEGORY_ACTIVE
	if tags.has("defense") or tags.has("mobility") or tags.has("utility") or tags.has("pickup") or ["dash", "tank", "speed", "utility"].has(archetype):
		return SLOT_CATEGORY_PASSIVE

	if warn_on_missing:
		push_warning("UpgradeManager: upgrade '%s' has no slot category." % str(definition.get("id", "")))
	return ""


func _definition_targets(definition: Dictionary, target_id: String) -> bool:
	var effects: Array = definition.get("effects", [])
	for effect in effects:
		if effect is Dictionary and str(effect.get("target", "")) == target_id:
			return true
	return false


func _is_selected_upgrade_line(upgrade_line_id: String) -> bool:
	return selected_attack_lines.has(upgrade_line_id) or selected_passive_lines.has(upgrade_line_id) or selected_active_lines.has(upgrade_line_id)


func _add_selected_slot_line(upgrade_id: String, slot_category: String) -> void:
	var lines := _get_selected_slot_lines(slot_category)
	if lines.has(upgrade_id):
		return
	lines.append(upgrade_id)


func _get_selected_slot_lines(slot_category: String) -> Array[String]:
	match slot_category:
		SLOT_CATEGORY_ATTACK:
			return selected_attack_lines
		SLOT_CATEGORY_PASSIVE:
			return selected_passive_lines
		SLOT_CATEGORY_ACTIVE:
			return selected_active_lines
	return []


func _get_slot_category_max(slot_category: String) -> int:
	match slot_category:
		SLOT_CATEGORY_ATTACK:
			return MAX_ATTACK_LINES
		SLOT_CATEGORY_PASSIVE:
			return MAX_PASSIVE_LINES
		SLOT_CATEGORY_ACTIVE:
			return MAX_ACTIVE_LINES
	return 0


func _apply_passive_upgrade(upgrade_id: String) -> bool:
	if passive_ability_manager == null:
		push_warning("UpgradeManager is missing PassiveAbilityManager reference.")
		return false
	if not passive_ability_manager.has_method("add_or_upgrade_passive"):
		push_warning("PassiveAbilityManager does not implement add_or_upgrade_passive(passive_id).")
		return false
	passive_ability_manager.add_or_upgrade_passive(upgrade_id)
	return true


func _apply_ability_display_names_to_text(text: String) -> String:
	if ability_manager == null or not ability_manager.has_method("get_ability_name"):
		return text
	var result := text
	result = result.replace("Nova Pulse", str(ability_manager.get_ability_name(1)))
	result = result.replace("Laser Beam", str(ability_manager.get_ability_name(2)))
	result = result.replace("Hero Slam", str(ability_manager.get_ability_name(3)))
	return result


func _get_flavored_upgrade_title(upgrade_id: String, fallback: String) -> String:
	var flavor: Dictionary = _get_hero_upgrade_flavor()
	var titles: Dictionary = flavor.get("titles", {})
	return str(titles.get(upgrade_id, fallback))


func _apply_hero_flavor_to_description(upgrade_id: String, fallback: String, effect_text: String) -> String:
	var flavor: Dictionary = _get_hero_upgrade_flavor()
	var descriptions: Dictionary = flavor.get("descriptions", {})
	if not descriptions.has(upgrade_id):
		return fallback
	var text: String = str(descriptions.get(upgrade_id, fallback))
	if text.find("%s") != -1:
		return text % effect_text
	return text


func _get_hero_upgrade_flavor() -> Dictionary:
	var selected_hero_id: String = str(hero_data.get("id", ""))
	return HERO_UPGRADE_FLAVOR.get(selected_hero_id, {})


func _pick_weighted_definition(candidates: Array[Dictionary]) -> Dictionary:
	var total_weight := 0.0
	for definition in candidates:
		total_weight += _get_effective_weight(definition)

	if total_weight <= 0.0:
		return candidates.pick_random() if not candidates.is_empty() else {}

	var roll := randf() * total_weight
	var cursor := 0.0
	for definition in candidates:
		cursor += _get_effective_weight(definition)
		if roll <= cursor:
			return definition

	return candidates.back() if not candidates.is_empty() else {}


func _get_effective_weight(definition: Dictionary) -> float:
	var base_weight := maxf(float(definition.get("weight", 1.0)), 0.0)
	var archetype := str(definition.get("archetype", ""))
	if archetype.is_empty():
		return base_weight
	var points := _get_archetype_count(archetype)
	var bias := 1.0 + minf(float(points) * 0.12, 0.6)
	return base_weight * bias


func _get_upgrade_definition(upgrade_id: String) -> Dictionary:
	for definition in _upgrade_definitions:
		if str(definition.get("id", "")) == upgrade_id:
			return definition
	return {}


func _format_effect_value(value) -> String:
	if value is int:
		return str(value)
	var number := float(value)
	if is_equal_approx(number, roundf(number)):
		return str(int(roundf(number)))
	return "%.2f" % number if number < 0.1 else "%.1f" % number


# ── EFFECTS ARRAY APPLICATOR ─────────────────────────────────────────────────

func _apply_effects_array(effects: Array) -> bool:
	var any_applied := false
	for effect in effects:
		var target_id := str(effect.get("target", ""))
		var property := str(effect.get("property", ""))
		var operation := str(effect.get("operation", "add"))
		var value = effect.get("value", 0.0)
		var min_value = effect.get("min_value", null)
		var max_value = effect.get("max_value", null)

		var target_node: Node = null
		match target_id:
			"player":
				target_node = player
			"auto_attack":
				target_node = auto_attack
			"ability_manager":
				target_node = ability_manager

		if target_node == null:
			push_warning("UpgradeManager: target '%s' is not set." % target_id)
			return false

		var current = target_node.get(property)
		if current == null:
			push_warning("UpgradeManager: property '%s' not found on %s." % [property, target_id])
			return false

		if current is bool:
			if operation != "set":
				push_warning("UpgradeManager: bool property '%s' requires operation 'set'." % property)
				return false
			target_node.set(property, bool(value))
		elif current is int:
			var int_val: int = int(current)
			match operation:
				"add":      int_val += int(value)
				"subtract": int_val -= int(value)
				"multiply": int_val = int(float(current) * float(value))
				"set":      int_val = int(value)
				_:
					push_warning("UpgradeManager: unsupported operation '%s'." % operation)
					return false
			if max_value != null:
				int_val = mini(int_val, int(max_value))
			if min_value != null:
				int_val = maxi(int_val, int(min_value))
			target_node.set(property, int_val)
		else:
			var float_val: float = float(current)
			match operation:
				"add":      float_val += float(value)
				"subtract": float_val -= float(value)
				"multiply": float_val *= float(value)
				"set":      float_val = float(value)
				_:
					push_warning("UpgradeManager: unsupported operation '%s'." % operation)
					return false
			if max_value != null:
				float_val = minf(float_val, float(max_value))
			if min_value != null:
				float_val = maxf(float_val, float(min_value))
			target_node.set(property, float_val)

		any_applied = true

	return any_applied


# ── TARGET-SPECIFIC HELPERS ───────────────────────────────────────────────────

func _apply_auto_attack_number(property_name: String, amount) -> bool:
	if auto_attack == null:
		push_warning("UpgradeManager is missing AutoAttack reference.")
		return false
	var value = auto_attack.get(property_name)
	if value == null:
		push_warning("AutoAttack is missing property: %s" % property_name)
		return false
	auto_attack.set(property_name, value + amount)
	return true


func _apply_player_number(property_name: String, amount) -> bool:
	if player == null:
		push_warning("UpgradeManager is missing Player reference.")
		return false
	var value = player.get(property_name)
	if value == null:
		push_warning("Player is missing property: %s" % property_name)
		return false
	player.set(property_name, value + amount)
	return true


func _apply_ability_number(property_name: String, amount) -> bool:
	if ability_manager == null:
		push_warning("UpgradeManager is missing AbilityManager reference.")
		return false
	var value = ability_manager.get(property_name)
	if value == null:
		push_warning("AbilityManager is missing property: %s" % property_name)
		return false
	ability_manager.set(property_name, value + amount)
	return true


func _apply_attack_speed_upgrade(amount) -> bool:
	if auto_attack == null:
		push_warning("UpgradeManager is missing AutoAttack reference.")
		return false
	var value = auto_attack.get("attack_interval")
	if value == null:
		push_warning("AutoAttack is missing attack_interval.")
		return false
	auto_attack.set("attack_interval", maxf(ATTACK_INTERVAL_MIN, value - float(amount)))
	return true


func _apply_nova_cooldown_upgrade(amount) -> bool:
	if ability_manager == null:
		push_warning("UpgradeManager is missing AbilityManager reference.")
		return false
	var value = ability_manager.get("nova_cooldown")
	if value == null:
		push_warning("AbilityManager is missing nova_cooldown.")
		return false
	ability_manager.set("nova_cooldown", maxf(NOVA_COOLDOWN_MIN, value - float(amount)))
	return true


func _apply_laser_cooldown_upgrade(amount) -> bool:
	if ability_manager == null:
		push_warning("UpgradeManager is missing AbilityManager reference.")
		return false
	var value = ability_manager.get("laser_cooldown")
	if value == null:
		push_warning("AbilityManager is missing laser_cooldown.")
		return false
	ability_manager.set("laser_cooldown", maxf(LASER_COOLDOWN_MIN, value - float(amount)))
	return true


func _apply_slam_cooldown_upgrade(amount) -> bool:
	if ability_manager == null:
		push_warning("UpgradeManager is missing AbilityManager reference.")
		return false
	var value = ability_manager.get("slam_cooldown")
	if value == null:
		push_warning("AbilityManager is missing slam_cooldown.")
		return false
	ability_manager.set("slam_cooldown", maxf(SLAM_COOLDOWN_MIN, value - float(amount)))
	return true


func _apply_dash_cooldown_upgrade(amount) -> bool:
	if player == null:
		push_warning("UpgradeManager is missing Player reference.")
		return false
	var value = player.get("dash_cooldown")
	if value == null:
		push_warning("Player is missing dash_cooldown.")
		return false
	player.set("dash_cooldown", maxf(DASH_COOLDOWN_MIN, value - float(amount)))
	return true


func _apply_dash_invulnerability_upgrade(amount) -> bool:
	if player == null:
		push_warning("UpgradeManager is missing Player reference.")
		return false
	var value = player.get("dash_invulnerability_duration")
	if value == null:
		push_warning("Player is missing dash_invulnerability_duration.")
		return false
	player.set("dash_invulnerability_duration", minf(DASH_INVULNERABILITY_MAX, value + float(amount)))
	return true


func _apply_projectile_count_upgrade(amount) -> bool:
	if auto_attack == null:
		push_warning("UpgradeManager is missing AutoAttack reference.")
		return false
	var value = auto_attack.get("projectile_count")
	if value == null:
		push_warning("AutoAttack is missing projectile_count.")
		return false
	auto_attack.set("projectile_count", mini(PROJECTILE_COUNT_MAX, int(value) + int(amount)))
	return true


func _apply_projectile_size_upgrade(amount) -> bool:
	if auto_attack == null:
		push_warning("UpgradeManager is missing AutoAttack reference.")
		return false
	var value = auto_attack.get("projectile_size_multiplier")
	if value == null:
		push_warning("AutoAttack is missing projectile_size_multiplier.")
		return false
	auto_attack.set("projectile_size_multiplier", minf(PROJECTILE_SIZE_MAX, value + float(amount)))
	return true


func _apply_explosive_projectiles_upgrade(amount) -> bool:
	if auto_attack == null:
		push_warning("UpgradeManager is missing AutoAttack reference.")
		return false
	var value = auto_attack.get("projectile_explosion_radius")
	if value == null:
		push_warning("AutoAttack is missing projectile_explosion_radius.")
		return false
	auto_attack.set("projectile_explosion_radius", minf(PROJECTILE_EXPLOSION_RADIUS_MAX, value + float(amount)))
	return true


func _apply_max_health_upgrade(amount) -> bool:
	if player == null:
		push_warning("UpgradeManager is missing Player reference.")
		return false
	var max_health = player.get("max_health")
	var current_health = player.get("current_health")
	if max_health == null or current_health == null:
		push_warning("Player is missing health properties.")
		return false
	var health_increase := int(amount)
	player.set("max_health", max_health + health_increase)
	player.set("current_health", min(current_health + health_increase, player.get("max_health")))
	if player.has_signal("health_changed"):
		player.health_changed.emit(player.get("current_health"), player.get("max_health"))
	return true
