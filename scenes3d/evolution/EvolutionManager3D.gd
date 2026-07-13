class_name EvolutionManager3D
extends Node

signal evolution_available(evolution_data: Dictionary)
signal evolution_applied(evolution_id: String, evolution_data: Dictionary)
signal evolution_state_changed

const EVOLUTIONS: Array[Dictionary] = [
	{"id": "rage_wave_worldbreaker", "title": "Worldbreaker", "description": "Rage Wave erupts three times, with each pulse expanding farther and striking enemies again.", "target_ability_id": "rage_wave", "implementation_status": "implemented", "prerequisites": ["sword_arc", "rage_max", "wave_radius"]},
	{"id": "shield_bash_rampage_impact", "title": "Rampage Impact", "description": "Shield Bash unleashes a wider heavy impact followed by a delayed second shockwave.", "target_ability_id": "shield_bash", "implementation_status": "implemented", "prerequisites": ["sword_knockback", "rage_multiplier", "bash_knockback"]},
	{"id": "crushing_leap_meteor_crash", "title": "Meteor Crash", "description": "Crushing Leap evolution. Gameplay effect deferred to Stage 1.7.4.", "target_ability_id": "crushing_leap", "implementation_status": "placeholder", "prerequisites": ["sword_damage", "rage_decay", "leap_damage"]},
]

var _upgrade_manager: Node
var _ability_manager: Node
var _selected_evolutions: Array[String] = []


func setup(upgrade_manager: Node, ability_manager: Node) -> void:
	_upgrade_manager = upgrade_manager
	_ability_manager = ability_manager
	reset_run_state()


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
	return {"id": evolution_id, "evolution_id": evolution_id, "title": str(definition["title"]), "description": str(definition["description"]), "target_ability_id": str(definition["target_ability_id"]), "implementation_status": str(definition.get("implementation_status", "placeholder")), "state": state_name, "selected": selected, "ready": is_ready and not selected, "selected_prerequisite_count": selected_count, "completed_prerequisite_count": completed_count, "total_prerequisite_count": prerequisites.size(), "prerequisites": prerequisites}


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
	if str(state.get("implementation_status", "placeholder")) != "implemented" or _ability_manager == null or not _ability_manager.has_method("apply_evolution"):
		return false
	if not bool(_ability_manager.apply_evolution(evolution_id)):
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
	evolution_state_changed.emit()


func refresh_evolution_states() -> void:
	evolution_state_changed.emit()


func _get_definition(evolution_id: String) -> Dictionary:
	for definition: Dictionary in EVOLUTIONS:
		if str(definition["id"]) == evolution_id:
			return definition
	return {}


func _can_activate_evolution(evolution_id: String) -> bool:
	return _ability_manager != null and _ability_manager.has_method("can_apply_evolution") and bool(_ability_manager.can_apply_evolution(evolution_id))
