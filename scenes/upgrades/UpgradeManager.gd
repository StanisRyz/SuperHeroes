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

const HERO_UPGRADE_FLAVOR := {
	"guardian": {
		"titles": {
			"attack_damage_up": "Radiant Strike",
			"attack_speed_up": "Solar Tempo",
			"attack_range_up": "Skyline Reach",
			"move_speed_up": "Aerial Momentum",
			"max_health_up": "Solar Fortitude",
			"projectile_speed_up": "Sunshot Velocity",
			"nova_damage_up": "Solar Burst Surge",
			"nova_cooldown_down": "Radiant Rhythm",
			"laser_damage_up": "Solar Beam Focus",
			"laser_cooldown_down": "Solar Beam Charge",
			"laser_width_up": "Wide Sunray",
			"slam_damage_up": "Aerial Impact Force",
			"slam_radius_up": "Impact Halo",
			"slam_cooldown_down": "Skyfall Ready",
			"shielded_dash": "Dawn Guard Dash",
			"heroic_endurance": "Solar Endurance",
			"power_collector": "Sunlit Collector",
			"nova_aftershock": "Radiant Aftershock",
			"laser_overcharge": "Solar Overcharge",
			"slam_quake": "Aerial Quake",
			"nova_aftershock_zone": "Radiant Aftershock Zone",
			"laser_double_pulse": "Twin Sunray",
			"slam_second_wave": "Second Impact",
			"dash_damage_trail": "Comet Guard",
			"bouncing_bolts": "Ricochet Rays",
		},
		"descriptions": {
			"attack_damage_up": "Increase radiant autoattack damage by %s.",
			"attack_speed_up": "Reduce radiant autoattack interval by %ss.",
			"attack_range_up": "Increase skyward autoattack targeting range by %s.",
			"move_speed_up": "Increase aerial movement speed by %s.",
			"max_health_up": "Increase solar durability and heal by %s.",
			"projectile_speed_up": "Increase speed of newly fired sunshots by %s.",
			"shielded_dash": "Extend guarded dash invulnerability and trim dash cooldown.",
			"heroic_endurance": "Increase solar max health by %s and restore HP.",
			"power_collector": "Increase movement speed for better radiant pickup reach.",
		},
	},
	"blaster": {
		"titles": {
			"attack_damage_up": "Precision Dart",
			"attack_speed_up": "Tactical Tempo",
			"attack_range_up": "Optic Rangefinder",
			"move_speed_up": "Shadow Step",
			"max_health_up": "Armored Lining",
			"projectile_speed_up": "Quick-Fire Gadget",
			"nova_damage_up": "Smoke Charge Payload",
			"nova_cooldown_down": "Smoke Charge Reset",
			"laser_damage_up": "Grapnel Shot Focus",
			"laser_cooldown_down": "Grapnel Reload",
			"laser_width_up": "Wide Grapnel Arc",
			"slam_damage_up": "Shock Trap Charge",
			"slam_radius_up": "Trap Field",
			"slam_cooldown_down": "Trap Reset",
			"shielded_dash": "Evasive Guard",
			"heroic_endurance": "Reinforced Kit",
			"power_collector": "Utility Sweep",
			"nova_aftershock": "Smoke Aftercharge",
			"laser_overcharge": "Grapnel Overdrive",
			"slam_quake": "Shock Trap Array",
			"nova_aftershock_zone": "Lingering Smoke",
			"laser_double_pulse": "Follow-Up Grapnel",
			"slam_second_wave": "Delayed Trap",
			"dash_damage_trail": "Tactical Exit",
			"bouncing_bolts": "Ricochet Tools",
		},
		"descriptions": {
			"attack_damage_up": "Increase precision autoattack damage by %s.",
			"attack_speed_up": "Reduce tactical autoattack interval by %ss.",
			"attack_range_up": "Increase targeting range by %s.",
			"move_speed_up": "Increase tactical movement speed by %s.",
			"max_health_up": "Increase armor reserves and heal by %s.",
			"projectile_speed_up": "Increase speed of newly fired gadgets by %s.",
			"shielded_dash": "Extend evasive invulnerability and trim dash cooldown.",
			"heroic_endurance": "Increase reinforced max health by %s and restore HP.",
			"power_collector": "Increase movement speed for cleaner pickup routes.",
		},
	},
	"vanguard": {
		"titles": {
			"attack_damage_up": "Bruiser Blow",
			"attack_speed_up": "Fury Tempo",
			"attack_range_up": "Long Swing",
			"move_speed_up": "Heavy Charge",
			"max_health_up": "Thick Hide",
			"projectile_speed_up": "Thrown Force",
			"nova_damage_up": "Rage Burst Power",
			"nova_cooldown_down": "Rage Recovery",
			"laser_damage_up": "Crushing Leap Force",
			"laser_cooldown_down": "Leap Recovery",
			"laser_width_up": "Broad Leap",
			"slam_damage_up": "Titan Slam Force",
			"slam_radius_up": "Rupture Ring",
			"slam_cooldown_down": "Slam Ready",
			"shielded_dash": "Braced Charge",
			"heroic_endurance": "Bruiser Endurance",
			"power_collector": "Power Rush",
			"nova_aftershock": "Rage Aftershock",
			"laser_overcharge": "Crushing Overdrive",
			"slam_quake": "Titan Quake",
			"nova_aftershock_zone": "Fury Aftershock",
			"laser_double_pulse": "Follow-Up Leap",
			"slam_second_wave": "Second Smash",
			"dash_damage_trail": "Rampage Dash",
			"bouncing_bolts": "Rebounding Force",
		},
		"descriptions": {
			"attack_damage_up": "Increase bruiser autoattack damage by %s.",
			"attack_speed_up": "Reduce heavy autoattack interval by %ss.",
			"attack_range_up": "Increase close-pressure targeting range by %s.",
			"move_speed_up": "Increase charging movement speed by %s.",
			"max_health_up": "Increase bruiser durability and heal by %s.",
			"projectile_speed_up": "Increase speed of newly hurled force by %s.",
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
		"tags": ["weapon", "speed"]
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
		"tags": ["passive", "pickup", "magnet"]
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
		"tags": ["ability", "damage", "aoe"]
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
		"tags": ["ability", "cooldown"]
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
		"tags": ["weapon", "pierce"]
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
		"tags": ["weapon", "projectile_count"]
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
		"tags": ["weapon", "spread"]
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
		"tags": ["weapon", "size"]
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
		"tags": ["weapon", "explosion"]
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
		"tags": ["ability", "damage"]
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
		"tags": ["ability", "cooldown"]
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
		"tags": ["ability", "area"]
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
		"tags": ["ability", "damage"]
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
		"tags": ["ability", "aoe"]
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
		"tags": ["ability", "cooldown"]
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
		"prerequisites": {
			"archetype_points": {"projectile": 3},
			"any_upgrade_levels": {"projectile_pierce_up": 1, "multishot_up": 1}
		},
		"effects": [
			{"target": "auto_attack", "property": "projectile_bounce", "operation": "add", "value": 1, "max_value": 5}
		]
	}
]


func setup(new_player: Node, new_auto_attack: Node, new_ability_manager: Node = null, new_hero_data: Dictionary = {}, new_passive_ability_manager: Node = null) -> void:
	player = new_player
	auto_attack = new_auto_attack
	ability_manager = new_ability_manager
	hero_data = new_hero_data.duplicate(true)
	passive_ability_manager = new_passive_ability_manager


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
	return _meets_prerequisites(definition)


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
	return {
		"id": upgrade_id,
		"title": definition.get("title", ""),
		"rarity": definition.get("rarity", "common"),
		"archetype": definition.get("archetype", ""),
		"tags": definition.get("tags", []),
		"max_level": definition.get("max_level", 1),
		"current_level": get_upgrade_level(upgrade_id),
		"prerequisites": definition.get("prerequisites", {})
	}


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

func _increment_upgrade_level(upgrade_id: String) -> void:
	upgrade_levels[upgrade_id] = get_upgrade_level(upgrade_id) + 1

	var definition := _get_upgrade_definition(upgrade_id)
	var archetype := str(definition.get("archetype", ""))
	if not archetype.is_empty():
		archetype_points[archetype] = int(archetype_points.get(archetype, 0)) + 1

	selected_upgrade_history.append({
		"id": upgrade_id,
		"title": str(definition.get("title", upgrade_id)),
		"archetype": archetype,
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
		"title": _get_flavored_upgrade_title(upgrade_id, str(definition.get("title", "Upgrade"))),
		"rarity": definition.get("rarity", "common"),
		"archetype": definition.get("archetype", ""),
		"tags": tags,
		"type": definition.get("type", definition.get("category", "")),
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
