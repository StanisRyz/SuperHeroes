class_name KnightAbilityManager3D
extends Node

@export var rage_wave_effect_scene: PackedScene = preload("res://scenes3d/effects/RageWaveEffect3D.tscn")
@export var worldbreaker_pulse_effect_scene: PackedScene = preload("res://scenes3d/effects/WorldbreakerPulseEffect3D.tscn")
@export var shield_bash_effect_scene: PackedScene = preload("res://scenes3d/effects/ShieldBashEffect3D.tscn")
@export var crushing_leap_effect_scene: PackedScene = preload("res://scenes3d/effects/CrushingLeapImpactEffect3D.tscn")

enum CastState { IDLE, WINDUP, SCRIPTED_MOTION, RECOVERY, CANCELLED }

const WORLDBREAKER_EVOLUTION_ID := "rage_wave_worldbreaker"
const WORLDBREAKER_PULSES := [
	{"delay": 0.0, "radius_multiplier": 1.0, "damage_multiplier": 1.5, "knockback_force": 7.0},
	{"delay": 0.22, "radius_multiplier": 1.45, "damage_multiplier": 1.25, "knockback_force": 8.5},
	{"delay": 0.44, "radius_multiplier": 1.9, "damage_multiplier": 1.0, "knockback_force": 10.0},
]
const WORLDBREAKER_SLOW := {"movement_speed_multiplier": 0.40}
const WORLDBREAKER_SLOW_DURATION := 2.5

signal ability_cooldown_changed(slot: int, remaining: float, total: float)
signal ability_state_changed(state: Dictionary)
signal ability_cast(slot: int, ability_id: String)
signal rage_changed(current: float, maximum: float, damage_multiplier: float)
signal hero_resource_changed(resource_name: String, current: float, maximum: float)

@export var maximum_rage := 100.0
@export var maximum_damage_multiplier := 1.45
@export var rage_decay_per_second := 4.0
@export var rage_per_damage_taken := 0.5
@export var rage_per_hit := 4.0
@export var wave_damage := 24
@export var wave_radius := 5.0
@export var wave_cooldown := 6.0
@export var bash_damage := 34
@export var bash_range := 4.5
@export var bash_angle := 80.0
@export var bash_cooldown := 7.0
@export var bash_knockback_force := 10.0
@export var bash_knockback_duration := 0.28
@export var leap_damage := 42
@export var leap_radius := 3.5
@export var leap_distance := 5.0
@export var leap_duration := 0.35
@export var leap_cooldown := 9.0

var rage := 0.0
var _player: Player3D
var _auto_attack: KnightMeleeAutoAttack3D
var _enemies: Node3D
var _effects: Node3D
var _visual: KnightVisual
var _cooldowns := {1: 0.0, 2: 0.0, 3: 0.0}
var _leap_landing_pending := false
var _stopped := false
var _active_ability_id := ""
var _cast_direction := Vector3.FORWARD
var _cast_origin := Vector3.ZERO
var _active_slot := 0
var _cast_state := CastState.IDLE
var _cast_elapsed := 0.0
var _cast_maximum := 0.0
var _action_token := 0
var _action_controller: Node
var _active_evolutions: Array[String] = []
var _pending_worldbreaker_pulses: Array[Dictionary] = []

func setup(player: Player3D, auto_attack: KnightMeleeAutoAttack3D, enemies: Node3D, effects: Node3D, visual: KnightVisual) -> void:
	_player = player
	_auto_attack = auto_attack
	_enemies = enemies
	_effects = effects
	_visual = visual
	_action_controller = player.action_controller
	if _action_controller != null and _action_controller.has_signal("action_state_changed") and not _action_controller.action_state_changed.is_connected(_on_action_state_changed):
		_action_controller.action_state_changed.connect(_on_action_state_changed)
	_player.damage_taken.connect(_on_player_damage_taken)
	_auto_attack.attack_impact_resolved.connect(_on_auto_attack_impact)
	_visual.action_impact.connect(_on_action_impact)
	_visual.action_finished.connect(_on_action_finished)
	_update_rage(0.0)

