extends Node

signal evolution_available(evolution_data: Dictionary)
signal evolution_applied(evolution_id: String, evolution_data: Dictionary)
signal evolution_state_changed

@export var elite_reward_chance: float = 0.0

var player: Node
var auto_attack: Node
var ability_manager: Node
var passive_ability_manager: Node
var upgrade_manager: Node

var _hero_data: Dictionary = {}
var _selected_evolutions: Array[String] = []

const TRIPLE_STATE_LOCKED := "locked"
const TRIPLE_STATE_PARTIAL := "partial"
const TRIPLE_STATE_COLLECTED := "collected"
const TRIPLE_STATE_READY := "ready"
const TRIPLE_STATE_SELECTED := "selected"

const EVOLUTION_TARGET_ATTACK := "attack"
const EVOLUTION_TARGET_ACTIVE := "active"
const EVOLUTION_TARGET_PASSIVE := "passive"
const VALID_EVOLUTION_TARGET_TYPES := [EVOLUTION_TARGET_ATTACK, EVOLUTION_TARGET_ACTIVE, EVOLUTION_TARGET_PASSIVE]
const EFFECT_STATUS_IMPLEMENTED := "implemented"
const EFFECT_STATUS_PLACEHOLDER := "placeholder"

# Triple definitions: each triple binds 1 attack line + 1 passive line + 1 active line
# into an evolution candidate for a specific active skill.
# 9 triples per hero. Each line is used exactly once per hero.
# required_levels: {} means use each upgrade's own max_level automatically.
var _triple_definitions: Array[Dictionary] = [
	# ── SOLAR GUARDIAN TRIPLES ──────────────────────────────────────────────────
	# Solar Beam evolutions (attack grids 1-3, passive grids 1-3, active grids 1-3)
	{
		"triple_id": "guardian_solar_cataclysm",
		"hero_id": "guardian",
		"grid_index": 1,
		"attack_line_id": "solar_ray_damage",
		"passive_line_id": "orbit_shields",
		"active_line_id": "solar_beam_damage_up",
		"target_active_skill_id": "solar_beam",
		"target_type": "active",
		"target_id": "solar_beam",
		"effect_status": "implemented",
		"evolution_id": "solar_beam_cataclysm",
		"title": "Solar Cataclysm",
		"description": "Transforms Solar Beam into a devastating red cataclysm. 3x damage, wider beam, leaves a burning pulse.",
		"required_levels": {},
	},
	{
		"triple_id": "guardian_sky_lance",
		"hero_id": "guardian",
		"grid_index": 2,
		"attack_line_id": "solar_ray_range",
		"passive_line_id": "storm_relay",
		"active_line_id": "solar_beam_range_up",
		"target_type": "attack",
		"target_id": "solar_ray",
		"effect_status": "implemented",
		"evolution_id": "solar_beam_sky_lance",
		"title": "Sky Lance",
		"description": "Solar Ray becomes a huge red lance with much longer range, wider corridor hits, and heavier visual presence.",
		"required_levels": {},
	},
	{
		"triple_id": "guardian_burning_judgment",
		"hero_id": "guardian",
		"grid_index": 3,
		"attack_line_id": "solar_ray_pierce_burn",
		"passive_line_id": "chain_lightning",
		"active_line_id": "solar_beam_overheat",
		"target_type": "attack",
		"target_id": "solar_ray",
		"effect_status": "implemented",
		"evolution_id": "solar_beam_burning_judgment",
		"title": "Burning Judgment",
		"description": "Solar Ray applies strong burning judgment damage after hits; Solar Empowered doubles the heat pulses.",
		"required_levels": {},
	},
	# Frost Breath evolutions (attack grids 4-6, passive grids 4-6, active grids 4-6)
	{
		"triple_id": "guardian_absolute_zero",
		"hero_id": "guardian",
		"grid_index": 4,
		"attack_line_id": "solar_ray_width",
		"passive_line_id": "time_dilator",
		"active_line_id": "frost_breath_power",
		"target_active_skill_id": "frost_breath",
		"target_type": "active",
		"target_id": "frost_breath",
		"effect_status": "implemented",
		"evolution_id": "frost_breath_absolute_zero",
		"title": "Absolute Zero",
		"description": "Transforms Frost Breath into absolute zero. Much wider cone, near-freezes all enemies hit.",
		"required_levels": {},
	},
	{
		"triple_id": "guardian_glacier_front",
		"hero_id": "guardian",
		"grid_index": 5,
		"attack_line_id": "solar_ray_tick_rate",
		"passive_line_id": "static_field",
		"active_line_id": "frost_breath_cone_up",
		"target_type": "attack",
		"target_id": "solar_ray",
		"effect_status": "implemented",
		"evolution_id": "frost_breath_glacier_front",
		"title": "Solar Glacier Front",
		"description": "Solar Ray creates a delayed radiant line pulse after firing. This evolves Solar Ray despite the legacy frost-themed id.",
		"required_levels": {},
	},
	{
		"triple_id": "guardian_permafrost",
		"hero_id": "guardian",
		"grid_index": 6,
		"attack_line_id": "solar_ray_empowered_bonus",
		"passive_line_id": "recovery_field",
		"active_line_id": "frost_breath_freeze",
		"target_type": "passive",
		"target_id": "orbit_shields",
		"effect_status": "implemented",
		"evolution_id": "frost_breath_permafrost",
		"title": "Solar Aegis",
		"description": "Orbit Shields gain stronger charges and faster regeneration; consumed shields explode in solar AoE.",
		"required_levels": {},
	},
	# Death Dash evolutions (attack grids 7-9, passive grids 7-9, active grids 7-9)
	{
		"triple_id": "guardian_solar_execution",
		"hero_id": "guardian",
		"grid_index": 7,
		"attack_line_id": "solar_ray_lingering_heat",
		"passive_line_id": "guardian_drone",
		"active_line_id": "death_dash_power",
		"target_active_skill_id": "death_dash",
		"target_type": "active",
		"target_id": "death_dash",
		"effect_status": "implemented",
		"evolution_id": "death_dash_solar_execution",
		"title": "Final Flash",
		"description": "Transforms Death Dash into a long execution dash with low-health bonus damage and a solar flash pulse.",
		"required_levels": {},
	},
	{
		"triple_id": "guardian_comet_path",
		"hero_id": "guardian",
		"grid_index": 8,
		"attack_line_id": "solar_ray_focus",
		"passive_line_id": "magnet_core",
		"active_line_id": "death_dash_distance",
		"target_type": "passive",
		"target_id": "storm_relay",
		"effect_status": "implemented",
		"evolution_id": "death_dash_comet_path",
		"title": "Solar Storm",
		"description": "Storm Relay becomes a frequent multi-target solar lightning storm, stronger during Solar Empowered.",
		"required_levels": {},
	},
	{
		"triple_id": "guardian_final_flash",
		"hero_id": "guardian",
		"grid_index": 9,
		"attack_line_id": "solar_ray_execution",
		"passive_line_id": "battle_focus",
		"active_line_id": "death_dash_cooldown_down",
		"target_type": "passive",
		"target_id": "recovery_field",
		"effect_status": "implemented",
		"evolution_id": "death_dash_final_flash",
		"title": "Radiant Renewal",
		"description": "Recovery Field heals harder, emits a damaging radiant pulse, and grants brief damage reduction.",
		"required_levels": {},
	},
	# ── NIGHT TACTICIAN TRIPLES ──────────────────────────────────────────────────
	# Smoke Screen evolutions (attack grids 1-3, passive grids 1-3, active grids 1-3)
	{
		"triple_id": "blaster_blackout",
		"hero_id": "blaster",
		"grid_index": 1,
		"attack_line_id": "rocket_damage",
		"passive_line_id": "orbit_shields",
		"active_line_id": "smoke_screen_radius",
		"target_active_skill_id": "smoke_screen",
		"target_type": "active",
		"target_id": "smoke_screen",
		"effect_status": "implemented",
		"evolution_id": "smoke_screen_blackout",
		"title": "Blackout",
		"description": "Transforms Smoke Screen into a huge blackout field with longer uptime, stronger slow/marks, and heavier damage reduction.",
		"required_levels": {},
	},
	{
		"triple_id": "blaster_tactical_cover",
		"hero_id": "blaster",
		"grid_index": 2,
		"attack_line_id": "rocket_count",
		"passive_line_id": "storm_relay",
		"active_line_id": "smoke_screen_duration",
		"target_type": "attack",
		"target_id": "homing_rockets",
		"effect_status": "implemented",
		"evolution_id": "smoke_screen_tactical_cover",
		"title": "Tactical Cover",
		"description": "Homing Rockets call in extra support rockets that spread cover fire across available targets.",
		"required_levels": {},
	},
	{
		"triple_id": "blaster_choking_zone",
		"hero_id": "blaster",
		"grid_index": 3,
		"attack_line_id": "rocket_reload",
		"passive_line_id": "time_dilator",
		"active_line_id": "smoke_screen_slow",
		"target_type": "attack",
		"target_id": "homing_rockets",
		"effect_status": "implemented",
		"evolution_id": "smoke_screen_choking_zone",
		"title": "Choking Zone",
		"description": "Homing Rocket impacts leave choking smoke bursts that slow and tactically mark nearby enemies.",
		"required_levels": {},
	},
	# Explosive Trap evolutions (attack grids 4-6, passive grids 4-6, active grids 4-6)
	{
		"triple_id": "blaster_chain_detonation",
		"hero_id": "blaster",
		"grid_index": 4,
		"attack_line_id": "rocket_explosion_radius",
		"passive_line_id": "static_field",
		"active_line_id": "trap_damage",
		"target_active_skill_id": "explosive_trap",
		"target_type": "active",
		"target_id": "explosive_trap",
		"effect_status": "implemented",
		"evolution_id": "trap_chain_detonation_evolution",
		"title": "Chain Detonation",
		"description": "Transforms Explosive Trap into cascading detonations. Chain blast pulses + Tactical Mark in wide radius.",
		"required_levels": {},
	},
	{
		"triple_id": "blaster_cluster_minefield",
		"hero_id": "blaster",
		"grid_index": 5,
		"attack_line_id": "rocket_cluster_payload",
		"passive_line_id": "chain_lightning",
		"active_line_id": "trap_radius",
		"target_type": "attack",
		"target_id": "homing_rockets",
		"effect_status": "implemented",
		"evolution_id": "trap_cluster_minefield",
		"title": "Cluster Minefield",
		"description": "Homing Rocket impacts split into clustered secondary explosions for a large, safe AoE burst.",
		"required_levels": {},
	},
	{
		"triple_id": "blaster_marked_blast",
		"hero_id": "blaster",
		"grid_index": 6,
		"attack_line_id": "marked_target_payload",
		"passive_line_id": "guardian_drone",
		"active_line_id": "trap_chain_detonation",
		"target_type": "passive",
		"target_id": "guardian_drone",
		"effect_status": "implemented",
		"evolution_id": "trap_marked_blast",
		"title": "Tactical Drone Swarm",
		"description": "Guardian Drone becomes a multi-shot tactical swarm that marks enemies while firing.",
		"required_levels": {},
	},
	# Grappling Hook evolutions (attack grids 7-9, passive grids 7-9, active grids 7-9)
	{
		"triple_id": "blaster_execution_pull",
		"hero_id": "blaster",
		"grid_index": 7,
		"attack_line_id": "rocket_seek_range",
		"passive_line_id": "magnet_core",
		"active_line_id": "hook_damage",
		"target_active_skill_id": "grappling_hook",
		"target_type": "active",
		"target_id": "grappling_hook",
		"effect_status": "implemented",
		"evolution_id": "hook_execution_pull",
		"title": "Execution Pull",
		"description": "Transforms Grappling Hook into an execution strike. 3x damage; AoE mark explosion if target was marked.",
		"required_levels": {},
	},
	{
		"triple_id": "blaster_shadow_line",
		"hero_id": "blaster",
		"grid_index": 8,
		"attack_line_id": "rocket_split",
		"passive_line_id": "battle_focus",
		"active_line_id": "hook_range",
		"target_type": "passive",
		"target_id": "chain_lightning",
		"effect_status": "implemented",
		"evolution_id": "hook_shadow_line",
		"title": "Shock Net",
		"description": "Chain Lightning prefers Tactical Marked enemies, bounces farther, and marks every struck enemy.",
		"required_levels": {},
	},
	{
		"triple_id": "blaster_rapid_abduction",
		"hero_id": "blaster",
		"grid_index": 9,
		"attack_line_id": "rocket_priority_targeting",
		"passive_line_id": "recovery_field",
		"active_line_id": "hook_cooldown_down",
		"target_type": "passive",
		"target_id": "time_dilator",
		"effect_status": "implemented",
		"evolution_id": "hook_rapid_abduction",
		"title": "Stasis Field",
		"description": "Time Dilator becomes a larger near-freeze field; marked enemies are almost stopped.",
		"required_levels": {},
	},
	# ── FURY VANGUARD TRIPLES ────────────────────────────────────────────────────
	# Rage Wave evolutions (attack grids 1-3, passive grids 1-3, active grids 1-3)
	{
		"triple_id": "vanguard_worldbreaker",
		"hero_id": "vanguard",
		"grid_index": 1,
		"attack_line_id": "splash_melee_damage",
		"passive_line_id": "orbit_shields",
		"active_line_id": "rage_wave_power",
		"target_active_skill_id": "rage_wave",
		"target_type": "active",
		"target_id": "rage_wave",
		"effect_status": "implemented",
		"evolution_id": "rage_wave_worldbreaker",
		"title": "Worldbreaker",
		"description": "Transforms Rage Wave into a worldbreaker. Multiple expanding shockwaves, heavy slow, Rage-scaled.",
		"required_levels": {},
	},
	{
		"triple_id": "vanguard_earthsplitter",
		"hero_id": "vanguard",
		"grid_index": 2,
		"attack_line_id": "splash_melee_radius",
		"passive_line_id": "static_field",
		"active_line_id": "rage_wave_radius",
		"target_type": "attack",
		"target_id": "splash_melee",
		"effect_status": "implemented",
		"evolution_id": "rage_wave_earthsplitter",
		"title": "Earthsplitter",
		"description": "Fury Strikes carve a forward ground crack that reaches well beyond the normal melee splash.",
		"required_levels": {},
	},
	{
		"triple_id": "vanguard_crushing_storm",
		"hero_id": "vanguard",
		"grid_index": 3,
		"attack_line_id": "splash_melee_frenzy",
		"passive_line_id": "time_dilator",
		"active_line_id": "rage_wave_deep_slow",
		"target_type": "attack",
		"target_id": "splash_melee",
		"effect_status": "implemented",
		"evolution_id": "rage_wave_crushing_storm",
		"title": "Crushing Storm",
		"description": "Fury Strikes scale harder with Rage and release a slowing pressure storm, becoming brutal at high Rage.",
		"required_levels": {},
	},
	# Mighty Clap evolutions (attack grids 4-6, passive grids 4-6, active grids 4-6)
	{
		"triple_id": "vanguard_thunderclap",
		"hero_id": "vanguard",
		"grid_index": 4,
		"attack_line_id": "splash_melee_impact",
		"passive_line_id": "storm_relay",
		"active_line_id": "mighty_clap_power",
		"target_active_skill_id": "mighty_clap",
		"target_type": "active",
		"target_id": "mighty_clap",
		"effect_status": "implemented",
		"evolution_id": "mighty_clap_thunderclap",
		"title": "Rampage Impact",
		"description": "Transforms Mighty Clap into a huge Rage-scaled cone shockwave with heavy knockback and a delayed second clap.",
		"required_levels": {},
	},
	{
		"triple_id": "vanguard_seismic_fan",
		"hero_id": "vanguard",
		"grid_index": 5,
		"attack_line_id": "splash_melee_shockwave",
		"passive_line_id": "chain_lightning",
		"active_line_id": "mighty_clap_range",
		"target_type": "attack",
		"target_id": "splash_melee",
		"effect_status": "implemented",
		"evolution_id": "mighty_clap_seismic_fan",
		"title": "Seismic Fan",
		"description": "Fury Strikes emit a forward seismic fan that hits enemies in front of the hero.",
		"required_levels": {},
	},
	{
		"triple_id": "vanguard_rampage_impact",
		"hero_id": "vanguard",
		"grid_index": 6,
		"attack_line_id": "splash_melee_combo",
		"passive_line_id": "battle_focus",
		"active_line_id": "mighty_clap_shockwave",
		"target_type": "passive",
		"target_id": "static_field",
		"effect_status": "implemented",
		"evolution_id": "mighty_clap_rampage_impact",
		"title": "Rage Field",
		"description": "Static Field becomes a Rage-scaling damage aura with larger and faster pulses at high Rage.",
		"required_levels": {},
	},
	# Rage Leap evolutions (attack grids 7-9, passive grids 7-9, active grids 7-9)
	{
		"triple_id": "vanguard_meteor_crash",
		"hero_id": "vanguard",
		"grid_index": 7,
		"attack_line_id": "splash_melee_speed",
		"passive_line_id": "magnet_core",
		"active_line_id": "rage_leap_power",
		"target_active_skill_id": "rage_leap",
		"target_type": "active",
		"target_id": "rage_leap",
		"effect_status": "implemented",
		"evolution_id": "rage_leap_meteor_crash",
		"title": "Meteor Crash",
		"description": "Transforms Rage Leap into a meteor crash. Huge crater damage + delayed second impact, Rage-scaled.",
		"required_levels": {},
	},
	{
		"triple_id": "vanguard_blood_crater",
		"hero_id": "vanguard",
		"grid_index": 8,
		"attack_line_id": "splash_melee_lifesteal",
		"passive_line_id": "recovery_field",
		"active_line_id": "rage_leap_radius",
		"target_type": "passive",
		"target_id": "battle_focus",
		"effect_status": "implemented",
		"evolution_id": "rage_leap_blood_crater",
		"title": "Berserker Focus",
		"description": "Battle Focus gives a much stronger Rage-scaled strike and attack-speed burst.",
		"required_levels": {},
	},
	{
		"triple_id": "vanguard_final_impact",
		"hero_id": "vanguard",
		"grid_index": 9,
		"attack_line_id": "splash_melee_execute",
		"passive_line_id": "guardian_drone",
		"active_line_id": "rage_leap_cooldown",
		"target_type": "passive",
		"target_id": "magnet_core",
		"effect_status": "implemented",
		"evolution_id": "rage_leap_final_impact",
		"title": "Gravity Rage",
		"description": "Magnet Core gains much stronger pickup reach and emits periodic gravity pulses that pull and slow enemies.",
		"required_levels": {},
	},
]


