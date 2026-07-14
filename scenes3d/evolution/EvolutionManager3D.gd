class_name EvolutionManager3D
extends Node

signal evolution_available(evolution_data: Dictionary)
signal evolution_applied(evolution_id: String, evolution_data: Dictionary)
signal evolution_state_changed

const EVOLUTIONS: Array[Dictionary] = [
	{"id": "rage_wave_worldbreaker", "title": "Worldbreaker", "description": "Rage Wave erupts three times, with each pulse expanding farther and striking enemies again.", "effect_summary": "Three expanding pulses. Total damage 2.60x. Wide-area slow.", "target_ability_id": "rage_wave", "implementation_status": "implemented", "prerequisites": ["splash_melee_damage", "orbit_shields", "rage_wave_power"]},
	{"id": "shield_bash_rampage_impact", "title": "Rampage Impact", "description": "Shield Bash unleashes a wider heavy impact followed by a delayed second shockwave.", "effect_summary": "Two directional impacts. Total damage 2.75x. Heavy knockback and stagger.", "target_ability_id": "shield_bash", "implementation_status": "implemented", "prerequisites": ["splash_melee_impact", "storm_relay", "mighty_clap_power"]},
	{"id": "crushing_leap_meteor_crash", "title": "Meteor Crash", "description": "Crushing Leap crashes down with a larger stunning impact followed by a delayed crater eruption.", "effect_summary": "Landing impact and crater aftershock. Total damage 2.60x. Stun and slow.", "target_ability_id": "crushing_leap", "implementation_status": "implemented", "prerequisites": ["splash_melee_speed", "magnet_core", "rage_leap_power"]},
	{"id": "mighty_clap_rampage_impact", "triple_id": "vanguard_rampage_impact", "title": "Rage Field", "description": "Static Field becomes a Rage-scaling damage aura with larger and faster pulses at high Rage.", "effect_summary": "Rage-scaled area pulses with increased radius, damage, and frequency.", "target_type": "passive", "target_passive_id": "static_field", "implementation_status": "implemented", "prerequisites": ["splash_melee_combo", "battle_focus", "mighty_clap_shockwave"]},
	{"id": "rage_leap_blood_crater", "triple_id": "vanguard_blood_crater", "title": "Berserker Focus", "description": "Battle Focus gives a much stronger Rage-scaled strike and attack-speed burst.", "effect_summary": "Rage-scaled multi-target strikes and an enhanced attack-speed burst.", "target_type": "passive", "target_passive_id": "battle_focus", "implementation_status": "implemented", "prerequisites": ["splash_melee_lifesteal", "recovery_field", "rage_leap_radius"]},
	{"id": "rage_leap_final_impact", "triple_id": "vanguard_final_impact", "title": "Gravity Rage", "description": "Magnet Core gains much stronger pickup reach and emits periodic gravity pulses that pull and slow enemies.", "effect_summary": "Greatly increased pickup reach and periodic enemy-pulling gravity pulses.", "target_type": "passive", "target_passive_id": "magnet_core", "implementation_status": "implemented", "prerequisites": ["splash_melee_execute", "guardian_drone", "rage_leap_cooldown"]},
	{"id": "rage_wave_earthsplitter", "triple_id": "vanguard_earthsplitter", "title": "Earthsplitter", "description": "Fury Strikes carve a forward ground crack beyond the normal melee splash.", "effect_summary": "A forward crack deals 0.75x base swing damage after a successful melee impact.", "target_type": "attack", "target_attack_id": "splash_melee", "implementation_status": "implemented", "prerequisites": ["splash_melee_radius", "static_field", "rage_wave_radius"]},
	{"id": "rage_wave_crushing_storm", "triple_id": "vanguard_crushing_storm", "title": "Crushing Storm", "description": "Fury Strikes create a Rage-scaling pressure storm after each successful impact.", "effect_summary": "Rage-scaled pressure area with independent damage and a stacking movement slow.", "target_type": "attack", "target_attack_id": "splash_melee", "implementation_status": "implemented", "prerequisites": ["splash_melee_frenzy", "time_dilator", "rage_wave_deep_slow"]},
	{"id": "mighty_clap_seismic_fan", "triple_id": "vanguard_seismic_fan", "title": "Seismic Fan", "description": "Fury Strikes emit a broad forward seismic fan after each successful impact.", "effect_summary": "A 68-degree cone reaches beyond the normal melee splash for 0.85x base swing damage.", "target_type": "attack", "target_attack_id": "splash_melee", "implementation_status": "implemented", "prerequisites": ["splash_melee_shockwave", "chain_lightning", "mighty_clap_range"]},
]

