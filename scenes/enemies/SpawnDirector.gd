extends Node

# Enemy roles (display/gameplay metadata)
# swarmer  = weak mass pressure      (grunt, swarm)
# hunter   = fast chase pressure     (runner, charger)
# bruiser  = slow durable block      (tank, shielded)
# shooter  = ranged pressure         (shooter)
# disruptor= special pressure        (exploder, support)

const BASE_SPAWN_INTERVAL := 1.5
const MIN_SPAWN_INTERVAL := 0.45
const MIN_SPAWN_INTERVAL_HARD := 0.20   # absolute floor when phase + event pressure compound
const BASE_MAX_ALIVE_ENEMIES := 12
const MAX_ALIVE_ENEMIES := 60
const WAVE_WARNING_COOLDOWN := 12.0     # minimum seconds between wave warning announcements

# --- Run Phases ---
# Five named phases spanning the 10-minute run.
# spawn_pressure_multiplier > 1 = faster spawning; < 1 = slower spawning.
# wave_interval_multiplier  > 1 = longer between wave packages; < 1 = shorter.
const RUN_PHASES: Array = [
	{
		"id": "early",
		"start_time": 0.0,
		"spawn_pressure_multiplier": 0.75,
		"max_alive_multiplier": 1.0,
		"wave_interval_multiplier": 1.3,
		"preferred_roles": ["swarmer", "hunter"],
		"warning_text": "",
	},
	{
		"id": "build",
		"start_time": 120.0,
		"spawn_pressure_multiplier": 0.9,
		"max_alive_multiplier": 1.0,
		"wave_interval_multiplier": 1.1,
		"preferred_roles": ["swarmer", "hunter", "bruiser"],
		"warning_text": "",
	},
	{
		"id": "pressure",
		"start_time": 240.0,
		"spawn_pressure_multiplier": 1.1,
		"max_alive_multiplier": 1.0,
		"wave_interval_multiplier": 0.95,
		"preferred_roles": ["bruiser", "shooter", "disruptor"],
		"warning_text": "",
	},
	{
		"id": "danger",
		"start_time": 360.0,
		"spawn_pressure_multiplier": 1.3,
		"max_alive_multiplier": 1.0,
		"wave_interval_multiplier": 0.85,
		"preferred_roles": ["shooter", "disruptor", "mixed"],
		"warning_text": "",
	},
	{
		"id": "pre_boss",
		"start_time": 480.0,
		"spawn_pressure_multiplier": 1.5,
		"max_alive_multiplier": 1.0,
		"wave_interval_multiplier": 0.75,
		"preferred_roles": ["disruptor", "mixed", "bruiser"],
		"warning_text": "",
	},
]

# Maximum total budget cost per wave pick.  Higher phases allow more expensive packages.
const PHASE_WAVE_BUDGETS: Dictionary = {
	"early": 2.5,
	"build": 3.5,
	"pressure": 5.0,
	"danger": 6.0,
	"pre_boss": 6.0,
}

var run_manager: Node
var active_event_modifiers: Dictionary = {}
var _stage_profile: String = "balanced"
var _last_wave_package_id: String = ""
var _event_announcement: Node = null
var _wave_budget_remaining: float = 6.0
var _package_last_fired: Dictionary = {}   # package_id -> run_time when last selected
var _last_warning_time: float = -999.0

var _stage_profile_weight_bonuses: Dictionary = {
	"ranged_support": {"shooter": 1.25, "support": 1.25},
	"swarm_exploder":  {"exploder": 1.3,  "swarm":   1.3},
	"defense_pressure": {"tank": 1.15, "shielded": 1.2},
	"portal_pressure":  {"runner": 1.2, "exploder": 1.15},
}