# ── SETUP ────────────────────────────────────────────────────────────────────

func setup(new_player: Node, new_auto_attack: Node, new_ability_manager: Node, new_upgrade_manager: Node, new_passive_ability_manager: Node = null) -> void:
	player = new_player
	auto_attack = new_auto_attack
	ability_manager = new_ability_manager
	upgrade_manager = new_upgrade_manager
	passive_ability_manager = new_passive_ability_manager
	if upgrade_manager != null:
		var hd = upgrade_manager.get("hero_data")
		if hd is Dictionary:
			_hero_data = (hd as Dictionary).duplicate(true)


func reset_run_state() -> void:
	_selected_evolutions.clear()
	if auto_attack != null and is_instance_valid(auto_attack) and auto_attack.has_method("_reset_attack_evolution_state"):
		auto_attack.call("_reset_attack_evolution_state")
	evolution_state_changed.emit()


# ── TRIPLE API ───────────────────────────────────────────────────────────────

func get_triple_definitions(hero_id: String) -> Array:
	var result: Array = []
	for triple in _triple_definitions:
		if str(triple.get("hero_id", "")) == hero_id:
			result.append(_normalize_triple(triple))
	return result

func get_triple_state(hero_id: String) -> Dictionary:
	var result: Dictionary = {}
	for triple in _triple_definitions:
		if str(triple.get("hero_id", "")) != hero_id:
			continue
		var triple_id := str(triple.get("triple_id", ""))
		result[triple_id] = _compute_triple_state(triple)
	return result


