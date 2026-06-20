extends Node

signal event_started(event_data: Dictionary)
signal event_finished(event_id: String)
signal elite_spawn_requested(event_data: Dictionary)
signal miniboss_spawn_requested(event_data: Dictionary)

var _run_manager: Node = null
var _event_profile: String = "balanced"
var _stopped: bool = false
var _fired_event_ids: Dictionary = {}
var _active_timed_events: Dictionary = {}

# Scheduled events per stage profile.
# type:
#   "timed"        — applies spawn_director modifier for 'duration' seconds, then clears it.
#   "announce_only"— shows announcement, no modifier.
#   "spawn_elite"  — triggers elite_spawn_requested signal.
#   "spawn_miniboss" — triggers miniboss_spawn_requested signal.
const _SCHEDULE: Dictionary = {
	"balanced": [
		{
			"id": "b_warn_1",
			"trigger_time": 75.0,
			"type": "announce_only",
			"announcement": "Emergency wave approaching!",
		},
		{
			"id": "b_elite_1",
			"trigger_time": 90.0,
			"type": "spawn_elite",
			"announcement": "",
		},
		{
			"id": "b_surge_1",
			"trigger_time": 150.0,
			"type": "timed",
			"announcement": "Wave surge!",
			"duration": 30.0,
			"modifier": {"spawn_pressure": 1.4},
		},
		{
			"id": "b_supply_1",
			"trigger_time": 230.0,
			"type": "announce_only",
			"announcement": "Supply drop incoming!",
		},
		{
			"id": "b_elite_2",
			"trigger_time": 300.0,
			"type": "spawn_elite",
			"announcement": "",
		},
		{
			"id": "b_miniboss_1",
			"trigger_time": 420.0,
			"type": "spawn_miniboss",
			"announcement": "",
		},
		{
			"id": "b_surge_2",
			"trigger_time": 480.0,
			"type": "timed",
			"announcement": "Pre-boss surge!",
			"duration": 25.0,
			"modifier": {"spawn_pressure": 1.5},
		},
	],
	"ranged_support": [
		{
			"id": "rs_warn_1",
			"trigger_time": 60.0,
			"type": "announce_only",
			"announcement": "Ranged support detected!",
		},
		{
			"id": "rs_elite_1",
			"trigger_time": 120.0,
			"type": "spawn_elite",
			"announcement": "",
		},
		{
			"id": "rs_surge_1",
			"trigger_time": 200.0,
			"type": "timed",
			"announcement": "Lab assault!",
			"duration": 30.0,
			"modifier": {"spawn_pressure": 1.35, "boost_variant_weights": {"shooter": 2.0, "support": 2.0}},
		},
		{
			"id": "rs_warn_2",
			"trigger_time": 290.0,
			"type": "announce_only",
			"announcement": "Reactor under threat!",
		},
		{
			"id": "rs_miniboss_1",
			"trigger_time": 360.0,
			"type": "spawn_miniboss",
			"announcement": "",
		},
		{
			"id": "rs_surge_2",
			"trigger_time": 460.0,
			"type": "timed",
			"announcement": "Final lab assault!",
			"duration": 30.0,
			"modifier": {"spawn_pressure": 1.5, "boost_variant_weights": {"shooter": 2.0, "support": 2.0}},
		},
	],
	"swarm_exploder": [
		{
			"id": "se_warn_1",
			"trigger_time": 60.0,
			"type": "announce_only",
			"announcement": "Swarms detected at the portals!",
		},
		{
			"id": "se_elite_1",
			"trigger_time": 90.0,
			"type": "spawn_elite",
			"announcement": "",
		},
		{
			"id": "se_surge_1",
			"trigger_time": 180.0,
			"type": "timed",
			"announcement": "Swarm rush!",
			"duration": 25.0,
			"modifier": {"spawn_pressure": 1.35, "boost_variant_weights": {"swarm": 2.0, "exploder": 1.8}},
		},
		{
			"id": "se_miniboss_1",
			"trigger_time": 360.0,
			"type": "spawn_miniboss",
			"announcement": "",
		},
		{
			"id": "se_surge_2",
			"trigger_time": 450.0,
			"type": "timed",
			"announcement": "Final siege!",
			"duration": 25.0,
			"modifier": {"spawn_pressure": 1.5},
		},
	],
}


func setup(new_run_manager: Node) -> void:
	_run_manager = new_run_manager
	_fired_event_ids.clear()
	_active_timed_events.clear()
	_stopped = false


func set_event_profile(profile: String) -> void:
	_event_profile = profile


func stop_for_final_boss_encounter() -> void:
	_stopped = true
	var ids_to_clear: Array[String] = []
	for evt_id in _active_timed_events:
		ids_to_clear.append(str(evt_id))
	for evt_id in ids_to_clear:
		_active_timed_events.erase(evt_id)
		event_finished.emit(evt_id)


func start_final_phase_event() -> void:
	if _stopped:
		return
	var final_event := {
		"id": "final_phase_pressure",
		"type": "timed",
		"announcement": "",
		"duration": 60.0,
		"modifier": {"spawn_pressure": 1.6, "max_alive_bonus": 5},
	}
	event_started.emit(final_event)
	_active_timed_events["final_phase_pressure"] = 60.0


func _process(delta: float) -> void:
	if _stopped or _run_manager == null:
		return

	var run_time := _get_run_time()

	var schedule: Array = _get_profile_schedule()
	for event in schedule:
		var event_id := str(event.get("id", ""))
		if _fired_event_ids.has(event_id):
			continue
		if run_time >= float(event.get("trigger_time", 0.0)):
			_fire_event(event)
			_fired_event_ids[event_id] = true

	var finished_ids: Array[String] = []
	for evt_id in _active_timed_events:
		_active_timed_events[evt_id] = float(_active_timed_events[evt_id]) - delta
		if float(_active_timed_events[evt_id]) <= 0.0:
			finished_ids.append(str(evt_id))
	for evt_id in finished_ids:
		_active_timed_events.erase(evt_id)
		event_finished.emit(evt_id)


func _get_profile_schedule() -> Array:
	if _SCHEDULE.has(_event_profile):
		return _SCHEDULE[_event_profile] as Array
	return _SCHEDULE.get("balanced", []) as Array


func _fire_event(event: Dictionary) -> void:
	var event_type := str(event.get("type", "announce_only"))
	match event_type:
		"timed":
			event_started.emit(event)
			_active_timed_events[str(event.get("id", ""))] = float(event.get("duration", 10.0))
		"announce_only":
			event_started.emit(event)
		"spawn_elite":
			elite_spawn_requested.emit(event)
		"spawn_miniboss":
			miniboss_spawn_requested.emit(event)


func _get_run_time() -> float:
	if _run_manager == null:
		return 0.0
	var value = _run_manager.get("run_time")
	return float(value) if value != null else 0.0


func debug_get_event_state() -> Dictionary:
	return {
		"profile": _event_profile,
		"stopped": _stopped,
		"fired_count": _fired_event_ids.size(),
		"active_timed": _active_timed_events.duplicate(),
	}