func _process(delta: float) -> void:
	if _stopped or get_tree().paused or _player == null or _player.is_dead():
		return
	_process_worldbreaker_pulses(delta)
	if _cast_state != CastState.IDLE:
		_cast_elapsed += delta
		if _cast_elapsed > _cast_maximum:
			_cancel_active_ability("watchdog", false)
	for slot: int in _cooldowns:
		_cooldowns[slot] = maxf(float(_cooldowns[slot]) - delta, 0.0)
		ability_cooldown_changed.emit(slot, _cooldowns[slot], _cooldown_total(slot))
		ability_state_changed.emit(get_ability_state(slot))
	if rage > 0.0:
		_update_rage(-rage_decay_per_second * delta)
	if _leap_landing_pending and not _player.is_scripted_motion_active():
		_leap_landing_pending = false
		_apply_leap_landing()

func cast_ability_1() -> bool:
	if not _can_cast(1): return false
	return _begin_cast(1, "rage_wave", Vector3.FORWARD)

func cast_ability_2() -> bool:
	if not _can_cast(2): return false
	var direction := _target_direction()
	return _begin_cast(2, "shield_bash", direction)

func cast_ability_3() -> bool:
	if not _can_cast(3): return false
	var direction := _target_direction()
	return _begin_cast(3, "crushing_leap", direction)

func get_ability_state(slot: int) -> Dictionary:
	var blocked_reason := _get_blocked_reason(slot)
	return {"slot": slot, "cooldown_remaining": float(_cooldowns.get(slot, 0.0)), "cooldown_total": _cooldown_total(slot), "display_name": get_ability_name(slot, false), "short_name": get_ability_name(slot, true), "is_ready": blocked_reason.is_empty(), "is_active": _active_slot == slot, "is_blocked": not blocked_reason.is_empty(), "blocked_reason": blocked_reason, "cast_state": _cast_state}
func get_all_ability_states() -> Dictionary:
	return {1: get_ability_state(1), 2: get_ability_state(2), 3: get_ability_state(3)}

func refresh_ability_states() -> void:
	_publish_all_ability_states()


func can_apply_evolution(evolution_id: String) -> bool:
	return evolution_id == WORLDBREAKER_EVOLUTION_ID


func apply_evolution(evolution_id: String) -> bool:
	if not can_apply_evolution(evolution_id):
		return false
	if evolution_id not in _active_evolutions:
		_active_evolutions.append(evolution_id)
	return true


func is_evolution_active(evolution_id: String) -> bool:
	return evolution_id in _active_evolutions

func get_ability_name(slot: int, prefer_short: bool = false) -> String:
	var names := {1: ["Rage Wave", "Wave"], 2: ["Shield Bash", "Bash"], 3: ["Crushing Leap", "Leap"]}
	return names.get(slot, ["Ability", "Ability"])[1 if prefer_short else 0]
func stop() -> void:
	_stopped = true; _pending_worldbreaker_pulses.clear(); _cancel_active_ability("stopped", false); _publish_all_ability_states()
func _can_cast(slot: int) -> bool:
	return _get_blocked_reason(slot).is_empty()

func _get_blocked_reason(slot: int) -> String:
	if _stopped: return "stopped"
	if _player == null or _player.is_dead(): return "dead"
	if get_tree().paused: return "paused"
	if not _active_ability_id.is_empty() or _cast_state != CastState.IDLE: return "casting"
	if float(_cooldowns.get(slot, 0.0)) > 0.0: return "cooldown"
	if _player.is_dashing: return "dash"
	if _player.is_scripted_motion_active(): return "scripted_motion"
	if _action_controller != null and not _action_controller.is_idle():
		var action_state: Dictionary = _action_controller.get_current_action_state()
		return "dash" if str(action_state.get("action_id", "")) == "dash" else "action_busy"
	return ""

func _begin_cast(slot: int, ability_id: String, direction: Vector3) -> bool:
	if ability_id == "crushing_leap" and (_player.is_dashing or _player.is_scripted_motion_active()): return false
	_cast_direction = direction; _cast_origin = _player.global_position
	_action_token = _action_controller.try_begin_ability(ability_id)
	if _action_token == 0: return false
	_auto_attack.interrupt_attack()
	if not _visual.play_ability(ability_id):
		_action_controller.cancel_action(_action_token, "visual_rejected")
		_action_token = 0
		_auto_attack.set_suspended(false)
		_player.release_combat_facing()
		return false
	_active_ability_id = ability_id; _active_slot = slot; _cast_state = CastState.WINDUP; _cast_elapsed = 0.0; _cast_maximum = 2.5 + (leap_duration if ability_id == "crushing_leap" else 0.0)
	_auto_attack.set_suspended(true); _start_cooldown(slot); ability_cast.emit(slot, ability_id); _publish_all_ability_states()
	if ability_id != "rage_wave": _player.lock_combat_facing(direction)
	return true