func get_ready_evolutions(hero_id: String) -> Array:
	var result: Array = []
	for triple in _triple_definitions:
		if str(triple.get("hero_id", "")) != hero_id:
			continue
		var state := _compute_triple_state(triple)
		var state_id := str(state.get("state", ""))
		if state_id == TRIPLE_STATE_READY or state_id == TRIPLE_STATE_SELECTED:
			result.append(_merge_triple_state(triple, state))
	return result

func mark_evolution_selected(evolution_id: String) -> void:
	if not _selected_evolutions.has(evolution_id):
		_selected_evolutions.append(evolution_id)
	evolution_state_changed.emit()


func is_evolution_selected(evolution_id: String) -> bool:
	return _selected_evolutions.has(evolution_id)


func validate_evolution_grid(hero_id: String, strict: bool = false) -> Dictionary:
	var errors: Array = []
	var warnings: Array = []
	var attack_seen: Dictionary = {}
	var passive_seen: Dictionary = {}
	var active_seen: Dictionary = {}
	var grid_seen: Dictionary = {}
	var evo_seen: Dictionary = {}
	var target_counts := _empty_type_counts()

	var hero_triples := get_triple_definitions(hero_id)
	if hero_triples.size() != 9:
		_record_issue(errors, warnings, true, "wrong_triple_count", "Hero '%s' has %d triples, expected 9." % [hero_id, hero_triples.size()])

	for triple in hero_triples:
		var triple_id := str(triple.get("triple_id", ""))
		var grid_idx := int(triple.get("grid_index", 0))
		var atk := str(triple.get("attack_line_id", ""))
		var pas := str(triple.get("passive_line_id", ""))
		var act := str(triple.get("active_line_id", ""))
		var evo_id := str(triple.get("evolution_id", ""))
		var target_type := get_evolution_target_type(triple)
		var target_id := get_evolution_target_id(triple)

		if grid_idx < 1 or grid_idx > 9:
			_record_issue(errors, warnings, true, "invalid_grid_index", "Triple '%s' has invalid grid_index %d." % [triple_id, grid_idx])
		elif grid_seen.has(grid_idx):
			_record_issue(errors, warnings, true, "duplicate_grid_index", "Duplicate grid_index %d for hero '%s'." % [grid_idx, hero_id])
		else:
			grid_seen[grid_idx] = triple_id

		if atk.is_empty():
			_record_issue(errors, warnings, true, "missing_attack_line", "Triple '%s' missing attack_line_id." % triple_id)
		elif attack_seen.has(atk):
			_record_issue(errors, warnings, true, "duplicate_attack_line", "Attack line '%s' reused in hero '%s' triples." % [atk, hero_id])
		else:
			attack_seen[atk] = triple_id

		if pas.is_empty():
			_record_issue(errors, warnings, true, "missing_passive_line", "Triple '%s' missing passive_line_id." % triple_id)
		elif passive_seen.has(pas):
			_record_issue(errors, warnings, true, "duplicate_passive_line", "Passive line '%s' reused in hero '%s' triples." % [pas, hero_id])
		else:
			passive_seen[pas] = triple_id

		if act.is_empty():
			_record_issue(errors, warnings, true, "missing_active_line", "Triple '%s' missing active_line_id." % triple_id)
		elif active_seen.has(act):
			_record_issue(errors, warnings, true, "duplicate_active_line", "Active line '%s' reused in hero '%s' triples." % [act, hero_id])
		else:
			active_seen[act] = triple_id

		if evo_id.is_empty():
			_record_issue(errors, warnings, true, "missing_evolution_id", "Triple '%s' missing evolution_id." % triple_id)
		elif evo_seen.has(evo_id):
			_record_issue(errors, warnings, true, "duplicate_evolution_id", "Evolution id '%s' used in multiple triples." % evo_id)
		else:
			evo_seen[evo_id] = triple_id

		if not VALID_EVOLUTION_TARGET_TYPES.has(target_type):
			_record_issue(errors, warnings, true, "invalid_target_type", "Triple '%s' has invalid target_type '%s'." % [triple_id, target_type])
		else:
			target_counts[target_type] = int(target_counts.get(target_type, 0)) + 1

		if target_id.is_empty():
			_record_issue(errors, warnings, true, "missing_target_id", "Triple '%s' missing target_id." % triple_id)
		elif not _is_valid_target_id(hero_id, target_type, target_id):
			_record_issue(errors, warnings, true, "invalid_target_id", "Triple '%s' target %s/%s does not match upgrade source ids." % [triple_id, target_type, target_id])

		if str(triple.get("effect_status", EFFECT_STATUS_PLACEHOLDER)) == EFFECT_STATUS_IMPLEMENTED:
			if not _is_implemented_evolution_id(evo_id):
				_record_issue(errors, warnings, true, "implemented_id_missing", "Evolution '%s' is marked implemented but is absent from the implemented id registry." % evo_id)
			if not _has_implemented_handler(evo_id, target_type, target_id):
				_record_issue(errors, warnings, true, "implemented_missing_handler", "Evolution '%s' is offerable but has no %s handler for target '%s'." % [evo_id, target_type, target_id])
		elif _is_implemented_evolution_id(evo_id):
			_record_issue(errors, warnings, true, "implemented_id_hidden", "Evolution '%s' has a handler but is marked placeholder." % evo_id)

	for target_type in VALID_EVOLUTION_TARGET_TYPES:
		var count := int(target_counts.get(target_type, 0))
		if count != 3:
			_record_issue(errors, warnings, true, "wrong_target_type_count", "Hero '%s' has %d %s evolution targets, expected 3." % [hero_id, count, target_type])

	for selected_id in _selected_evolutions:
		var raw_selected_triple := _get_triple_by_evolution_id(selected_id)
		if raw_selected_triple.is_empty():
			_record_issue(errors, warnings, true, "selected_unknown_evolution", "Selected evolution '%s' has no triple definition." % selected_id)
			continue
		var selected_triple := _normalize_triple(raw_selected_triple)
		if str(selected_triple.get("hero_id", "")) != hero_id:
			continue
		var selected_type := get_evolution_target_type(selected_triple)
		var selected_target := get_evolution_target_id(selected_triple)
		if not _has_implemented_handler(selected_id, selected_type, selected_target):
			_record_issue(errors, warnings, true, "selected_missing_handler", "Selected evolution '%s' no longer matches a %s handler for '%s'." % [selected_id, selected_type, selected_target])

	return {
		"ok": errors.is_empty(),
		"hero_id": hero_id,
		"strict": strict,
		"errors": errors,
		"warnings": warnings,
		"error_count": errors.size(),
		"warning_count": warnings.size(),
		"triple_count": hero_triples.size(),
		"target_counts": target_counts,
	}

