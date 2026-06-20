extends Node

signal objective_completed
signal objective_failed
signal objective_state_changed(state: Dictionary)

var _objective_type: String = "survival"
var _objective_data: Dictionary = {}
var _arena: Node = null
var _player: Node2D = null
var _enemy_container: Node = null
var _playable_rect: Rect2
var _spawn_director: Node = null

var _defense_objective: Node = null
var _portals: Array = []
var _portals_total: int = 0
var _portals_destroyed: int = 0
var _objective_done: bool = false
var _objective_failed_flag: bool = false

const PORTAL_SPREAD_POSITIONS: Array = [
	Vector2(-450, -380),
	Vector2(490, -310),
	Vector2(-60, 510),
	Vector2(-490, 310),
	Vector2(450, 390),
]


func setup(stage_data: Dictionary, arena: Node, player: Node, enemy_container: Node, playable_rect: Rect2) -> void:
	_objective_type = str(stage_data.get("objective_type", "survival"))
	_objective_data = stage_data.get("objective_data", {})
	_arena = arena
	_enemy_container = enemy_container
	_playable_rect = playable_rect
	_spawn_director = _arena.get_node_or_null("SpawnDirector") if _arena != null else null

	if player is Node2D:
		_player = player as Node2D

	match _objective_type:
		"defense":
			_spawn_defense_objective()
		"destroy_structures":
			_spawn_portals()
			_apply_portal_pressure()


func _spawn_defense_objective() -> void:
	var def_script: Script = load("res://scenes/objectives/DefenseObjective.gd")
	if def_script == null:
		push_warning("StageObjectiveManager: DefenseObjective.gd not found.")
		return

	_defense_objective = def_script.new()
	_defense_objective.name = "DefenseObjective"
	_arena.add_child(_defense_objective)

	if _defense_objective is Node2D:
		(_defense_objective as Node2D).global_position = Vector2(0.0, -110.0)

	var hp := int(_objective_data.get("target_hp", 300))
	var disp_name := str(_objective_data.get("target_display_name", "Lab Reactor"))
	var dmg_rate := float(_objective_data.get("damage_per_enemy_per_second", 15.0))

	if _defense_objective.has_method("setup"):
		_defense_objective.setup(hp, disp_name, dmg_rate)

	if _defense_objective.has_signal("health_changed"):
		_defense_objective.health_changed.connect(_on_defense_health_changed)
	if _defense_objective.has_signal("objective_destroyed"):
		_defense_objective.objective_destroyed.connect(_on_defense_objective_destroyed)

	objective_state_changed.emit(get_objective_state())


func _spawn_portals() -> void:
	var portal_script: Script = load("res://scenes/objectives/PortalObjective.gd")
	if portal_script == null:
		push_warning("StageObjectiveManager: PortalObjective.gd not found.")
		return

	_portals_total = int(_objective_data.get("portal_count", 3))
	var portal_hp := int(_objective_data.get("portal_hp", 150))
	var portal_name := str(_objective_data.get("portal_display_name", "Dark Portal"))

	for i in range(_portals_total):
		var portal: Node = portal_script.new()
		portal.name = "Portal_%d" % i
		_arena.add_child(portal)

		if portal is Node2D:
			(portal as Node2D).global_position = PORTAL_SPREAD_POSITIONS[i % PORTAL_SPREAD_POSITIONS.size()]

		if portal.has_method("setup"):
			portal.setup(portal_hp, portal_name)

		if portal.has_signal("portal_destroyed"):
			portal.portal_destroyed.connect(_on_portal_destroyed)

		_portals.append(portal)

	objective_state_changed.emit(get_objective_state())


func _apply_portal_pressure() -> void:
	if _spawn_director == null or not _spawn_director.has_method("apply_event_modifier"):
		return
	var alive := _portals_total - _portals_destroyed
	if alive <= 0:
		_clear_portal_pressure()
		return
	var pressure_bonus := clampf(float(alive) / float(maxi(_portals_total, 1)) * 0.55, 0.0, 0.55)
	_spawn_director.apply_event_modifier({
		"id": "portal_pressure",
		"modifier": {
			"spawn_pressure": 1.0 + pressure_bonus,
			"boost_variant_weights": {"runner": 1.3, "exploder": 1.3},
		},
	})


func _clear_portal_pressure() -> void:
	if _spawn_director != null and _spawn_director.has_method("clear_event_modifier"):
		_spawn_director.clear_event_modifier("portal_pressure")


func _on_defense_health_changed(_current_hp: int, _max_hp: int) -> void:
	objective_state_changed.emit(get_objective_state())


func _on_defense_objective_destroyed() -> void:
	if not _objective_done and not _objective_failed_flag:
		_objective_failed_flag = true
		_objective_done = true
		objective_failed.emit()


func _on_portal_destroyed(_portal: Node) -> void:
	_portals_destroyed += 1
	objective_state_changed.emit(get_objective_state())
	_apply_portal_pressure()
	if _portals_destroyed >= _portals_total and not _objective_done:
		_objective_done = true
		_clear_portal_pressure()
		objective_completed.emit()


func get_objective_state() -> Dictionary:
	var state: Dictionary = {
		"objective_type": _objective_type,
		"objective_done": _objective_done,
	}
	match _objective_type:
		"defense":
			if _defense_objective != null and is_instance_valid(_defense_objective):
				state["defense_hp"] = int(_defense_objective.get("current_health") or 0)
				state["defense_max_hp"] = int(_defense_objective.get("max_health") or 1)
				state["defense_display_name"] = str(_defense_objective.get("display_name") or "Reactor")
			else:
				state["defense_hp"] = 0
				state["defense_max_hp"] = 1
				state["defense_display_name"] = "Reactor"
			state["failed"] = _objective_failed_flag
		"destroy_structures":
			state["portals_destroyed"] = _portals_destroyed
			state["portals_total"] = _portals_total
	return state


func debug_get_objective_state() -> Dictionary:
	var state := get_objective_state()
	state["portals_alive"] = maxi(_portals_total - _portals_destroyed, 0)
	state["portal_pressure_active"] = _objective_type == "destroy_structures" and not _objective_done
	if _spawn_director != null:
		var mods = _spawn_director.get("active_event_modifiers")
		if mods is Dictionary:
			state["portal_modifier"] = (mods as Dictionary).get("portal_pressure", {})
		else:
			state["portal_modifier"] = {}
	return state


func cleanup() -> void:
	_clear_portal_pressure()

	if _defense_objective != null and is_instance_valid(_defense_objective):
		_defense_objective.queue_free()
	_defense_objective = null

	for portal in _portals:
		if is_instance_valid(portal):
			portal.queue_free()
	_portals.clear()
