class_name PlayerActionDebugTracer3D
extends Node

@export var tracing_enabled := true
@export var console_output := true
@export var file_output := true
@export var heartbeat_interval := 1.0
@export var anomaly_detection := true
@export var maximum_in_memory_events := 200

var _controller: Node
var _player: Node
var _ability: Node
var _auto_attack: Node
var _visual: Node
var _sequence := 0
var _elapsed := 0.0
var _heartbeat := 0.0
var _events: Array[Dictionary] = []
var _file: FileAccess

func setup(controller: Node, player: Node, ability: Node, auto_attack: Node, visual: Node) -> void:
	_controller = controller; _player = player; _ability = ability; _auto_attack = auto_attack; _visual = visual
	if file_output:
		var path := "user://action_trace_%s.log" % Time.get_datetime_string_from_system().replace(":", "-")
		_file = FileAccess.open(path, FileAccess.WRITE)
		print("[ACTION_TRACE] file=%s" % path)
	_record("Tracer", "started", {}, true)

func _process(delta: float) -> void:
	if not tracing_enabled: return
	_elapsed += delta; _heartbeat += delta
	if _heartbeat >= heartbeat_interval:
		_heartbeat = 0.0; _record("Tracer", "heartbeat", _snapshot(), false)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F8: capture_snapshot()
		elif event.keycode == KEY_F9: tracing_enabled = not tracing_enabled; print("[ACTION_TRACE] tracing=%s" % tracing_enabled)
		elif event.keycode == KEY_F10: _events.clear(); _record("Tracer", "section_reset", {}, true)

func capture_snapshot() -> void:
	_record("Tracer", "snapshot", _snapshot(), true)

func _snapshot() -> Dictionary:
	return {"paused": get_tree().paused, "frame": Engine.get_process_frames(), "controller": _debug(_controller), "player": _debug(_player), "ability": _debug(_ability), "autoattack": _debug(_auto_attack), "visual": _debug(_visual)}

func _debug(node: Node) -> Dictionary:
	return node.get_debug_state() if node != null and node.has_method("get_debug_state") else {}

func _record(source: String, event_name: String, data: Dictionary, flush: bool) -> void:
	_sequence += 1
	var event := {"sequence": _sequence, "time": snappedf(_elapsed, 0.001), "source": source, "event": event_name, "data": data}
	_events.append(event)
	if _events.size() > maximum_in_memory_events: _events.pop_front()
	var line := "[ACTION_TRACE] %s" % JSON.stringify(event)
	if console_output: print(line)
	if _file != null: _file.store_line(line); if flush: _file.flush()

func _exit_tree() -> void:
	if _file != null: _file.close()