func get_all_evolutions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for t in get_triple_definitions(str(_hero_data.get("id", ""))):
		result.append(t as Dictionary)
	return result


func get_available_evolutions() -> Array[Dictionary]:
	var hero_id := str(_hero_data.get("id", ""))
	var result: Array[Dictionary] = []
	for triple in get_ready_evolutions(hero_id):
		var evo_id := str(triple.get("evolution_id", ""))
		if is_evolution_selected(evo_id) or not _is_evolution_offerable(triple):
			continue
		var data := (triple as Dictionary).duplicate(true)
		data["id"] = evo_id
		result.append(data)
		evolution_available.emit(data)
	return result

func has_evolution(evolution_id: String) -> bool:
	return is_evolution_selected(evolution_id)


func apply_evolution(evolution_id: String) -> bool:
	if is_evolution_selected(evolution_id):
		return false
	var triple := _get_triple_by_evolution_id(evolution_id)
	if triple.is_empty():
		push_warning("EvolutionManager: unknown evolution '%s'." % evolution_id)
		return false
	var triple_data := _normalize_triple(triple)
	if not _apply_evolution_effect(evolution_id, triple_data):
		return false
	mark_evolution_selected(evolution_id)
	triple_data["announcement"] = "EVOLVED: " + str(triple_data.get("title", evolution_id)).to_upper() + "!"
	evolution_applied.emit(evolution_id, triple_data)
	return true

