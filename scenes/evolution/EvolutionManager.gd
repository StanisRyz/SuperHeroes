extends Node

signal evolution_available(evolution_data: Dictionary)
signal evolution_applied(evolution_id: String, evolution_data: Dictionary)
signal evolution_state_changed

@export var elite_reward_chance: float = 0.0

var player: Node
var auto_attack: Node
var ability_manager: Node
var upgrade_manager: Node

var _hero_data: Dictionary = {}
var _selected_evolutions: Array[String] = []

const TRIPLE_STATE_LOCKED := "locked"
const TRIPLE_STATE_PARTIAL := "partial"
const TRIPLE_STATE_COLLECTED := "collected"
const TRIPLE_STATE_READY := "ready"
const TRIPLE_STATE_SELECTED := "selected"

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
		"evolution_id": "solar_beam_cataclysm",
		"title": "Solar Cataclysm",
		"description": "Future evolution for Solar Beam: raw power focus.",
		"required_levels": {},
	},
	{
		"triple_id": "guardian_sky_lance",
		"hero_id": "guardian",
		"grid_index": 2,
		"attack_line_id": "solar_ray_range",
		"passive_line_id": "storm_relay",
		"active_line_id": "solar_beam_range_up",
		"target_active_skill_id": "solar_beam",
		"evolution_id": "solar_beam_sky_lance",
		"title": "Sky Lance",
		"description": "Future evolution for Solar Beam: extreme reach and width.",
		"required_levels": {},
	},
	{
		"triple_id": "guardian_burning_judgment",
		"hero_id": "guardian",
		"grid_index": 3,
		"attack_line_id": "solar_ray_pierce_burn",
		"passive_line_id": "chain_lightning",
		"active_line_id": "solar_beam_overheat",
		"target_active_skill_id": "solar_beam",
		"evolution_id": "solar_beam_burning_judgment",
		"title": "Burning Judgment",
		"description": "Future evolution for Solar Beam: burn and empowered synergy.",
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
		"evolution_id": "frost_breath_absolute_zero",
		"title": "Absolute Zero",
		"description": "Future evolution for Frost Breath: total cold suppression.",
		"required_levels": {},
	},
	{
		"triple_id": "guardian_glacier_front",
		"hero_id": "guardian",
		"grid_index": 5,
		"attack_line_id": "solar_ray_tick_rate",
		"passive_line_id": "static_field",
		"active_line_id": "frost_breath_cone_up",
		"target_active_skill_id": "frost_breath",
		"evolution_id": "frost_breath_glacier_front",
		"title": "Glacier Front",
		"description": "Future evolution for Frost Breath: wide cone area denial.",
		"required_levels": {},
	},
	{
		"triple_id": "guardian_permafrost",
		"hero_id": "guardian",
		"grid_index": 6,
		"attack_line_id": "solar_ray_empowered_bonus",
		"passive_line_id": "recovery_field",
		"active_line_id": "frost_breath_freeze",
		"target_active_skill_id": "frost_breath",
		"evolution_id": "frost_breath_permafrost",
		"title": "Permafrost",
		"description": "Future evolution for Frost Breath: sustained freeze lock.",
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
		"evolution_id": "death_dash_solar_execution",
		"title": "Solar Execution",
		"description": "Future evolution for Death Dash: scorching kill dash.",
		"required_levels": {},
	},
	{
		"triple_id": "guardian_comet_path",
		"hero_id": "guardian",
		"grid_index": 8,
		"attack_line_id": "solar_ray_focus",
		"passive_line_id": "magnet_core",
		"active_line_id": "death_dash_distance",
		"target_active_skill_id": "death_dash",
		"evolution_id": "death_dash_comet_path",
		"title": "Comet Path",
		"description": "Future evolution for Death Dash: long-range comet strike.",
		"required_levels": {},
	},
	{
		"triple_id": "guardian_final_flash",
		"hero_id": "guardian",
		"grid_index": 9,
		"attack_line_id": "solar_ray_execution",
		"passive_line_id": "battle_focus",
		"active_line_id": "death_dash_cooldown_down",
		"target_active_skill_id": "death_dash",
		"evolution_id": "death_dash_final_flash",
		"title": "Final Flash",
		"description": "Future evolution for Death Dash: rapid execution sprint.",
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
		"evolution_id": "smoke_screen_blackout",
		"title": "Blackout",
		"description": "Future evolution for Smoke Screen: total area denial cloud.",
		"required_levels": {},
	},
	{
		"triple_id": "blaster_tactical_cover",
		"hero_id": "blaster",
		"grid_index": 2,
		"attack_line_id": "rocket_count",
		"passive_line_id": "storm_relay",
		"active_line_id": "smoke_screen_duration",
		"target_active_skill_id": "smoke_screen",
		"evolution_id": "smoke_screen_tactical_cover",
		"title": "Tactical Cover",
		"description": "Future evolution for Smoke Screen: extended tactical shroud.",
		"required_levels": {},
	},
	{
		"triple_id": "blaster_choking_zone",
		"hero_id": "blaster",
		"grid_index": 3,
		"attack_line_id": "rocket_reload",
		"passive_line_id": "time_dilator",
		"active_line_id": "smoke_screen_slow",
		"target_active_skill_id": "smoke_screen",
		"evolution_id": "smoke_screen_choking_zone",
		"title": "Choking Zone",
		"description": "Future evolution for Smoke Screen: oppressive slow field.",
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
		"evolution_id": "trap_chain_detonation_evolution",
		"title": "Chain Detonation",
		"description": "Future evolution for Explosive Trap: cascade blast network.",
		"required_levels": {},
	},
	{
		"triple_id": "blaster_cluster_minefield",
		"hero_id": "blaster",
		"grid_index": 5,
		"attack_line_id": "rocket_cluster_payload",
		"passive_line_id": "chain_lightning",
		"active_line_id": "trap_radius",
		"target_active_skill_id": "explosive_trap",
		"evolution_id": "trap_cluster_minefield",
		"title": "Cluster Minefield",
		"description": "Future evolution for Explosive Trap: saturation trap field.",
		"required_levels": {},
	},
	{
		"triple_id": "blaster_marked_blast",
		"hero_id": "blaster",
		"grid_index": 6,
		"attack_line_id": "marked_target_payload",
		"passive_line_id": "guardian_drone",
		"active_line_id": "trap_chain_detonation",
		"target_active_skill_id": "explosive_trap",
		"evolution_id": "trap_marked_blast",
		"title": "Marked Blast",
		"description": "Future evolution for Explosive Trap: mark-amplified detonation.",
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
		"evolution_id": "hook_execution_pull",
		"title": "Execution Pull",
		"description": "Future evolution for Grappling Hook: lethal long-range snare.",
		"required_levels": {},
	},
	{
		"triple_id": "blaster_shadow_line",
		"hero_id": "blaster",
		"grid_index": 8,
		"attack_line_id": "rocket_split",
		"passive_line_id": "battle_focus",
		"active_line_id": "hook_range",
		"target_active_skill_id": "grappling_hook",
		"evolution_id": "hook_shadow_line",
		"title": "Shadow Line",
		"description": "Future evolution for Grappling Hook: extreme-range rapid pull.",
		"required_levels": {},
	},
	{
		"triple_id": "blaster_rapid_abduction",
		"hero_id": "blaster",
		"grid_index": 9,
		"attack_line_id": "rocket_priority_targeting",
		"passive_line_id": "recovery_field",
		"active_line_id": "hook_cooldown_down",
		"target_active_skill_id": "grappling_hook",
		"evolution_id": "hook_rapid_abduction",
		"title": "Rapid Abduction",
		"description": "Future evolution for Grappling Hook: relentless cycle pull.",
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
		"evolution_id": "rage_wave_worldbreaker",
		"title": "Worldbreaker",
		"description": "Future evolution for Rage Wave: shockwave that reshapes the battlefield.",
		"required_levels": {},
	},
	{
		"triple_id": "vanguard_earthsplitter",
		"hero_id": "vanguard",
		"grid_index": 2,
		"attack_line_id": "splash_melee_radius",
		"passive_line_id": "static_field",
		"active_line_id": "rage_wave_radius",
		"target_active_skill_id": "rage_wave",
		"evolution_id": "rage_wave_earthsplitter",
		"title": "Earthsplitter",
		"description": "Future evolution for Rage Wave: wide ground-splitting pulse.",
		"required_levels": {},
	},
	{
		"triple_id": "vanguard_crushing_storm",
		"hero_id": "vanguard",
		"grid_index": 3,
		"attack_line_id": "splash_melee_frenzy",
		"passive_line_id": "time_dilator",
		"active_line_id": "rage_wave_deep_slow",
		"target_active_skill_id": "rage_wave",
		"evolution_id": "rage_wave_crushing_storm",
		"title": "Crushing Storm",
		"description": "Future evolution for Rage Wave: rage-fueled suppression wave.",
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
		"evolution_id": "mighty_clap_thunderclap",
		"title": "Thunderclap",
		"description": "Future evolution for Mighty Clap: earth-shattering impact slam.",
		"required_levels": {},
	},
	{
		"triple_id": "vanguard_seismic_fan",
		"hero_id": "vanguard",
		"grid_index": 5,
		"attack_line_id": "splash_melee_shockwave",
		"passive_line_id": "chain_lightning",
		"active_line_id": "mighty_clap_range",
		"target_active_skill_id": "mighty_clap",
		"evolution_id": "mighty_clap_seismic_fan",
		"title": "Seismic Fan",
		"description": "Future evolution for Mighty Clap: wide seismic shockwave fan.",
		"required_levels": {},
	},
	{
		"triple_id": "vanguard_rampage_impact",
		"hero_id": "vanguard",
		"grid_index": 6,
		"attack_line_id": "splash_melee_combo",
		"passive_line_id": "battle_focus",
		"active_line_id": "mighty_clap_shockwave",
		"target_active_skill_id": "mighty_clap",
		"evolution_id": "mighty_clap_rampage_impact",
		"title": "Rampage Impact",
		"description": "Future evolution for Mighty Clap: rage-combo amplified shockwave.",
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
		"evolution_id": "rage_leap_meteor_crash",
		"title": "Meteor Crash",
		"description": "Future evolution for Rage Leap: high-velocity crater landing.",
		"required_levels": {},
	},
	{
		"triple_id": "vanguard_blood_crater",
		"hero_id": "vanguard",
		"grid_index": 8,
		"attack_line_id": "splash_melee_lifesteal",
		"passive_line_id": "recovery_field",
		"active_line_id": "rage_leap_radius",
		"target_active_skill_id": "rage_leap",
		"evolution_id": "rage_leap_blood_crater",
		"title": "Blood Crater",
		"description": "Future evolution for Rage Leap: lifesteal-infused wide landing.",
		"required_levels": {},
	},
	{
		"triple_id": "vanguard_final_impact",
		"hero_id": "vanguard",
		"grid_index": 9,
		"attack_line_id": "splash_melee_execute",
		"passive_line_id": "guardian_drone",
		"active_line_id": "rage_leap_cooldown",
		"target_active_skill_id": "rage_leap",
		"evolution_id": "rage_leap_final_impact",
		"title": "Final Impact",
		"description": "Future evolution for Rage Leap: rapid execution leap strike.",
		"required_levels": {},
	},
]