# Wave packages — each defines a role-themed burst of enemies.
# phase_weights : per-phase weight multiplier (stacks with base weight and profile_bonus).
# budget_cost   : how much of the phase wave budget this package consumes.
# min_phase     : earliest phase this package may appear ("" = any).
# max_phase     : latest  phase this package may appear  ("" = any).
# warning_level : 0 = silent; 1 = minor announcement; 2 = major announcement.
# warning_text  : text shown when warning_level >= 1.
# package_cooldown : minimum seconds before the same package fires again.
const WAVE_PACKAGES: Array = [
	{
		"id": "early_grunts",
		"role": "swarmer",
		"variant_pool": ["grunt"],
		"min_count": 2, "max_count": 3,
		"weight": 1.2,
		"unlock_time": 0.0,
		"profile_bonus": {},
		"phase_weights": {"early": 1.5, "build": 1.0, "pressure": 0.7, "danger": 0.4, "pre_boss": 0.2},
		"budget_cost": 1.0,
		"min_phase": "",
		"max_phase": "danger",
		"warning_level": 0,
		"warning_text": "",
		"package_cooldown": 8.0,
	},
	{
		"id": "runner_pack",
		"role": "hunter",
		"variant_pool": ["runner"],
		"min_count": 2, "max_count": 3,
		"weight": 1.0,
		"unlock_time": 30.0,
		"profile_bonus": {},
		"phase_weights": {"early": 1.2, "build": 1.1, "pressure": 0.9, "danger": 0.6, "pre_boss": 0.4},
		"budget_cost": 1.5,
		"min_phase": "",
		"max_phase": "",
		"warning_level": 0,
		"warning_text": "",
		"package_cooldown": 10.0,
	},
	{
		"id": "bruiser_wall",
		"role": "bruiser",
		"variant_pool": ["tank"],
		"min_count": 1, "max_count": 2,
		"weight": 0.7,
		"unlock_time": 60.0,
		"profile_bonus": {"balanced": 1.2},
		"phase_weights": {"early": 0.3, "build": 1.2, "pressure": 1.3, "danger": 1.0, "pre_boss": 0.9},
		"budget_cost": 2.0,
		"min_phase": "",
		"max_phase": "",
		"warning_level": 1,
		"warning_text": "Heavy front!",
		"package_cooldown": 15.0,
	},
	{
		"id": "shooter_screen",
		"role": "shooter",
		"variant_pool": ["shooter"],
		"min_count": 1, "max_count": 2,
		"weight": 0.7,
		"unlock_time": 75.0,
		"profile_bonus": {"ranged_support": 1.5},
		"phase_weights": {"early": 0.2, "build": 0.9, "pressure": 1.3, "danger": 1.2, "pre_boss": 1.0},
		"budget_cost": 2.0,
		"min_phase": "build",
		"max_phase": "",
		"warning_level": 1,
		"warning_text": "Ranged support detected",
		"package_cooldown": 15.0,
	},
	{
		"id": "exploder_pressure",
		"role": "disruptor",
		"variant_pool": ["exploder"],
		"min_count": 1, "max_count": 2,
		"weight": 0.65,
		"unlock_time": 120.0,
		"profile_bonus": {"swarm_exploder": 1.5},
		"phase_weights": {"early": 0.0, "build": 0.7, "pressure": 1.1, "danger": 1.3, "pre_boss": 1.2},
		"budget_cost": 2.5,
		"min_phase": "build",
		"max_phase": "",
		"warning_level": 1,
		"warning_text": "Exploders incoming",
		"package_cooldown": 20.0,
	},
	{
		"id": "swarm_rush",
		"role": "swarmer",
		"variant_pool": ["swarm"],
		"min_count": 2, "max_count": 4,
		"weight": 0.85,
		"unlock_time": 150.0,
		"profile_bonus": {"swarm_exploder": 1.5},
		"phase_weights": {"early": 0.0, "build": 0.6, "pressure": 1.2, "danger": 1.4, "pre_boss": 1.2},
		"budget_cost": 2.0,
		"min_phase": "build",
		"max_phase": "",
		"warning_level": 2,
		"warning_text": "Swarm incoming!",
		"package_cooldown": 18.0,
	},
	{
		"id": "shielded_push",
		"role": "bruiser",
		"variant_pool": ["shielded"],
		"min_count": 1, "max_count": 2,
		"weight": 0.6,
		"unlock_time": 180.0,
		"profile_bonus": {},
		"phase_weights": {"early": 0.0, "build": 0.4, "pressure": 1.0, "danger": 1.3, "pre_boss": 1.1},
		"budget_cost": 2.5,
		"min_phase": "pressure",
		"max_phase": "",
		"warning_level": 1,
		"warning_text": "Shielded push!",
		"package_cooldown": 20.0,
	},
	{
		"id": "support_pair",
		"role": "disruptor",
		"variant_pool": ["support"],
		"min_count": 1, "max_count": 2,
		"weight": 0.55,
		"unlock_time": 210.0,
		"profile_bonus": {"ranged_support": 1.4},
		"phase_weights": {"early": 0.0, "build": 0.3, "pressure": 0.9, "danger": 1.2, "pre_boss": 1.3},
		"budget_cost": 2.5,
		"min_phase": "pressure",
		"max_phase": "",
		"warning_level": 2,
		"warning_text": "Support unit detected",
		"package_cooldown": 22.0,
	},
	{
		"id": "mixed_late_wave",
		"role": "mixed",
		"variant_pool": ["runner", "tank", "shooter"],
		"min_count": 2, "max_count": 3,
		"weight": 0.65,
		"unlock_time": 240.0,
		"profile_bonus": {"balanced": 1.3},
		"phase_weights": {"early": 0.0, "build": 0.0, "pressure": 0.8, "danger": 1.4, "pre_boss": 1.5},
		"budget_cost": 3.0,
		"min_phase": "pressure",
		"max_phase": "",
		"warning_level": 2,
		"warning_text": "Danger wave!",
		"package_cooldown": 25.0,
	},
]