func get_overdrive_options() -> Array[Dictionary]:
	var hero_id := str(_hero_data.get("id", ""))
	var result: Array[Dictionary] = []
	for triple in _triple_definitions:
		if str(triple.get("hero_id", "")) != hero_id:
			continue
		var evo_id := str(triple.get("evolution_id", ""))
		if is_evolution_selected(evo_id):
			continue
		var state := _compute_triple_state(triple)
		if str(state.get("state", "")) != TRIPLE_STATE_READY:
			continue
		var merged := _merge_triple_state(triple, state)
		if not _is_evolution_offerable(merged):
			continue
		result.append(merged)
	return result

func get_applied_evolutions() -> Array[String]:
	return _selected_evolutions.duplicate()


func get_applied_evolution_titles() -> Array[String]:
	var titles: Array[String] = []
	for evo_id in _selected_evolutions:
		var triple := _get_triple_by_evolution_id(evo_id)
		titles.append(str(triple.get("title", evo_id)) if not triple.is_empty() else evo_id)
	return titles


# ── DEBUG ─────────────────────────────────────────────────────────────────────

func debug_print_evolution_state() -> void:
	print("=== EvolutionManager ===")
	var hero_id := str(_hero_data.get("id", "unknown"))
	var ready_evos := get_ready_evolutions(hero_id)
	print("hero=%s  ready=%d  selected=%s" % [hero_id, ready_evos.size(), str(get_applied_evolution_titles())])
	var triple_states := get_triple_state(hero_id)
	for triple_id in triple_states:
		var ts: Dictionary = triple_states[triple_id]
		print("  %s: %s (%d/3 sel, %d/3 maxed)" % [
			triple_id,
			ts.get("state", "?"),
			int(ts.get("selected_lines_count", 0)),
			int(ts.get("maxed_lines_count", 0)),
		])
	print("========================")