# ── SETUP ────────────────────────────────────────────────────────────────────

func setup(new_player: Node, new_auto_attack: Node, new_ability_manager: Node, new_upgrade_manager: Node) -> void:
	player = new_player
	auto_attack = new_auto_attack
	ability_manager = new_ability_manager
	upgrade_manager = new_upgrade_manager
	if upgrade_manager != null:
		var hd = upgrade_manager.get("hero_data")
		if hd is Dictionary:
			_hero_data = (hd as Dictionary).duplicate(true)


func reset_run_state() -> void:
	_selected_evolutions.clear()
	evolution_state_changed.emit()


# ── TRIPLE API ───────────────────────────────────────────────────────────────

func get_triple_definitions(hero_id: String) -> Array:
	var result: Array = []
	for triple in _triple_definitions:
		if str(triple.get("hero_id", "")) == hero_id:
			result.append(triple.duplicate(true))
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
			result.append(triple.duplicate(true))
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

	var hero_triples := get_triple_definitions(hero_id)
	if hero_triples.size() != 9:
		_record_issue(errors, warnings, true, "wrong_triple_count",
			"Hero '%s' has %d triples, expected 9." % [hero_id, hero_triples.size()])

	for triple in hero_triples:
		var triple_id := str(triple.get("triple_id", ""))
		var grid_idx := int(triple.get("grid_index", 0))
		var atk := str(triple.get("attack_line_id", ""))
		var pas := str(triple.get("passive_line_id", ""))
		var act := str(triple.get("active_line_id", ""))
		var evo_id := str(triple.get("evolution_id", ""))
		var target := str(triple.get("target_active_skill_id", ""))

		if grid_idx < 1 or grid_idx > 9:
			_record_issue(errors, warnings, true, "invalid_grid_index",
				"Triple '%s' has invalid grid_index %d." % [triple_id, grid_idx])
		elif grid_seen.has(grid_idx):
			_record_issue(errors, warnings, true, "duplicate_grid_index",
				"Duplicate grid_index %d for hero '%s'." % [grid_idx, hero_id])
		else:
			grid_seen[grid_idx] = triple_id

		if atk.is_empty():
			_record_issue(errors, warnings, true, "missing_attack_line", "Triple '%s' missing attack_line_id." % triple_id)
		elif attack_seen.has(atk):
			_record_issue(errors, warnings, true, "duplicate_attack_line",
				"Attack line '%s' reused in hero '%s' triples." % [atk, hero_id])
		else:
			attack_seen[atk] = triple_id

		if pas.is_empty():
			_record_issue(errors, warnings, true, "missing_passive_line", "Triple '%s' missing passive_line_id." % triple_id)
		elif passive_seen.has(pas):
			_record_issue(errors, warnings, true, "duplicate_passive_line",
				"Passive line '%s' reused in hero '%s' triples." % [pas, hero_id])
		else:
			passive_seen[pas] = triple_id

		if act.is_empty():
			_record_issue(errors, warnings, true, "missing_active_line", "Triple '%s' missing active_line_id." % triple_id)
		elif active_seen.has(act):
			_record_issue(errors, warnings, true, "duplicate_active_line",
				"Active line '%s' reused in hero '%s' triples." % [act, hero_id])
		else:
			active_seen[act] = triple_id

		if evo_id.is_empty():
			_record_issue(errors, warnings, true, "missing_evolution_id", "Triple '%s' missing evolution_id." % triple_id)
		elif evo_seen.has(evo_id):
			_record_issue(errors, warnings, true, "duplicate_evolution_id",
				"Evolution id '%s' used in multiple triples." % evo_id)
		else:
			evo_seen[evo_id] = triple_id

		if target.is_empty():
			_record_issue(errors, warnings, true, "missing_target_active_skill",
				"Triple '%s' missing target_active_skill_id." % triple_id)

	return {
		"ok": errors.is_empty(),
		"hero_id": hero_id,
		"strict": strict,
		"errors": errors,
		"warnings": warnings,
		"error_count": errors.size(),
		"warning_count": warnings.size(),
		"triple_count": hero_triples.size(),
	}


