class_name CharacterVisualController
extends Node3D

## Presentation-only animation state controller shared by animated 3D characters.

signal attack_started
signal attack_impact
signal attack_finished
signal death_animation_finished
signal action_started(action_id: String)
signal action_impact(action_id: String)
signal action_finished(action_id: String)

@export_category("Animation mapping")
@export var idle_animation: StringName = &"kaykit/Idle_A"
@export var run_animation: StringName = &"kaykit/Running_A"
@export var attack_animation: StringName = &"kaykit/Use_Item"
@export var hit_animation: StringName = &"kaykit/Hit_A"
@export var death_animation: StringName = &"kaykit/Death_A"
@export_range(0.0, 1.0, 0.01) var attack_impact_normalized_time: float = 0.5

var _animation_player: AnimationPlayer = null
var _locomotion_amount: float = 0.0
var _active_one_shot: StringName = &""
var _attack_impact_emitted: bool = false
var _death_visual_active: bool = false
var _death_animation_finished_emitted: bool = false
var _active_action_id := ""
var _active_action_impact := 0.5
var _action_impact_emitted := false


func configure_animation_player(animation_player: AnimationPlayer) -> void:
	if _animation_player != null and _animation_player.animation_finished.is_connected(_on_animation_finished):
		_animation_player.animation_finished.disconnect(_on_animation_finished)
	_animation_player = animation_player
	if _animation_player != null and not _animation_player.animation_finished.is_connected(_on_animation_finished):
		_animation_player.animation_finished.connect(_on_animation_finished)
	reset_visual_state()


func set_locomotion_amount(amount: float) -> void:
	_locomotion_amount = clampf(amount, 0.0, 1.0)
	if not _death_visual_active and _active_one_shot == &"":
		_play_locomotion()


func play_attack() -> bool:
	if _death_visual_active or _active_one_shot != &"" or not _has_animation(attack_animation):
		return false
	_active_one_shot = attack_animation
	_attack_impact_emitted = false
	_animation_player.play(attack_animation)
	attack_started.emit()
	return true


func play_action(action_id: String, animation_name: StringName, impact_normalized_time: float) -> bool:
	if _death_visual_active or _active_one_shot != &"" or not _has_animation(animation_name):
		return false
	_active_one_shot = animation_name
	_active_action_id = action_id
	_active_action_impact = clampf(impact_normalized_time, 0.0, 1.0)
	_action_impact_emitted = false
	_animation_player.play(animation_name)
	action_started.emit(action_id)
	return true


func play_hit() -> bool:
	if _death_visual_active or _active_one_shot != &"" or not _has_animation(hit_animation):
		return false
	_active_one_shot = hit_animation
	_animation_player.play(hit_animation)
	return true


func play_death() -> bool:
	if _death_visual_active:
		return false
	_death_visual_active = true
	_active_one_shot = death_animation
	if _has_animation(death_animation):
		_animation_player.play(death_animation)
	else:
		_emit_death_animation_finished_once()
	return true


func reset_visual_state() -> void:
	_active_one_shot = &""
	_attack_impact_emitted = false
	_death_visual_active = false
	_death_animation_finished_emitted = false
	_play_locomotion()


func is_death_visual_active() -> bool:
	return _death_visual_active


func _process(_delta: float) -> void:
	if not _active_action_id.is_empty() and not _action_impact_emitted and _animation_player != null:
		var action_animation := _animation_player.get_animation(_active_one_shot)
		if action_animation != null and _animation_player.current_animation_position >= action_animation.length * _active_action_impact:
			_action_impact_emitted = true
			action_impact.emit(_active_action_id)
	if _active_one_shot != attack_animation or _attack_impact_emitted or _animation_player == null:
		return
	var animation: Animation = _animation_player.get_animation(attack_animation)
	if animation != null and _animation_player.current_animation_position >= animation.length * attack_impact_normalized_time:
		_attack_impact_emitted = true
		attack_impact.emit()


func _play_locomotion() -> void:
	if _animation_player == null or _death_visual_active or _active_one_shot != &"":
		return
	var next_animation: StringName = run_animation if _locomotion_amount > 0.05 else idle_animation
	if not _has_animation(next_animation):
		return
	if _animation_player.current_animation != next_animation or not _animation_player.is_playing():
		_animation_player.play(next_animation, 0.12)


func _has_animation(animation_name: StringName) -> bool:
	return _animation_player != null and animation_name != &"" and _animation_player.has_animation(animation_name)


func _on_animation_finished(animation_name: StringName) -> void:
	if not _active_action_id.is_empty() and animation_name == _active_one_shot:
		if not _action_impact_emitted:
			_action_impact_emitted = true
			action_impact.emit(_active_action_id)
		var finished_action := _active_action_id
		_active_action_id = ""
		_active_one_shot = &""
		action_finished.emit(finished_action)
		_play_locomotion()
		return
	if animation_name == attack_animation and _active_one_shot == attack_animation:
		if not _attack_impact_emitted:
			_attack_impact_emitted = true
			attack_impact.emit()
		_active_one_shot = &""
		attack_finished.emit()
		_play_locomotion()
	elif animation_name == hit_animation and _active_one_shot == hit_animation:
		_active_one_shot = &""
		_play_locomotion()
	elif animation_name == death_animation and _death_visual_active:
		_emit_death_animation_finished_once()


func _emit_death_animation_finished_once() -> void:
	if _death_animation_finished_emitted:
		return
	_death_animation_finished_emitted = true
	death_animation_finished.emit()