func debug_get_evolution_state() -> Dictionary:
	var hero_id := str(_hero_data.get("id", ""))
	var ready_count := get_ready_evolutions(hero_id).size()
	return {
		"available_count": ready_count,
		"applied_ids": get_applied_evolutions(),
		"applied_titles": get_applied_evolution_titles(),
		"hero_id": hero_id,
		"ready_count": ready_count,
		"selected_count": _selected_evolutions.size(),
		"type_counts": get_evolution_type_counts(hero_id),
		"ready_type_counts": get_ready_evolution_type_counts(hero_id),
		"selected_type_counts": get_selected_evolution_type_counts(hero_id),
	}

func debug_get_evolution_grid_state() -> Dictionary:
	var hero_id := str(_hero_data.get("id", ""))
	var triple_states := get_triple_state(hero_id)
	var closest := _find_closest_triple(triple_states)
	return {
		"hero_id": hero_id,
		"triple_count": get_triple_definitions(hero_id).size(),
		"ready_count": get_ready_evolutions(hero_id).size(),
		"selected_count": _selected_evolutions.size(),
		"type_counts": get_evolution_type_counts(hero_id),
		"ready_type_counts": get_ready_evolution_type_counts(hero_id),
		"selected_type_counts": get_selected_evolution_type_counts(hero_id),
		"applied_titles": get_applied_evolution_titles(),
		"applied_ids": get_applied_evolutions(),
		"triple_states": triple_states,
		"closest_triple": closest,
		"validation": validate_evolution_grid(hero_id),
	}

func get_evolution_target_type(triple: Dictionary) -> String:
	var target_type := str(triple.get("target_type", ""))
	if target_type.is_empty() and triple.has("target_active_skill_id"):
		return EVOLUTION_TARGET_ACTIVE
	return target_type


func get_evolution_target_id(triple: Dictionary) -> String:
	var target_id := str(triple.get("target_id", ""))
	if target_id.is_empty():
		return str(triple.get("target_active_skill_id", ""))
	return target_id


func get_evolution_type_counts(hero_id: String) -> Dictionary:
	var counts := _empty_type_counts()
	for triple in get_triple_definitions(hero_id):
		var target_type := get_evolution_target_type(triple)
		if counts.has(target_type):
			counts[target_type] = int(counts[target_type]) + 1
	return counts


func get_selected_evolution_type_counts(hero_id: String) -> Dictionary:
	var counts := _empty_type_counts()
	for evolution_id in _selected_evolutions:
		var triple := _get_triple_by_evolution_id(evolution_id)
		if triple.is_empty() or str(triple.get("hero_id", "")) != hero_id:
			continue
		var target_type := get_evolution_target_type(triple)
		if counts.has(target_type):
			counts[target_type] = int(counts[target_type]) + 1
	return counts


func get_ready_evolution_type_counts(hero_id: String) -> Dictionary:
	var counts := _empty_type_counts()
	for triple in _triple_definitions:
		if str(triple.get("hero_id", "")) != hero_id:
			continue
		var state := _compute_triple_state(triple)
		if str(state.get("state", "")) != TRIPLE_STATE_READY:
			continue
		var target_type := get_evolution_target_type(triple)
		if counts.has(target_type):
			counts[target_type] = int(counts[target_type]) + 1
	return counts


func _empty_type_counts() -> Dictionary:
	return {
		EVOLUTION_TARGET_ATTACK: 0,
		EVOLUTION_TARGET_ACTIVE: 0,
		EVOLUTION_TARGET_PASSIVE: 0,
	}


func _normalize_triple(triple: Dictionary) -> Dictionary:
	var data := triple.duplicate(true)
	var target_type := get_evolution_target_type(data)
	var target_id := get_evolution_target_id(data)
	data["target_type"] = target_type
	data["target_id"] = target_id
	data["id"] = str(data.get("evolution_id", ""))
	if target_type == EVOLUTION_TARGET_ACTIVE and not data.has("target_active_skill_id"):
		data["target_active_skill_id"] = target_id
	if not data.has("effect_status"):
		data["effect_status"] = EFFECT_STATUS_IMPLEMENTED if _is_implemented_evolution_id(str(data.get("evolution_id", ""))) else EFFECT_STATUS_PLACEHOLDER
	return data


func _merge_triple_state(triple: Dictionary, state: Dictionary) -> Dictionary:
	var merged := _normalize_triple(triple)
	merged.merge(state, true)
	merged["target_type"] = get_evolution_target_type(merged)
	merged["target_id"] = get_evolution_target_id(merged)
	merged["id"] = str(merged.get("evolution_id", ""))
	return merged


func _is_evolution_offerable(triple: Dictionary) -> bool:
	var evolution_id := str(triple.get("evolution_id", ""))
	var target_type := get_evolution_target_type(triple)
	var target_id := get_evolution_target_id(triple)
	return (
		str(triple.get("effect_status", EFFECT_STATUS_PLACEHOLDER)) == EFFECT_STATUS_IMPLEMENTED
		and _has_implemented_handler(evolution_id, target_type, target_id)
	)


func _is_implemented_evolution_id(evolution_id: String) -> bool:
	return [
		"solar_beam_cataclysm",
		"solar_beam_sky_lance",
		"solar_beam_burning_judgment",
		"frost_breath_absolute_zero",
		"frost_breath_glacier_front",
		"frost_breath_permafrost",
		"death_dash_solar_execution",
		"death_dash_comet_path",
		"death_dash_final_flash",
		"smoke_screen_blackout",
		"smoke_screen_tactical_cover",
		"smoke_screen_choking_zone",
		"trap_chain_detonation_evolution",
		"trap_cluster_minefield",
		"trap_marked_blast",
		"hook_execution_pull",
		"hook_shadow_line",
		"hook_rapid_abduction",
		"rage_wave_worldbreaker",
		"rage_wave_earthsplitter",
		"rage_wave_crushing_storm",
		"mighty_clap_thunderclap",
		"mighty_clap_seismic_fan",
		"mighty_clap_rampage_impact",
		"rage_leap_meteor_crash",
		"rage_leap_blood_crater",
		"rage_leap_final_impact",
	].has(evolution_id)