func setup(new_run_manager: Node, new_event_announcement: Node = null) -> void:
	run_manager = new_run_manager
	_event_announcement = new_event_announcement
	_package_last_fired.clear()
	_wave_budget_remaining = 6.0
	_last_warning_time = -999.0


func set_stage_profile(profile: String) -> void:
	_stage_profile = profile


func apply_event_modifier(event_data: Dictionary) -> void:
	active_event_modifiers[event_data["id"]] = event_data.get("modifier", {})


func clear_event_modifier(event_id: String) -> void:
	active_event_modifiers.erase(event_id)


# --- Phase API ---

func get_current_run_phase() -> String:
	var seconds := _get_run_time()
	var result := "early"
	for phase in RUN_PHASES:
		if seconds >= float(phase.get("start_time", 0.0)):
			result = str(phase.get("id", "early"))
	return result


func get_current_phase_data() -> Dictionary:
	var seconds := _get_run_time()
	var result: Dictionary = RUN_PHASES[0]
	for phase in RUN_PHASES:
		if seconds >= float(phase.get("start_time", 0.0)):
			result = phase
	return result


func get_phase_progress() -> float:
	var seconds := _get_run_time()
	var phase_data := get_current_phase_data()
	var start := float(phase_data.get("start_time", 0.0))
	var phase_id := str(phase_data.get("id", "early"))
	var next_start := 600.0
	for i in range(RUN_PHASES.size()):
		if str(RUN_PHASES[i].get("id", "")) == phase_id and i + 1 < RUN_PHASES.size():
			next_start = float(RUN_PHASES[i + 1].get("start_time", 600.0))
			break
	var duration := next_start - start
	if duration <= 0.0:
		return 1.0
	return clampf((seconds - start) / duration, 0.0, 1.0)