var _upgrade_manager: Node
var _ability_manager: Node
var _passive_manager: Node
var _auto_attack: Node
var _selected_evolutions: Array[String] = []


func setup(upgrade_manager: Node, ability_manager: Node, passive_manager: Node = null, auto_attack: Node = null) -> void:
	_upgrade_manager = upgrade_manager
	_ability_manager = ability_manager
	_passive_manager = passive_manager
	_auto_attack = auto_attack
	reset_run_state()
	if _upgrade_manager != null and _upgrade_manager.has_signal("upgrade_applied") and not _upgrade_manager.upgrade_applied.is_connected(_on_upgrade_applied):
		_upgrade_manager.upgrade_applied.connect(_on_upgrade_applied)


func get_available_evolutions() -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for definition: Dictionary in EVOLUTIONS:
		var state := get_evolution_state(str(definition["id"]))
		if bool(state.get("ready", false)) and not bool(state.get("selected", false)) and str(state.get("implementation_status", "placeholder")) == "implemented" and _can_activate_evolution(str(definition["id"])):
			available.append(state)
			evolution_available.emit(state)
	return available


func get_evolution_state(evolution_id: String) -> Dictionary:
	var definition := _get_definition(evolution_id)
	if definition.is_empty():
		return {}
	var prerequisites: Array[Dictionary] = []
	var selected_count := 0
	var completed_count := 0
	for upgrade_id: String in definition["prerequisites"]:
		var upgrade: Dictionary = _upgrade_manager.get_upgrade_definition(upgrade_id) if _upgrade_manager != null and _upgrade_manager.has_method("get_upgrade_definition") else {}
		var current_level := int(upgrade.get("level", 0))
		var required_level := int(upgrade.get("required_level", upgrade.get("max_level", 0)))
		var completed := required_level > 0 and current_level >= required_level
		if current_level > 0:
			selected_count += 1
		if completed:
			completed_count += 1
		prerequisites.append({"upgrade_id": upgrade_id, "title": str(upgrade.get("title", upgrade_id)), "category": str(upgrade.get("category", "")), "current_level": current_level, "required_level": required_level, "maximum_level": int(upgrade.get("max_level", 0)), "completed": completed})
	var selected := is_evolution_selected(evolution_id)
	var is_ready := completed_count == prerequisites.size() and prerequisites.size() == 3
	var state_name := "selected" if selected else ("ready" if is_ready else ("partial" if selected_count > 0 else "locked"))
	return {"id": evolution_id, "evolution_id": evolution_id, "triple_id": str(definition.get("triple_id", "")), "title": str(definition["title"]), "description": str(definition["description"]), "effect_summary": str(definition.get("effect_summary", "")), "target_type": str(definition.get("target_type", "active")), "target_ability_id": str(definition.get("target_ability_id", "")), "target_passive_id": str(definition.get("target_passive_id", "")), "target_attack_id": str(definition.get("target_attack_id", "")), "implementation_status": str(definition.get("implementation_status", "placeholder")), "state": state_name, "selected": selected, "ready": is_ready and not selected, "selected_prerequisite_count": selected_count, "completed_prerequisite_count": completed_count, "total_prerequisite_count": prerequisites.size(), "prerequisites": prerequisites}


func get_evolution_path_state(evolution_id: String) -> Dictionary:
	var state := get_evolution_state(evolution_id)
	if state.is_empty():
		return {}
	var total_progress := 0
	var lines := {"attack": {}, "passive": {}, "active": {}}
	for prerequisite: Dictionary in state["prerequisites"]:
		total_progress += int(prerequisite["current_level"])
		lines[str(prerequisite["category"])] = prerequisite
	state["total_progress"] = total_progress
	state["started_line_count"] = int(state["selected_prerequisite_count"])
	state["completed_line_count"] = int(state["completed_prerequisite_count"])
	state["attack_line"] = lines["attack"]
	state["passive_line"] = lines["passive"]
	state["active_line"] = lines["active"]
	return state