func _has_implemented_handler(evolution_id: String, target_type: String, target_id: String) -> bool:
	match target_type:
		EVOLUTION_TARGET_ATTACK:
			return {
				"solar_beam_sky_lance": "solar_ray",
				"solar_beam_burning_judgment": "solar_ray",
				"frost_breath_glacier_front": "solar_ray",
				"smoke_screen_tactical_cover": "homing_rockets",
				"smoke_screen_choking_zone": "homing_rockets",
				"trap_cluster_minefield": "homing_rockets",
				"rage_wave_earthsplitter": "splash_melee",
				"rage_wave_crushing_storm": "splash_melee",
				"mighty_clap_seismic_fan": "splash_melee",
			}.get(evolution_id, "") == target_id
		EVOLUTION_TARGET_ACTIVE:
			return {
				"solar_beam_cataclysm": "solar_beam",
				"frost_breath_absolute_zero": "frost_breath",
				"death_dash_solar_execution": "death_dash",
				"smoke_screen_blackout": "smoke_screen",
				"trap_chain_detonation_evolution": "explosive_trap",
				"hook_execution_pull": "grappling_hook",
				"rage_wave_worldbreaker": "rage_wave",
				"mighty_clap_thunderclap": "mighty_clap",
				"rage_leap_meteor_crash": "rage_leap",
			}.get(evolution_id, "") == target_id
		EVOLUTION_TARGET_PASSIVE:
			return {
				"frost_breath_permafrost": "orbit_shields",
				"death_dash_comet_path": "storm_relay",
				"death_dash_final_flash": "recovery_field",
				"trap_marked_blast": "guardian_drone",
				"hook_shadow_line": "chain_lightning",
				"hook_rapid_abduction": "time_dilator",
				"mighty_clap_rampage_impact": "static_field",
				"rage_leap_blood_crater": "battle_focus",
				"rage_leap_final_impact": "magnet_core",
			}.get(evolution_id, "") == target_id
	return false


func _apply_active_evolution_effect(evolution_id: String) -> bool:
	if ability_manager == null or not is_instance_valid(ability_manager):
		push_warning("EvolutionManager: AbilityManager unavailable for evolution '%s'." % evolution_id)
		return false
	match evolution_id:
		"solar_beam_cataclysm":
			ability_manager.set("solar_beam_cataclysm_enabled", true)
		"frost_breath_absolute_zero":
			ability_manager.set("frost_breath_absolute_zero_enabled", true)
		"death_dash_solar_execution":
			ability_manager.set("death_dash_final_flash_enabled", true)
		"smoke_screen_blackout":
			ability_manager.set("smoke_screen_blackout_enabled", true)
		"trap_chain_detonation_evolution":
			ability_manager.set("explosive_trap_chain_evolution_enabled", true)
		"hook_execution_pull":
			ability_manager.set("grappling_hook_execution_enabled", true)
		"rage_wave_worldbreaker":
			ability_manager.set("rage_wave_worldbreaker_enabled", true)
		"mighty_clap_thunderclap":
			ability_manager.set("mighty_clap_rampage_impact_enabled", true)
		"rage_leap_meteor_crash":
			ability_manager.set("rage_leap_meteor_crash_enabled", true)
		_:
			push_warning("EvolutionManager: no active effect implemented for evolution '%s'." % evolution_id)
			return false
	return true


func _apply_attack_evolution_effect(evolution_id: String, target_id: String) -> bool:
	if auto_attack == null or not is_instance_valid(auto_attack):
		push_warning("EvolutionManager: PlayerAutoAttack unavailable for attack evolution '%s'." % evolution_id)
		return false
	if auto_attack.has_method("apply_attack_evolution"):
		return bool(auto_attack.apply_attack_evolution(evolution_id, target_id))
	push_warning("EvolutionManager: attack evolution '%s' for '%s' is placeholder-only in this patch." % [evolution_id, target_id])
	return false


func _apply_passive_evolution_effect(evolution_id: String, target_id: String) -> bool:
	if passive_ability_manager == null or not is_instance_valid(passive_ability_manager):
		push_warning("EvolutionManager: PassiveAbilityManager unavailable for passive evolution '%s'." % evolution_id)
		return false
	if passive_ability_manager.has_method("apply_passive_evolution"):
		return bool(passive_ability_manager.apply_passive_evolution(evolution_id, target_id))
	push_warning("EvolutionManager: passive evolution '%s' for '%s' is placeholder-only in this patch." % [evolution_id, target_id])
	return false


func _is_valid_target_id(hero_id: String, target_type: String, target_id: String) -> bool:
	if upgrade_manager == null or not upgrade_manager.has_method("get_upgrade_definition_summary"):
		return true
	var line_ids: Array[String] = []
	for triple in get_triple_definitions(hero_id):
		match target_type:
			EVOLUTION_TARGET_ATTACK:
				line_ids.append(str(triple.get("attack_line_id", "")))
			EVOLUTION_TARGET_ACTIVE:
				line_ids.append(str(triple.get("active_line_id", "")))
			EVOLUTION_TARGET_PASSIVE:
				line_ids.append(str(triple.get("passive_line_id", "")))
	for line_id in line_ids:
		if line_id.is_empty():
			continue
		var summary: Dictionary = upgrade_manager.get_upgrade_definition_summary(line_id)
		if summary.is_empty():
			continue
		match target_type:
			EVOLUTION_TARGET_ATTACK:
				if str(summary.get("slot_category", "")) == "attack" and str(summary.get("source_skill_id", "")) == target_id:
					return true
			EVOLUTION_TARGET_ACTIVE:
				if str(summary.get("slot_category", "")) == "active" and (str(summary.get("source_skill_id", "")) == target_id or str(summary.get("evolution_target_active_skill", "")) == target_id):
					return true
			EVOLUTION_TARGET_PASSIVE:
				if str(summary.get("slot_category", "")) == "passive" and (str(summary.get("source_skill_id", "")) == target_id or str(summary.get("id", "")) == target_id):
					return true
	return false


