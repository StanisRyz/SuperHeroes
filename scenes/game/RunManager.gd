extends Node

signal run_time_changed(seconds: float)
signal kill_count_changed(kills: int)
signal run_ended(stats: Dictionary)
signal final_phase_started
signal victory_reached(stats: Dictionary)
signal special_kill_count_changed(elites: int, minibosses: int)
signal target_time_reached
signal final_boss_required_changed(required: bool)
signal final_boss_state_changed(spawned: bool, defeated: bool)

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
var final_boss_required: bool = true
var final_boss_spawned: bool = false
var final_boss_defeated: bool = false

var _time_emit_accumulator := 0.0
var _effective_target_run_time: float = 600.0
var _effective_final_phase_time: float = 540.0
var _boss_phase_triggered: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_recalculate_effective_times()
	run_time_changed.emit(run_time)
	kill_count_changed.emit(kill_count)


func apply_run_tuning(new_target_run_time: float, new_final_phase_start_time: float) -> void:
	target_run_time = maxf(new_target_run_time, 1.0)
	final_phase_start_time = clampf(new_final_phase_start_time, 0.0, target_run_time)
	_recalculate_effective_times()
	run_time_changed.emit(run_time)


func apply_stage_run_settings(settings: Dictionary) -> void:
	if settings.has("target_run_time"):
		target_run_time = maxf(float(settings["target_run_time"]), 1.0)
	if settings.has("final_phase_start_time"):
		final_phase_start_time = clampf(float(settings["final_phase_start_time"]), 0.0, target_run_time)
	if settings.has("victory_requires_final_boss"):
		final_boss_required = bool(settings["victory_requires_final_boss"])
		final_boss_required_changed.emit(final_boss_required)
	_recalculate_effective_times()
	run_time_changed.emit(run_time)


func _recalculate_effective_times() -> void:
	if use_debug_run_duration:
		_effective_target_run_time = debug_target_run_time
		var ratio := final_phase_start_time / maxf(target_run_time, 1.0)
		_effective_final_phase_time = debug_target_run_time * ratio
	else:
		_effective_target_run_time = target_run_time
		_effective_final_phase_time = final_phase_start_time


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
		if final_boss_required:
			if not _boss_phase_triggered:
				_boss_phase_triggered = true
				target_time_reached.emit()
		else:
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
	if victory_requires_final_miniboss_defeated and not final_boss_required and run_time >= _effective_target_run_time and not has_victory:
		trigger_victory()


func register_final_boss_spawned() -> void:
	if not is_run_active:
		return
	final_boss_spawned = true
	final_boss_state_changed.emit(final_boss_spawned, final_boss_defeated)


func register_final_boss_defeated() -> void:
	if not is_run_active or has_victory:
		return
	final_boss_defeated = true
	final_boss_state_changed.emit(final_boss_spawned, final_boss_defeated)
	if final_boss_required and _boss_phase_triggered:
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
	if final_boss_required:
		return final_boss_defeated
	if victory_requires_final_miniboss_defeated:
		return miniboss_kill_count > 0
	return true


func mark_boss_phase_triggered() -> void:
	_boss_phase_triggered = true


func get_target_run_time() -> float:
	return _effective_target_run_time


func get_final_phase_start_time() -> float:
	return _effective_final_phase_time


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
		"final_boss_required": final_boss_required,
		"final_boss_spawned": final_boss_spawned,
		"final_boss_defeated": final_boss_defeated,
	}