func get_all_evolution_path_states() -> Dictionary:
	var states := {}
	for definition: Dictionary in EVOLUTIONS:
		var evolution_id := str(definition["id"])
		states[evolution_id] = get_evolution_path_state(evolution_id)
	return states


func get_closest_evolution_id() -> String:
	var closest: Dictionary = {}
	for definition: Dictionary in EVOLUTIONS:
		var path := get_evolution_path_state(str(definition["id"]))
		if bool(path.get("selected", false)) or int(path.get("total_progress", 0)) <= 0:
			continue
		if closest.is_empty() or _is_path_closer(path, closest):
			closest = path
	return str(closest.get("id", ""))


func get_closest_evolution_path_state() -> Dictionary:
	var evolution_id := get_closest_evolution_id()
	return get_evolution_path_state(evolution_id) if not evolution_id.is_empty() else {}


func get_upgrade_evolution_context(upgrade_id: String) -> Dictionary:
	if _upgrade_manager == null:
		return {}
	var definition: Dictionary = _upgrade_manager.get_upgrade_definition(upgrade_id)
	var evolution_id := str(definition.get("evolution_id", ""))
	var path := get_evolution_path_state(evolution_id)
	if path.is_empty():
		return {}
	return path


func enrich_upgrade_options(options: Array[Dictionary]) -> Array[Dictionary]:
	var enriched: Array[Dictionary] = []
	for option: Dictionary in options:
		var copy := option.duplicate(true)
		var context := get_upgrade_evolution_context(str(copy.get("id", "")))
		var projection := get_projected_evolution_path_state(str(copy.get("id", "")))
		copy.merge(projection, true)
		copy["evolution_title"] = str(context.get("title", ""))
		copy["related_lines"] = context.get("prerequisites", []).duplicate(true)
		copy["is_new_line"] = int(copy.get("level", 0)) == 0
		enriched.append(copy)
	return enriched


func get_projected_evolution_path_state(upgrade_id: String) -> Dictionary:
	var context := get_upgrade_evolution_context(upgrade_id)
	if context.is_empty() or _upgrade_manager == null:
		return {}
	var current_level := _upgrade_manager.get_upgrade_level(upgrade_id)
	var required_level := _upgrade_manager.get_upgrade_max_level(upgrade_id)
	var projected_level := mini(current_level + 1, required_level)
	var projected_progress := int(context["total_progress"]) + (1 if projected_level > current_level else 0)
	var projected_completed := int(context["completed_line_count"]) + (1 if projected_level == required_level and current_level < required_level else 0)
	return {"evolution_id": context["id"], "current_progress": int(context["total_progress"]), "projected_progress": projected_progress, "current_line_level": current_level, "projected_line_level": projected_level, "current_completed_line_count": int(context["completed_line_count"]), "projected_completed_line_count": projected_completed, "current_state": context["state"], "projected_state": "ready" if projected_completed == 3 else ("partial" if projected_progress > 0 else "locked"), "completes_line": projected_level == required_level and current_level < required_level, "completes_evolution": projected_completed == 3 and not bool(context.get("selected", false))}


func get_all_evolution_states() -> Dictionary:
	var states := {}
	for definition: Dictionary in EVOLUTIONS:
		var evolution_id := str(definition["id"])
		states[evolution_id] = get_evolution_state(evolution_id)
	return states


func apply_evolution(evolution_id: String) -> bool:
	if is_evolution_selected(evolution_id):
		return false
	var state := get_evolution_state(evolution_id)
	if state.is_empty() or not bool(state.get("ready", false)):
		return false
	if str(state.get("implementation_status", "placeholder")) != "implemented":
		return false
	if not _apply_evolution_effect(evolution_id, state):
		return false
	_selected_evolutions.append(evolution_id)
	var selected_state := get_evolution_state(evolution_id)
	evolution_applied.emit(evolution_id, selected_state)
	evolution_state_changed.emit()
	return true