func _apply_evolution_effect(evolution_id: String, triple: Dictionary) -> bool:
	var target_type := get_evolution_target_type(triple)
	var target_id := get_evolution_target_id(triple)
	if str(triple.get("effect_status", EFFECT_STATUS_PLACEHOLDER)) != EFFECT_STATUS_IMPLEMENTED:
		push_warning("EvolutionManager: evolution '%s' for %s/%s is not implemented yet." % [evolution_id, target_type, target_id])
		return false

	match target_type:
		EVOLUTION_TARGET_ACTIVE:
			return _apply_active_evolution_effect(evolution_id)
		EVOLUTION_TARGET_ATTACK:
			return _apply_attack_evolution_effect(evolution_id, target_id)
		EVOLUTION_TARGET_PASSIVE:
			return _apply_passive_evolution_effect(evolution_id, target_id)
		_:
			push_warning("EvolutionManager: unknown target_type '%s' for evolution '%s'." % [target_type, evolution_id])
			return false

func _compute_triple_state(triple: Dictionary) -> Dictionary:
	var attack_id := str(triple.get("attack_line_id", ""))
	var passive_id := str(triple.get("passive_line_id", ""))
	var active_id := str(triple.get("active_line_id", ""))
	var evolution_id := str(triple.get("evolution_id", ""))

	var attack_sel := _is_line_selected(attack_id)
	var passive_sel := _is_line_selected(passive_id)
	var active_sel := _is_line_selected(active_id)

	var attack_max := _get_required_level(triple, attack_id)
	var passive_max := _get_required_level(triple, passive_id)
	var active_max := _get_required_level(triple, active_id)

	var attack_level := _get_upgrade_level(attack_id)
	var passive_level := _get_upgrade_level(passive_id)
	var active_level := _get_upgrade_level(active_id)

	var attack_maxed := attack_sel and attack_level >= attack_max
	var passive_maxed := passive_sel and passive_level >= passive_max
	var active_maxed := active_sel and active_level >= active_max

	var selected_count := int(attack_sel) + int(passive_sel) + int(active_sel)
	var maxed_count := int(attack_maxed) + int(passive_maxed) + int(active_maxed)

	var state: String
	if is_evolution_selected(evolution_id):
		state = TRIPLE_STATE_SELECTED
	elif selected_count == 3 and maxed_count == 3:
		state = TRIPLE_STATE_READY
	elif selected_count == 3:
		state = TRIPLE_STATE_COLLECTED
	elif selected_count > 0:
		state = TRIPLE_STATE_PARTIAL
	else:
		state = TRIPLE_STATE_LOCKED

	return {
		"triple_id": triple.get("triple_id", ""),
		"evolution_id": evolution_id,
		"title": triple.get("title", ""),
		"target_type": get_evolution_target_type(triple),
		"target_id": get_evolution_target_id(triple),
		"effect_status": triple.get("effect_status", EFFECT_STATUS_PLACEHOLDER),
		"state": state,
		"selected_lines_count": selected_count,
		"maxed_lines_count": maxed_count,
		"required_lines": [
			{
				"id": attack_id,
				"title": _get_upgrade_title(attack_id),
				"category": "attack",
				"current_level": attack_level,
				"max_level": attack_max,
				"selected": attack_sel,
				"maxed": attack_maxed,
			},
			{
				"id": passive_id,
				"title": _get_upgrade_title(passive_id),
				"category": "passive",
				"current_level": passive_level,
				"max_level": passive_max,
				"selected": passive_sel,
				"maxed": passive_maxed,
			},
			{
				"id": active_id,
				"title": _get_upgrade_title(active_id),
				"category": "active",
				"current_level": active_level,
				"max_level": active_max,
				"selected": active_sel,
				"maxed": active_maxed,
			},
		],
	}


func _is_line_selected(line_id: String) -> bool:
	if upgrade_manager == null or line_id.is_empty():
		return false
	if upgrade_manager.has_method("has_selected_line"):
		return bool(upgrade_manager.has_selected_line(line_id))
	if upgrade_manager.has_method("get_upgrade_level"):
		return int(upgrade_manager.get_upgrade_level(line_id)) > 0
	return false


func _get_upgrade_level(upgrade_id: String) -> int:
	if upgrade_manager == null or upgrade_id.is_empty():
		return 0
	if upgrade_manager.has_method("get_upgrade_level"):
		return int(upgrade_manager.get_upgrade_level(upgrade_id))
	return 0


func _get_upgrade_max_level(upgrade_id: String) -> int:
	if upgrade_manager == null or upgrade_id.is_empty():
		return 1
	if upgrade_manager.has_method("get_upgrade_max_level"):
		return int(upgrade_manager.get_upgrade_max_level(upgrade_id))
	var summary: Dictionary = {}
	if upgrade_manager.has_method("get_upgrade_definition_summary"):
		summary = upgrade_manager.get_upgrade_definition_summary(upgrade_id)
	return int(summary.get("max_level", 1)) if not summary.is_empty() else 1


func _get_upgrade_title(upgrade_id: String) -> String:
	if upgrade_manager == null or upgrade_id.is_empty() or not upgrade_manager.has_method("get_upgrade_definition_summary"):
		return upgrade_id
	var summary: Dictionary = upgrade_manager.get_upgrade_definition_summary(upgrade_id)
	return str(summary.get("title", upgrade_id)) if not summary.is_empty() else upgrade_id


func _get_required_level(triple: Dictionary, line_id: String) -> int:
	var required_levels: Dictionary = triple.get("required_levels", {})
	if required_levels.has(line_id):
		return int(required_levels[line_id])
	return _get_upgrade_max_level(line_id)


func _get_triple_by_evolution_id(evolution_id: String) -> Dictionary:
	for triple in _triple_definitions:
		if str(triple.get("evolution_id", "")) == evolution_id:
			return triple
	return {}


func _find_closest_triple(triple_states: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	var best_score := -1
	for triple_id in triple_states:
		var ts: Dictionary = triple_states[triple_id]
		if str(ts.get("state", "")) == TRIPLE_STATE_SELECTED:
			continue
		var score := int(ts.get("selected_lines_count", 0)) * 10 + int(ts.get("maxed_lines_count", 0))
		if score > best_score:
			best_score = score
			best = ts
	return best


func _record_issue(errors: Array, warnings: Array, as_error: bool, code: String, message: String) -> void:
	var issue := {"code": code, "message": message}
	if as_error:
		errors.append(issue)
	else:
		warnings.append(issue)