# ── LEGACY COMPATIBILITY METHODS (used by Arena / EvolutionRewardScreen) ─────

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
		if not is_evolution_selected(evo_id):
			var data := triple as Dictionary
			result.append(data)
			evolution_available.emit(data)
	return result


func has_evolution(evolution_id: String) -> bool:
	return is_evolution_selected(evolution_id)


func apply_evolution(evolution_id: String) -> bool:
	# Effects are not implemented in this patch — only tracks selection state.
	if is_evolution_selected(evolution_id):
		return false
	mark_evolution_selected(evolution_id)
	var triple := _get_triple_by_evolution_id(evolution_id)
	evolution_applied.emit(evolution_id, triple.duplicate(true))
	return true


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
	var ready := get_ready_evolutions(hero_id)
	print("hero=%s  ready=%d  selected=%s" % [hero_id, ready.size(), str(get_applied_evolution_titles())])
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
		"triple_states": triple_states,
		"closest_triple": closest,
		"validation": validate_evolution_grid(hero_id),
	}


# ── PRIVATE HELPERS ───────────────────────────────────────────────────────────

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
		"state": state,
		"selected_lines_count": selected_count,
		"maxed_lines_count": maxed_count,
		"required_lines": [
			{
				"id": attack_id,
				"category": "attack",
				"current_level": attack_level,
				"max_level": attack_max,
				"selected": attack_sel,
				"maxed": attack_maxed,
			},
			{
				"id": passive_id,
				"category": "passive",
				"current_level": passive_level,
				"max_level": passive_max,
				"selected": passive_sel,
				"maxed": passive_maxed,
			},
			{
				"id": active_id,
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
