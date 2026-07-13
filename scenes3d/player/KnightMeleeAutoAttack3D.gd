class_name KnightMeleeAutoAttack3D
extends Node

signal attack_impact_resolved(hit_count: int, total_damage: int)

@export var attack_damage: int = 14
@export var attack_interval: float = 0.8
@export var targeting_range: float = 3.2
@export var attack_radius: float = 2.0
@export_range(1.0, 360.0, 1.0) var attack_arc: float = 110.0
@export var knockback_force: float = 5.0
@export var knockback_duration: float = 0.16

var _player: Player3D
var _enemy_container: Node3D
var _knight_visual: KnightVisual
var _cooldown_remaining: float = 0.0
var _attack_active: bool = false
var _attack_direction: Vector3 = Vector3.FORWARD
var _damaged_enemies: Array[Enemy3D] = []
var _damage_multiplier: float = 1.0
var _suspended: bool = false
var _attack_speed_modifiers: Dictionary = {}
var _fury_combo_enabled := false
var _fury_combo_bonus_per_stack := 0.0
var _fury_combo_stacks := 0
var _fury_combo_decay_remaining := 0.0

const FURY_COMBO_MAX_STACKS := 5
const FURY_COMBO_DECAY_DURATION := 3.0


func set_suspended(value: bool) -> void:
	_suspended = value


func is_suspended() -> bool:
	return _suspended


func cancel_current_attack() -> void:
	_attack_active = false
	_damaged_enemies.clear()
	if _player != null:
		_player.release_combat_facing()

func interrupt_attack() -> void:
	if _knight_visual != null:
		_knight_visual.cancel_attack()
	cancel_current_attack()

func set_damage_multiplier(multiplier: float) -> void:
	_damage_multiplier = maxf(multiplier, 0.0)


func set_temporary_attack_speed_modifier(modifier_id: String, multiplier: float, duration: float) -> void:
	if modifier_id.is_empty():
		return
	_attack_speed_modifiers[modifier_id] = {"multiplier": maxf(multiplier, 0.01), "remaining": maxf(duration, 0.0)}


func clear_temporary_attack_speed_modifier(modifier_id: String) -> void:
	_attack_speed_modifiers.erase(modifier_id)


func upgrade_fury_combo(bonus_per_level: float) -> bool:
	if bonus_per_level <= 0.0:
		return false
	_fury_combo_enabled = true
	_fury_combo_bonus_per_stack += bonus_per_level
	return true


func get_debug_state() -> Dictionary:
	return {"suspended": _suspended, "attack_active": _attack_active, "cooldown_remaining": _cooldown_remaining, "attack_direction": _attack_direction, "damage_multiplier": _damage_multiplier, "damaged_enemy_count": _damaged_enemies.size()}


func setup(player: Player3D, enemy_container: Node3D, knight_visual: KnightVisual) -> void:
	_player = player
	_enemy_container = enemy_container
	_knight_visual = knight_visual
	_reset_fury_combo(true)
	if _knight_visual != null and not _knight_visual.attack_impact.is_connected(_on_attack_impact):
		_knight_visual.attack_impact.connect(_on_attack_impact)
	if _knight_visual != null and not _knight_visual.attack_finished.is_connected(_on_attack_finished):
		_knight_visual.attack_finished.connect(_on_attack_finished)


func stop_attacking() -> void:
	_attack_active = false
	_damaged_enemies.clear()
	if _player != null:
		_player.release_combat_facing()
	_reset_fury_combo(true)


func _process(delta: float) -> void:
	_process_attack_speed_modifiers(delta)
	_process_fury_combo(delta)
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)
	if _suspended or _attack_active or _cooldown_remaining > 0.0 or _player == null or _player.is_dead() or get_tree().paused or not _player.action_controller.is_idle():
		return
	var target: Enemy3D = _find_nearest_target()
	if target == null:
		return
	_attack_direction = target.global_position - _player.global_position
	_attack_direction.y = 0.0
	if _attack_direction.is_zero_approx():
		return
	_attack_direction = _attack_direction.normalized()
	if _knight_visual != null and _knight_visual.play_attack():
		_attack_active = true
		_cooldown_remaining = _get_effective_attack_interval()
		_damaged_enemies.clear()
		_player.lock_combat_facing(_attack_direction)


func _find_nearest_target() -> Enemy3D:
	return CombatQuery3D.nearest_living_enemy(_enemy_container, _player.global_position, targeting_range)


func _on_attack_impact() -> void:
	if not _attack_active or _player == null or _enemy_container == null:
		return
	var hit_count := 0
	var total_damage := 0
	for enemy: Enemy3D in CombatQuery3D.enemies_in_cone(_enemy_container, _player.global_position, _attack_direction, attack_radius, attack_arc):
		if enemy in _damaged_enemies:
			continue
		var offset := enemy.global_position - _player.global_position
		offset.y = 0.0
		_damaged_enemies.append(enemy)
		var damage := maxi(roundi(attack_damage * _damage_multiplier * _get_fury_combo_multiplier()), 1)
		enemy.take_damage(damage)
		enemy.apply_knockback(offset, knockback_force, knockback_duration)
		hit_count += 1
		total_damage += damage
	if hit_count > 0:
		_add_fury_combo_stack()
	attack_impact_resolved.emit(hit_count, total_damage)


func _on_attack_finished() -> void:
	if not _attack_active:
		return
	_attack_active = false
	_damaged_enemies.clear()
	if _player != null:
		_player.release_combat_facing()


func _process_attack_speed_modifiers(delta: float) -> void:
	for modifier_id: String in _attack_speed_modifiers.keys():
		var modifier: Dictionary = _attack_speed_modifiers[modifier_id]
		modifier["remaining"] = float(modifier["remaining"]) - delta
		if float(modifier["remaining"]) <= 0.0:
			_attack_speed_modifiers.erase(modifier_id)
		else:
			_attack_speed_modifiers[modifier_id] = modifier


func _get_effective_attack_interval() -> float:
	var multiplier := 1.0
	for modifier: Dictionary in _attack_speed_modifiers.values():
		multiplier *= float(modifier.get("multiplier", 1.0))
	return attack_interval / maxf(multiplier, 0.01)


func _process_fury_combo(delta: float) -> void:
	if _fury_combo_stacks <= 0:
		return
	_fury_combo_decay_remaining = maxf(_fury_combo_decay_remaining - delta, 0.0)
	if _fury_combo_decay_remaining <= 0.0:
		_fury_combo_stacks = 0


func _add_fury_combo_stack() -> void:
	if not _fury_combo_enabled:
		return
	_fury_combo_stacks = mini(_fury_combo_stacks + 1, FURY_COMBO_MAX_STACKS)
	_fury_combo_decay_remaining = FURY_COMBO_DECAY_DURATION


func _get_fury_combo_multiplier() -> float:
	return 1.0 + float(_fury_combo_stacks) * _fury_combo_bonus_per_stack


func _reset_fury_combo(clear_upgrade: bool = false) -> void:
	_fury_combo_stacks = 0
	_fury_combo_decay_remaining = 0.0
	if clear_upgrade:
		_fury_combo_enabled = false
		_fury_combo_bonus_per_stack = 0.0


func _exit_tree() -> void:
	_reset_fury_combo(true)
