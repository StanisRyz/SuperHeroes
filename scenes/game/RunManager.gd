extends Node

signal run_time_changed(seconds: float)
signal kill_count_changed(kills: int)
signal run_ended(stats: Dictionary)
signal final_phase_started
signal victory_reached(stats: Dictionary)
signal special_kill_count_changed(elites: int, minibosses: int)

@export var target_run_time: float = 600.0
@export var final_phase_start_time: float = 540.0
@export var victory_requires_final_miniboss_defeated: bool = false
@export var debug_target_run_time: float = 60.0
@export var use_debug_run_duration: bool = false

var run_time: float = 0.0
var kill_count: int = 0
var is_run_active: bool = true
var is_final_phase_active: bool = false
var has_victory: bool = false
var elite_kill_count: int = 0
var miniboss_kill_count: int = 0

var _time_emit_accumulator := 0.0
var _effective_target_run_time: float = 600.0
var _effective_final_phase_time: float = 540.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	if use_debug_run_duration:
		_effective_target_run_time = debug_target_run_time
		var ratio := final_phase_start_time / maxf(target_run_time, 1.0)
		_effective_final_phase_time = debug_target_run_time * ratio
	else:
		_effective_target_run_time = target_run_time
		_effective_final_phase_time = final_phase_start_time
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

	if not is_final_phase_active and run_time >= _effective_final_phase_time:
		is_final_phase_active = true
		final_phase_started.emit()

	if not has_victory and run_time >= _effective_target_run_time:
		if can_trigger_victory():
			trigger_victory()


func register_enemy_kill() -> void:
	if not is_run_active:
		return
	kill_count += 1
	kill_count_changed.emit(kill_count)


func register_elite_kill() -> void:
	if not is_run_active:
		return
	elite_kill_count += 1
	special_kill_count_changed.emit(elite_kill_count, miniboss_kill_count)


func register_miniboss_kill() -> void:
	if not is_run_active:
		return
	miniboss_kill_count += 1
	special_kill_count_changed.emit(elite_kill_count, miniboss_kill_count)
	if victory_requires_final_miniboss_defeated and run_time >= _effective_target_run_time and not has_victory:
		trigger_victory()


func trigger_victory() -> void:
	if has_victory or not is_run_active:
		return
	is_run_active = false
	has_victory = true
	run_time_changed.emit(run_time)
	victory_reached.emit(get_stats())


func can_trigger_victory() -> bool:
	if has_victory or not is_run_active:
		return false
	if victory_requires_final_miniboss_defeated:
		return miniboss_kill_count > 0
	return true


func get_target_run_time() -> float:
	return _effective_target_run_time


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
		"elite_kill_count": elite_kill_count,
		"miniboss_kill_count": miniboss_kill_count,
		"target_run_time": _effective_target_run_time,
		"has_victory": has_victory,
	}