func debug_get_run_director_state() -> Dictionary:
	return {
		"run_time": _get_run_time(),
		"phase": get_current_run_phase(),
		"phase_progress": get_phase_progress(),
		"spawn_interval": get_spawn_interval(),
		"max_alive": get_max_alive_enemies(),
		"wave_interval": get_wave_interval(),
		"last_wave_package": _last_wave_package_id,
		"stage_profile": _stage_profile,
		"wave_budget_remaining": _wave_budget_remaining,
	}


# --- Spawn Interval ---

# Interval between individual enemy spawns.
# Phase pressure multiplier: > 1 = faster spawning (smaller interval).
# Hard floor of MIN_SPAWN_INTERVAL_HARD prevents impossible spawning density.
func get_spawn_interval() -> float:
	var seconds := _get_run_time()
	var phase_data := get_current_phase_data()
	var progress := clampf(seconds / 600.0, 0.0, 1.0)
	var base_interval := lerpf(BASE_SPAWN_INTERVAL, MIN_SPAWN_INTERVAL, progress)
	var phase_pressure := float(phase_data.get("spawn_pressure_multiplier", 1.0))
	base_interval = base_interval / phase_pressure
	for mod_id in active_event_modifiers:
		var mod: Dictionary = active_event_modifiers[mod_id]
		if mod.has("spawn_pressure"):
			base_interval = base_interval / float(mod["spawn_pressure"])
	return maxf(base_interval, MIN_SPAWN_INTERVAL_HARD)


func get_max_alive_enemies() -> int:
	var seconds := _get_run_time()
	var progress := clampf(seconds / 300.0, 0.0, 1.0)
	var base_max := int(round(lerpf(BASE_MAX_ALIVE_ENEMIES, MAX_ALIVE_ENEMIES, progress)))
	var bonus := 0
	for mod_id in active_event_modifiers:
		var mod: Dictionary = active_event_modifiers[mod_id]
		if mod.has("max_alive_bonus"):
			bonus += int(mod["max_alive_bonus"])
	return mini(base_max + bonus, MAX_ALIVE_ENEMIES)


func get_enemy_variant() -> Dictionary:
	var seconds := _get_run_time()
	var variants := _get_available_variants(seconds)
	if variants.is_empty():
		return {}

	var total_weight := 0.0
	for variant in variants:
		total_weight += _get_modified_weight(variant)

	if total_weight <= 0.0:
		return _strip_weight(variants[0])

	var roll := randf() * total_weight
	var weight_cursor := 0.0
	for variant in variants:
		weight_cursor += _get_modified_weight(variant)
		if roll <= weight_cursor:
			return _strip_weight(variant)

	return _strip_weight(variants[0])


func get_enemy_variant_by_id(variant_id: String) -> Dictionary:
	for variant in _get_available_variants(9999.0):
		if str(variant.get("id", "")) == variant_id:
			return _strip_weight(variant)
	return {}


# --- Wave Director ---

# Interval between wave package spawns; phase-driven.
# Base 11 s × wave_interval_multiplier → early ~14.3 s, pre_boss ~8.25 s.
func get_wave_interval() -> float:
	var phase_data := get_current_phase_data()
	var mult := float(phase_data.get("wave_interval_multiplier", 1.0))
	return maxf(11.0 * mult, 5.0)