func _on_action_impact(action_id: String) -> void:
	if action_id != _active_ability_id: return
	if action_id == "rage_wave":
		if is_evolution_active(WORLDBREAKER_EVOLUTION_ID):
			_queue_worldbreaker_pulses(_cast_origin)
		else:
			_apply_area_damage(CombatQuery3D.enemies_in_radius(_enemies, _cast_origin, wave_radius), wave_damage, {"movement_speed_multiplier": 0.55}, 2.0, "rage_wave_slow")
			_spawn_effect(rage_wave_effect_scene, [_cast_origin, wave_radius, 0.35])
	elif action_id == "shield_bash":
		for enemy: Enemy3D in CombatQuery3D.enemies_in_cone(_enemies, _cast_origin, _cast_direction, bash_range, bash_angle):
			var damage := _scaled_damage(bash_damage); enemy.take_damage(damage); enemy.apply_knockback(_cast_direction, bash_knockback_force, bash_knockback_duration); _update_rage(rage_per_hit + damage * 0.05)
		_spawn_effect(shield_bash_effect_scene, [_cast_origin, _cast_direction, bash_range, bash_angle, 0.22])
	elif action_id == "crushing_leap" and not _leap_landing_pending:
		if _player.start_scripted_motion(_action_token, _cast_direction, leap_distance, leap_duration, leap_duration):
			_leap_landing_pending = true; _cast_state = CastState.SCRIPTED_MOTION
		else:
			_cancel_active_ability("leap_motion_failed", true)

func refresh_rage_state() -> void:
	rage = clampf(rage, 0.0, maximum_rage)
	_update_rage(0.0)

func _on_action_finished(action_id: String) -> void:
	if action_id == _active_ability_id and action_id != "crushing_leap": _finish_active_ability()
func _start_cooldown(slot: int) -> void:
	_cooldowns[slot] = _cooldown_total(slot); ability_cooldown_changed.emit(slot, _cooldowns[slot], _cooldown_total(slot)); ability_state_changed.emit(get_ability_state(slot))
func _cooldown_total(slot: int) -> float:
	return wave_cooldown if slot == 1 else (bash_cooldown if slot == 2 else leap_cooldown)
func _target_direction() -> Vector3:
	var target := CombatQuery3D.nearest_living_enemy(_enemies, _player.global_position, INF)
	var direction := target.global_position - _player.global_position if target != null else WorldPlane.horizontal_to_world(_player.get_aim_direction())
	direction.y = 0.0; return direction.normalized() if not direction.is_zero_approx() else Vector3.FORWARD
func _apply_leap_landing() -> void:
	_apply_area_damage(CombatQuery3D.enemies_in_radius(_enemies, _player.global_position, leap_radius), leap_damage, {"movement_speed_multiplier": 0.45, "stun": true}, 1.0, "crushing_leap_stun")
	_spawn_effect(crushing_leap_effect_scene, [_player.global_position, leap_radius, 0.4])
	_finish_active_ability()

func _spawn_effect(effect_scene: PackedScene, arguments: Array) -> void:
	if effect_scene == null or _effects == null: return
	var effect := effect_scene.instantiate()
	_effects.add_child(effect)
	if effect.has_method("setup"):
		effect.callv("setup", arguments)

func _finish_active_ability() -> void:
	_action_controller.finish_action(_action_token); _action_token = 0; _active_ability_id = ""; _active_slot = 0; _leap_landing_pending = false; _cast_state = CastState.IDLE; _cast_elapsed = 0.0; _player.release_combat_facing()
	if not _stopped: _auto_attack.set_suspended(false)
	_publish_all_ability_states()

func _cancel_active_ability(_reason: String, refund_cooldown: bool) -> void:
	if refund_cooldown and _active_slot > 0: _cooldowns[_active_slot] = 0.0
	_player.cancel_scripted_motion(); _finish_active_ability()