func is_evolution_selected(evolution_id: String) -> bool:
	return evolution_id in _selected_evolutions


func get_applied_evolutions() -> Array[String]:
	return _selected_evolutions.duplicate()


func get_applied_evolution_titles() -> Array[String]:
	var titles: Array[String] = []
	for evolution_id: String in _selected_evolutions:
		var definition := _get_definition(evolution_id)
		titles.append(str(definition.get("title", evolution_id)))
	return titles


func reset_run_state() -> void:
	_selected_evolutions.clear()
	if _auto_attack != null and _auto_attack.has_method("reset_attack_evolution_state"):
		_auto_attack.reset_attack_evolution_state()
	evolution_state_changed.emit()


func refresh_evolution_states() -> void:
	evolution_state_changed.emit()


func _on_upgrade_applied(_upgrade_id: String, _new_level: int) -> void:
	evolution_state_changed.emit()


func _is_upgrade_available(upgrade_id: String) -> bool:
	return not upgrade_id.is_empty() and _upgrade_manager != null and _upgrade_manager.is_upgrade_eligible(upgrade_id)


func _plan_contains(entries: Array[Dictionary], upgrade_id: String) -> bool:
	for entry: Dictionary in entries:
		if str(entry.get("upgrade_id", "")) == upgrade_id:
			return true
	return false


func _is_path_closer(left: Dictionary, right: Dictionary) -> bool:
	if bool(left.get("ready", false)) != bool(right.get("ready", false)):
		return bool(left.get("ready", false))
	if int(left.get("total_progress", 0)) != int(right.get("total_progress", 0)):
		return int(left["total_progress"]) > int(right["total_progress"])
	if int(left.get("completed_line_count", 0)) != int(right.get("completed_line_count", 0)):
		return int(left["completed_line_count"]) > int(right["completed_line_count"])
	return int(left.get("started_line_count", 0)) > int(right.get("started_line_count", 0))


func get_progression_matrix_validation_errors() -> Array[String]:
	if _upgrade_manager == null or not _upgrade_manager.has_method("get_progression_matrix_validation_errors"):
		return ["RunUpgradeManager3D validation API is unavailable."]
	return _upgrade_manager.get_progression_matrix_validation_errors(EVOLUTIONS)


func _get_definition(evolution_id: String) -> Dictionary:
	for definition: Dictionary in EVOLUTIONS:
		if str(definition["id"]) == evolution_id:
			return definition
	return {}


func _can_activate_evolution(evolution_id: String) -> bool:
	var definition := _get_definition(evolution_id)
	match str(definition.get("target_type", "active")):
		"passive": return _passive_manager != null and _passive_manager.has_method("can_apply_passive_evolution") and bool(_passive_manager.can_apply_passive_evolution(evolution_id, str(definition.get("target_passive_id", ""))))
		"attack": return _auto_attack != null and _auto_attack.has_method("can_apply_attack_evolution") and bool(_auto_attack.can_apply_attack_evolution(evolution_id, str(definition.get("target_attack_id", ""))))
		_: return _ability_manager != null and _ability_manager.has_method("can_apply_evolution") and bool(_ability_manager.can_apply_evolution(evolution_id))


func get_applied_evolution_type_counts() -> Dictionary:
	var counts := {"active": 0, "attack": 0, "passive": 0}
	for evolution_id: String in _selected_evolutions:
		var definition := _get_definition(evolution_id)
		var target_type := str(definition.get("target_type", "active"))
		counts[target_type] = int(counts.get(target_type, 0)) + 1
	return counts


func _apply_evolution_effect(evolution_id: String, state: Dictionary) -> bool:
	match str(state.get("target_type", "active")):
		"passive": return _passive_manager != null and _passive_manager.has_method("apply_passive_evolution") and bool(_passive_manager.apply_passive_evolution(evolution_id, str(state.get("target_passive_id", ""))))
		"attack": return _auto_attack != null and _auto_attack.has_method("apply_attack_evolution") and bool(_auto_attack.apply_attack_evolution(evolution_id, str(state.get("target_attack_id", ""))))
		_: return _ability_manager != null and _ability_manager.has_method("apply_evolution") and bool(_ability_manager.apply_evolution(evolution_id))