# Selects and builds a wave package for the current run phase and stage profile.
# Returns a dict with id, role, variant_ids, warning_level.
# Returns {} if no package is available yet.
func get_wave_package() -> Dictionary:
	var seconds := _get_run_time()
	var phase_id := get_current_run_phase()
	_wave_budget_remaining = float(PHASE_WAVE_BUDGETS.get(phase_id, 5.0))

	var available := _get_available_packages(seconds)
	if available.is_empty():
		return {}

	# Filter to packages the current wave budget can afford.
	var affordable: Array = []
	for pkg in available:
		if float(pkg.get("budget_cost", 1.0)) <= _wave_budget_remaining:
			affordable.append(pkg)
	if affordable.is_empty():
		affordable = available  # safety fallback: ignore budget if nothing fits

	var total := 0.0
	for pkg in affordable:
		total += _get_package_weight(pkg)

	var selected_pkg: Dictionary = affordable[0]
	if total > 0.0:
		var roll := randf() * total
		var cursor := 0.0
		for pkg in affordable:
			cursor += _get_package_weight(pkg)
			if roll <= cursor:
				selected_pkg = pkg
				break

	_last_wave_package_id = str(selected_pkg.get("id", ""))
	_package_last_fired[_last_wave_package_id] = seconds
	_wave_budget_remaining -= float(selected_pkg.get("budget_cost", 1.0))
	_maybe_fire_wave_warning(selected_pkg)
	return _build_package_spawn(selected_pkg, seconds)


# Backward-compatible alias so existing callers still work.
func debug_get_wave_state() -> Dictionary:
	return debug_get_run_director_state()


# --- Internal helpers ---

func _maybe_fire_wave_warning(pkg: Dictionary) -> void:
	var level := int(pkg.get("warning_level", 0))
	if level <= 0:
		return
	var seconds := _get_run_time()
	if seconds - _last_warning_time < WAVE_WARNING_COOLDOWN:
		return
	var text := str(pkg.get("warning_text", ""))
	if text.is_empty():
		return
	_last_warning_time = seconds
	if _event_announcement != null and _event_announcement.has_method("show_announcement"):
		var duration := 2.0 if level == 1 else 2.5
		_event_announcement.show_announcement(text, duration)


func _get_available_packages(seconds: float) -> Array:
	var available_variants := _get_available_variants(seconds)
	var available_ids: Dictionary = {}
	for v in available_variants:
		available_ids[str(v.get("id", ""))] = true

	var phase_order: Array = ["early", "build", "pressure", "danger", "pre_boss"]
	var current_phase_id := get_current_run_phase()
	var current_phase_idx: int = phase_order.find(current_phase_id)

	var result: Array = []
	for pkg in WAVE_PACKAGES:
		if seconds < float(pkg.get("unlock_time", 0.0)):
			continue

		# Package cooldown: must wait before the same package fires again.
		var pkg_id := str(pkg.get("id", ""))
		var cooldown := float(pkg.get("package_cooldown", 0.0))
		if cooldown > 0.0 and _package_last_fired.has(pkg_id):
			if seconds - float(_package_last_fired[pkg_id]) < cooldown:
				continue

		# Min-phase gate: package not allowed before its minimum phase.
		var min_phase_id := str(pkg.get("min_phase", ""))
		if not min_phase_id.is_empty():
			var min_idx: int = phase_order.find(min_phase_id)
			if min_idx >= 0 and current_phase_idx >= 0 and current_phase_idx < min_idx:
				continue

		# Max-phase gate: package not allowed after its maximum phase.
		var max_phase_id := str(pkg.get("max_phase", ""))
		if not max_phase_id.is_empty():
			var max_idx: int = phase_order.find(max_phase_id)
			if max_idx >= 0 and current_phase_idx >= 0 and current_phase_idx > max_idx:
				continue

		# All variants in the pool must be available at this run time.
		var pool: Array = pkg.get("variant_pool", [])
		var all_ok := true
		for vid in pool:
			if not available_ids.has(str(vid)):
				all_ok = false
				break
		if all_ok:
			result.append(pkg)
	return result


func _get_package_weight(pkg: Dictionary) -> float:
	var weight := float(pkg.get("weight", 1.0))
	var phase_id := get_current_run_phase()

	# Phase-specific multiplier.
	var phase_weights: Dictionary = pkg.get("phase_weights", {})
	if phase_weights.has(phase_id):
		weight *= float(phase_weights[phase_id])

	# Stage-profile bonus.
	var bonus: Dictionary = pkg.get("profile_bonus", {})
	if bonus.has(_stage_profile):
		weight *= float(bonus[_stage_profile])

	return maxf(weight, 0.0)


