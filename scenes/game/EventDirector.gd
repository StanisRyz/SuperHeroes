extends Node

signal event_started(event_data: Dictionary)
signal event_finished(event_id: String)
signal elite_spawn_requested(event_data: Dictionary)
signal miniboss_spawn_requested(event_data: Dictionary)

var run_manager: Node = null
var _triggered_events: Dictionary = {}
var _active_timed_events: Dictionary = {}

# Event schedule definition
var _event_schedule: Array = [
	{
		"id": "runner_rush_30",
		"trigger_time": 30.0,
		"duration": 12.0,
		"announcement": "Runner Rush!",
		"type": "timed",
		"modifier": {"boost_runner_weight": true, "spawn_pressure": 1.3}
	},
	{
		"id": "tank_wave_60",
		"trigger_time": 60.0,
		"duration": 15.0,
		"announcement": "Tank Wave!",
		"type": "timed",
		"modifier": {"boost_tank_weight": true, "max_alive_bonus": 2}
	},
	{
		"id": "elite_90",
		"trigger_time": 90.0,
		"duration": 0.0,
		"announcement": "Elite Incoming!",
		"type": "elite",
		"modifier": {}
	},
	{
		"id": "miniboss_150",
		"trigger_time": 150.0,
		"duration": 0.0,
		"announcement": "Miniboss Incoming!",
		"type": "miniboss",
		"modifier": {}
	},
	{
		"id": "exploder_wave",
		"trigger_time": 180.0,
		"duration": 15.0,
		"announcement": "Exploder Wave!",
		"type": "timed",
		"modifier": {"boost_variant_weights": {"exploder": 4.0}, "spawn_pressure": 1.15}
	},
	{
		"id": "swarm_wave",
		"trigger_time": 240.0,
		"duration": 15.0,
		"announcement": "Swarm Incoming!",
		"type": "timed",
		"modifier": {"boost_variant_weights": {"swarm": 4.0}, "spawn_pressure": 1.35}
	},
	{
		"id": "shielded_wave",
		"trigger_time": 300.0,
		"duration": 18.0,
		"announcement": "Shielded Front!",
		"type": "timed",
		"modifier": {"boost_variant_weights": {"shielded": 4.0}, "max_alive_bonus": 2}
	},
	{
		"id": "support_wave",
		"trigger_time": 360.0,
		"duration": 18.0,
		"announcement": "Support Units!",
		"type": "timed",
		"modifier": {"boost_variant_weights": {"support": 4.0}, "spawn_pressure": 1.15}
	},
]

func setup(new_run_manager: Node) -> void:
	run_manager = new_run_manager
	_triggered_events.clear()
	_active_timed_events.clear()

func _process(delta: float) -> void:
	if run_manager == null:
		return
	# Guard: only run events if run is active
	if "is_run_active" in run_manager and not run_manager.is_run_active:
		return
	var run_time: float = run_manager.run_time
	_check_event_schedule(run_time)
	_tick_active_events(delta)

func _check_event_schedule(run_time: float) -> void:
	for event in _event_schedule:
		var event_id: String = event["id"]
		if _triggered_events.has(event_id):
			continue
		if run_time >= event["trigger_time"]:
			_triggered_events[event_id] = true
			_fire_event(event)

func _fire_event(event: Dictionary) -> void:
	var event_type: String = event.get("type", "timed")
	emit_signal("event_started", event)
	if event_type == "timed":
		_active_timed_events[event["id"]] = {"data": event, "elapsed": 0.0}
	elif event_type == "elite":
		emit_signal("elite_spawn_requested", event)
	elif event_type == "miniboss":
		emit_signal("miniboss_spawn_requested", event)

func _tick_active_events(delta: float) -> void:
	var to_finish: Array = []
	for event_id in _active_timed_events:
		var entry = _active_timed_events[event_id]
		entry["elapsed"] += delta
		if entry["elapsed"] >= entry["data"]["duration"]:
			to_finish.append(event_id)
	for event_id in to_finish:
		_active_timed_events.erase(event_id)
		emit_signal("event_finished", event_id)


func start_final_phase_event() -> void:
	var event_id := "final_phase_pressure"
	if _triggered_events.has(event_id):
		return
	_triggered_events[event_id] = true
	var event_data := {
		"id": event_id,
		"type": "timed",
		"announcement": "",
		"duration": 9999.0,
		"modifier": {
			"spawn_pressure": 1.6,
			"max_alive_bonus": 4,
			"boost_special_weight": true
		}
	}
	_active_timed_events[event_id] = {"data": event_data, "elapsed": 0.0}
	emit_signal("event_started", event_data)