func _apply_area_damage(enemies: Array[Enemy3D], base_damage: int, modifier: Dictionary, duration: float, modifier_id: String = "knight_ability") -> void:
	for enemy: Enemy3D in enemies:
		var damage := _scaled_damage(base_damage); enemy.take_damage(damage); enemy.apply_temporary_modifier(modifier_id, modifier, duration); enemy.apply_knockback(enemy.global_position - _player.global_position, 6.0, 0.2); _update_rage(rage_per_hit + damage * 0.05)


func _queue_worldbreaker_pulses(origin: Vector3) -> void:
	for index in WORLDBREAKER_PULSES.size():
		var tuning: Dictionary = WORLDBREAKER_PULSES[index]
		var pulse := {"remaining_delay": float(tuning["delay"]), "origin": origin, "radius": wave_radius * float(tuning["radius_multiplier"]), "base_damage": roundi(wave_damage * float(tuning["damage_multiplier"])), "knockback_force": float(tuning["knockback_force"]), "pulse_index": index + 1}
		if float(pulse["remaining_delay"]) <= 0.0:
			_resolve_worldbreaker_pulse(pulse)
		else:
			_pending_worldbreaker_pulses.append(pulse)


func _process_worldbreaker_pulses(delta: float) -> void:
	for index in range(_pending_worldbreaker_pulses.size() - 1, -1, -1):
		var pulse: Dictionary = _pending_worldbreaker_pulses[index]
		pulse["remaining_delay"] = float(pulse["remaining_delay"]) - delta
		if float(pulse["remaining_delay"]) <= 0.0:
			_pending_worldbreaker_pulses.remove_at(index)
			_resolve_worldbreaker_pulse(pulse)
		else:
			_pending_worldbreaker_pulses[index] = pulse


func _resolve_worldbreaker_pulse(pulse: Dictionary) -> void:
	if _stopped or _enemies == null:
		return
	var origin: Vector3 = pulse["origin"]
	var radius := float(pulse["radius"])
	var base_damage := int(pulse["base_damage"])
	var knockback_force := float(pulse["knockback_force"])
	for enemy: Enemy3D in CombatQuery3D.enemies_in_radius(_enemies, origin, radius):
		if not is_instance_valid(enemy):
			continue
		var damage := _scaled_damage(base_damage)
		enemy.take_damage(damage)
		enemy.apply_temporary_modifier("worldbreaker_slow", WORLDBREAKER_SLOW, WORLDBREAKER_SLOW_DURATION)
		enemy.apply_knockback(enemy.global_position - origin, knockback_force, 0.24)
		_update_rage(rage_per_hit + damage * 0.05)
	_spawn_effect(worldbreaker_pulse_effect_scene, [origin, radius, 0.34, int(pulse["pulse_index"])])


func _exit_tree() -> void:
	_pending_worldbreaker_pulses.clear()

func _scaled_damage(base_damage: int) -> int: return maxi(roundi(base_damage * get_damage_multiplier()), 1)
func _on_player_damage_taken(amount: int) -> void: _update_rage(amount * rage_per_damage_taken)
func _on_auto_attack_impact(hits: int, damage: int) -> void: _update_rage(hits * rage_per_hit + damage * 0.03)
func get_damage_multiplier() -> float: return lerpf(1.0, maximum_damage_multiplier, rage / maxf(maximum_rage, 0.001))
func _update_rage(delta: float) -> void:
	rage = clampf(rage + delta, 0.0, maximum_rage)
	if _auto_attack != null: _auto_attack.set_damage_multiplier(get_damage_multiplier())
	rage_changed.emit(rage, maximum_rage, get_damage_multiplier()); hero_resource_changed.emit("Rage", rage, maximum_rage)

func _on_action_state_changed(_state: Dictionary) -> void:
	_publish_all_ability_states()

func _publish_all_ability_states() -> void:
	for slot in [1, 2, 3]:
		ability_state_changed.emit(get_ability_state(slot))

func get_debug_state() -> Dictionary:
	return {"stopped": _stopped, "active_ability_id": _active_ability_id, "active_slot": _active_slot, "cast_state": _cast_state, "cast_elapsed": _cast_elapsed, "cast_maximum": _cast_maximum, "action_token": _action_token, "cooldowns": _cooldowns.duplicate(), "rage": rage, "maximum_rage": maximum_rage, "damage_multiplier": get_damage_multiplier(), "leap_landing_pending": _leap_landing_pending}