func _build_package_spawn(pkg: Dictionary, seconds: float) -> Dictionary:
	var pool: Array = pkg.get("variant_pool", [])
	var min_c: int = int(pkg.get("min_count", 1))
	var max_c: int = int(pkg.get("max_count", 2))

	# Gradually increase max count after 300 s (late game), capped at +2.
	if seconds >= 300.0:
		max_c = mini(max_c + 1, max_c + 2)

	var count: int = randi_range(min_c, max_c)

	var ids: Array[String] = []
	for i in range(count):
		ids.append(str(pool[randi() % pool.size()]))

	return {
		"id": str(pkg.get("id", "")),
		"role": str(pkg.get("role", "")),
		"variant_ids": ids,
		"warning_level": int(pkg.get("warning_level", 0)),
	}


func _get_run_time() -> float:
	if run_manager == null:
		return 0.0
	var value = run_manager.get("run_time")
	return float(value) if value != null else 0.0


func _get_available_variants(seconds: float) -> Array[Dictionary]:
	var variants: Array[Dictionary] = [
		{
			"id": "grunt",
			"display_name": "Grunt",
			"role": "swarmer",
			"behavior_id": "chase",
			"speed": 120.0,
			"max_health": 20,
			"contact_damage": 10,
			"experience_value": 1,
			"body_color": Color(0.83, 0.12, 0.24, 1.0),
			"core_color": Color(0.34, 0.04, 0.1, 1.0),
			"weight": 1.0,
		},
	]

	if seconds >= 30.0:
		variants.append({
			"id": "runner",
			"display_name": "Runner",
			"role": "hunter",
			"behavior_id": "chase",
			"speed": 175.0,
			"max_health": 14,
			"contact_damage": 10,
			"experience_value": 1,
			"body_color": Color(0.95, 0.55, 0.12, 1.0),
			"core_color": Color(0.42, 0.16, 0.02, 1.0),
			"weight": clampf((seconds - 30.0) / 90.0, 0.25, 1.4),
		})

	if seconds >= 45.0:
		variants.append({
			"id": "charger",
			"display_name": "Charger",
			"role": "hunter",
			"behavior_id": "charger",
			"speed": 150.0,
			"max_health": 32,
			"contact_damage": 13,
			"experience_value": 2,
			"body_color": Color(0.1, 0.68, 0.62, 1.0),
			"core_color": Color(0.02, 0.26, 0.28, 1.0),
			"charge_range": 360.0,
			"charge_windup": 0.35,
			"charge_speed_multiplier": 2.4,
			"charge_duration": 0.45,
			"charge_cooldown": 2.2,
			"weight": clampf((seconds - 45.0) / 120.0, 0.15, 0.9),
		})

	if seconds >= 60.0:
		variants.append({
			"id": "tank",
			"display_name": "Tank",
			"role": "bruiser",
			"behavior_id": "chase",
			"speed": 85.0,
			"max_health": 55,
			"contact_damage": 18,
			"experience_value": 3,
			"body_color": Color(0.42, 0.26, 0.72, 1.0),
			"core_color": Color(0.14, 0.08, 0.32, 1.0),
			"weight": clampf((seconds - 60.0) / 150.0, 0.15, 0.85),
		})

	if seconds >= 75.0:
		variants.append({
			"id": "shooter",
			"display_name": "Shooter",
			"role": "shooter",
			"behavior_id": "shooter",
			"speed": 90.0,
			"max_health": 24,
			"contact_damage": 9,
			"experience_value": 2,
			"body_color": Color(0.24, 0.42, 0.95, 1.0),
			"core_color": Color(0.05, 0.12, 0.38, 1.0),
			"preferred_distance": 430.0,
			"shoot_range": 560.0,
			"shoot_interval": 1.8,
			"projectile_damage": 8,
			"projectile_speed": 360.0,
			"weight": clampf((seconds - 75.0) / 150.0, 0.1, 0.75),
		})

	if seconds >= 120.0:
		variants.append({
			"id": "exploder",
			"display_name": "Exploder",
			"role": "disruptor",
			"behavior_id": "exploder",
			"speed": 135.0,
			"max_health": 26,
			"contact_damage": 6,
			"experience_value": 2,
			"body_color": Color(1.0, 0.22, 0.08, 1.0),
			"core_color": Color(1.0, 0.72, 0.08, 1.0),
			"explode_radius": 115.0,
			"explode_damage": 22,
			"explode_windup": 0.65,
			"explode_trigger_distance": 70.0,
			"weight": clampf((seconds - 120.0) / 160.0, 0.1, 0.7),
		})

	if seconds >= 150.0:
		variants.append({
			"id": "swarm",
			"display_name": "Swarm",
			"role": "swarmer",
			"behavior_id": "swarm",
			"speed": 205.0,
			"max_health": 12,
			"contact_damage": 7,
			"experience_value": 1,
			"body_color": Color(0.05, 0.95, 0.76, 1.0),
			"core_color": Color(0.02, 0.34, 0.18, 1.0),
			"orbit_distance": 135.0,
			"orbit_strength": 0.85,
			"orbit_direction": 1.0,
			"approach_distance": 230.0,
			"weight": clampf((seconds - 150.0) / 180.0, 0.1, 0.8),
		})

	if seconds >= 180.0:
		variants.append({
			"id": "shielded",
			"display_name": "Shielded",
			"role": "bruiser",
			"behavior_id": "chase",
			"speed": 105.0,
			"max_health": 42,
			"contact_damage": 14,
			"experience_value": 3,
			"body_color": Color(0.26, 0.56, 1.0, 1.0),
			"core_color": Color(0.86, 0.95, 1.0, 1.0),
			"shield_value": 28,
			"weight": clampf((seconds - 180.0) / 190.0, 0.1, 0.7),
		})

	if seconds >= 210.0:
		variants.append({
			"id": "support",
			"display_name": "Support",
			"role": "disruptor",
			"behavior_id": "support",
			"speed": 82.0,
			"max_health": 34,
			"contact_damage": 7,
			"experience_value": 3,
			"body_color": Color(0.7, 0.22, 0.95, 1.0),
			"core_color": Color(1.0, 0.86, 0.18, 1.0),
			"support_radius": 300.0,
			"support_interval": 4.0,
			"support_damage_multiplier": 1.25,
			"support_speed_multiplier": 1.18,
			"support_buff_duration": 5.0,
			"weight": clampf((seconds - 210.0) / 210.0, 0.1, 0.55),
		})

	return variants


func _get_modified_weight(variant: Dictionary) -> float:
	var weight := float(variant.get("weight", 1.0))
	var variant_id := str(variant.get("id", ""))
	if _stage_profile_weight_bonuses.has(_stage_profile):
		var bonuses: Dictionary = _stage_profile_weight_bonuses[_stage_profile]
		if bonuses.has(variant_id):
			weight *= float(bonuses[variant_id])
	for mod_id in active_event_modifiers:
		var mod: Dictionary = active_event_modifiers[mod_id]
		if mod.get("boost_runner_weight", false) and variant_id == "runner":
			weight *= 3.0
		if mod.get("boost_tank_weight", false) and variant_id == "tank":
			weight *= 3.0
		if mod.get("boost_special_weight", false) and ["charger", "shooter", "exploder", "swarm", "shielded", "support"].has(variant_id):
			weight *= 1.5
		var boosted: Dictionary = mod.get("boost_variant_weights", {})
		if boosted.has(variant_id):
			weight *= float(boosted[variant_id])
	return maxf(weight, 0.0)


func _strip_weight(variant: Dictionary) -> Dictionary:
	var selected := variant.duplicate()
	selected.erase("weight")
	return selected
