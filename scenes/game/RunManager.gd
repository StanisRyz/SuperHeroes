extends Node

signal run_time_changed(seconds: float)
signal kill_count_changed(kills: int)
signal run_ended(stats: Dictionary)

var run_time: float = 0.0
var kill_count: int = 0
var is_run_active: bool = true

var _time_emit_accumulator := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	run_time_changed.emit(run_time)
	kill_count_changed.emit(kill_count)


func _process(delta: float) -> void:
	if not is_run_active:
		return

	run_time += delta
	_time_emit_accumulator += delta
	if _time_emit_accumulator >= 0.25:
		_time_emit_accumulator = 0.0
		run_time_changed.emit(run_time)


func register_enemy_kill() -> void:
	if not is_run_active:
		return

	kill_count += 1
	kill_count_changed.emit(kill_count)


func end_run() -> void:
	if not is_run_active:
		return

	is_run_active = false
	run_time_changed.emit(run_time)
	run_ended.emit(get_stats())


func get_stats() -> Dictionary:
	return {
		"run_time": run_time,
		"kill_count": kill_count,
	}
