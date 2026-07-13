class_name KnightMeleeAutoAttack3D
extends Node

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


func setup(player: Player3D, enemy_container: Node3D, knight_visual: KnightVisual) -> void:
	_player = player
	_enemy_container = enemy_container
	_knight_visual = knight_visual
	if _knight_visual != null and not _knight_visual.attack_impact.is_connected(_on_attack_impact):
		_knight_visual.attack_impact.connect(_on_attack_impact)
	if _knight_visual != null and not _knight_visual.attack_finished.is_connected(_on_attack_finished):
		_knight_visual.attack_finished.connect(_on_attack_finished)


func stop_attacking() -> void:
	_attack_active = false
	_damaged_enemies.clear()
	if _player != null:
		_player.release_combat_facing()


func _process(delta: float) -> void:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)
	if _attack_active or _cooldown_remaining > 0.0 or _player == null or _player.is_dead() or get_tree().paused:
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
		_cooldown_remaining = attack_interval
		_damaged_enemies.clear()
		_player.lock_combat_facing(_attack_direction)


func _find_nearest_target() -> Enemy3D:
	if _enemy_container == null:
		return null
	var nearest: Enemy3D = null
	var nearest_distance := targeting_range
	for child: Node in _enemy_container.get_children():
		if not child is Enemy3D:
			continue
		var enemy := child as Enemy3D
		if enemy.is_dead():
			continue
		var offset := enemy.global_position - _player.global_position
		offset.y = 0.0
		var distance := offset.length()
		if distance <= nearest_distance:
			nearest = enemy
			nearest_distance = distance
	return nearest


func _on_attack_impact() -> void:
	if not _attack_active or _player == null or _enemy_container == null:
		return
	var minimum_dot := cos(deg_to_rad(attack_arc * 0.5))
	for child: Node in _enemy_container.get_children():
		if not child is Enemy3D:
			continue
		var enemy := child as Enemy3D
		if enemy.is_dead() or enemy in _damaged_enemies:
			continue
		var offset := enemy.global_position - _player.global_position
		offset.y = 0.0
		if offset.length() > attack_radius or offset.is_zero_approx():
			continue
		if _attack_direction.dot(offset.normalized()) < minimum_dot:
			continue
		_damaged_enemies.append(enemy)
		enemy.take_damage(attack_damage)
		enemy.apply_knockback(offset, knockback_force, knockback_duration)


func _on_attack_finished() -> void:
	if not _attack_active:
		return
	_attack_active = false
	_damaged_enemies.clear()
	if _player != null:
		_player.release_combat_facing()
