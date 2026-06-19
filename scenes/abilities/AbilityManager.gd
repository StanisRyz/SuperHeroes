extends Node

signal ability_cooldown_changed(slot: int, cooldown_remaining: float, cooldown_total: float)
signal ability_cast(slot: int)

@export var nova_damage: int = 18
@export var nova_radius: float = 220.0
@export var nova_cooldown: float = 6.0
@export var pulse_feedback_scene: PackedScene

var player: Node2D
var enemy_container: Node
var _ability_1_cooldown_remaining := 0.0
var _last_emitted_cooldown := -1.0


func setup(new_player: Node2D, new_enemy_container: Node) -> void:
	player = new_player
	enemy_container = new_enemy_container
	_emit_cooldown_changed(true)


func _process(delta: float) -> void:
	if _ability_1_cooldown_remaining <= 0.0:
		return

	_ability_1_cooldown_remaining = maxf(_ability_1_cooldown_remaining - delta, 0.0)
	_emit_cooldown_changed(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ability_1"):
		cast_ability_1()


func cast_ability_1() -> void:
	_try_cast_nova_pulse()


func _try_cast_nova_pulse() -> void:
	if get_tree().paused:
		return
	if player == null or not is_instance_valid(player):
		return
	if player.has_method("is_dead") and player.is_dead():
		return
	if _ability_1_cooldown_remaining > 0.0:
		return

	if not _damage_enemies_in_radius():
		return

	_spawn_pulse_feedback()
	if player.has_method("shake_camera"):
		player.shake_camera(5.0, 0.14)
	_ability_1_cooldown_remaining = maxf(nova_cooldown, 0.0)
	ability_cast.emit(1)
	_emit_cooldown_changed(true)


func _damage_enemies_in_radius() -> bool:
	if enemy_container == null or not is_instance_valid(enemy_container):
		push_warning("AbilityManager is missing EnemyContainer reference.")
		return false

	for enemy in enemy_container.get_children():
		if _is_valid_enemy(enemy) and player.global_position.distance_to(enemy.global_position) <= nova_radius:
			enemy.take_damage(nova_damage)

	return true


func _spawn_pulse_feedback() -> void:
	if pulse_feedback_scene == null:
		return

	var feedback_node := pulse_feedback_scene.instantiate()
	if not feedback_node is Node2D:
		push_warning("Nova Pulse feedback scene root must be Node2D.")
		feedback_node.queue_free()
		return

	var feedback := feedback_node as Node2D
	player.get_parent().add_child(feedback)
	feedback.global_position = player.global_position

	if feedback.has_method("play"):
		feedback.play(nova_radius)


func _is_valid_enemy(node: Node) -> bool:
	return (
		node is Node2D
		and is_instance_valid(node)
		and not node.is_queued_for_deletion()
		and node.has_method("take_damage")
		and (node.is_in_group("enemies") or node.has_method("take_damage"))
	)


func _emit_cooldown_changed(force: bool) -> void:
	var should_emit := force
	if not should_emit:
		should_emit = absf(_ability_1_cooldown_remaining - _last_emitted_cooldown) >= 0.05
	should_emit = should_emit or (_ability_1_cooldown_remaining == 0.0 and _last_emitted_cooldown != 0.0)

	if not should_emit:
		return

	_last_emitted_cooldown = _ability_1_cooldown_remaining
	ability_cooldown_changed.emit(1, _ability_1_cooldown_remaining, nova_cooldown)
