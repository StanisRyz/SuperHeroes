extends Node

@export var heal_amount: int = 25
@export var shield_charges: int = 1
@export var bomb_damage: int = 50
@export var bomb_radius: float = 320.0
@export var magnet_burst_radius: float = 900.0
@export var move_speed_multiplier: float = 1.35
@export var move_speed_duration: float = 6.0
@export var attack_speed_multiplier: float = 1.35
@export var attack_speed_duration: float = 6.0
@export var bomb_burst_scene: PackedScene

var player: Node
var player_buff_manager: Node
var auto_attack: Node
var enemy_container: Node
var pickup_container: Node
var floating_text_spawner: Node
var audio_manager: Node
var feedback_manager: Node


func setup(new_player: Node, new_auto_attack: Node, new_enemy_container: Node, new_pickup_container: Node, new_floating_text_spawner: Node = null, new_audio_manager: Node = null, new_feedback_manager: Node = null) -> void:
	player = new_player
	auto_attack = new_auto_attack
	enemy_container = new_enemy_container
	pickup_container = new_pickup_container
	floating_text_spawner = new_floating_text_spawner
	audio_manager = new_audio_manager
	feedback_manager = new_feedback_manager

	if player != null:
		player_buff_manager = player.get_node_or_null("PlayerBuffManager")
		if player_buff_manager == null:
			push_warning("PowerupManager could not find Player/PlayerBuffManager.")


func apply_powerup(powerup_id: String, world_position: Vector2) -> void:
	match powerup_id:
		"heal":
			_apply_heal(world_position)
		"shield":
			_apply_shield(world_position)
		"bomb":
			_apply_bomb(world_position)
		"magnet_burst":
			_apply_magnet_burst(world_position)
		"move_speed_boost":
			_apply_move_speed_boost(world_position)
		"attack_speed_boost":
			_apply_attack_speed_boost(world_position)
		_:
			push_warning("PowerupManager: unknown powerup_id=%s" % powerup_id)

	if audio_manager != null and audio_manager.has_method("play_pickup"):
		audio_manager.play_pickup()


func _apply_heal(world_position: Vector2) -> void:
	if player != null and player.has_method("heal"):
		player.heal(heal_amount)
	_show_powerup("heal", world_position)


func _apply_shield(world_position: Vector2) -> void:
	if player_buff_manager != null and player_buff_manager.has_method("add_shield_charges"):
		player_buff_manager.add_shield_charges(shield_charges)
	_show_powerup("shield", world_position)


func _apply_bomb(world_position: Vector2) -> void:
	if enemy_container != null and player != null:
		var player_node := player as Node2D
		for enemy in enemy_container.get_children():
			if not is_instance_valid(enemy):
				continue
			if not enemy.has_method("take_damage"):
				continue
			if not enemy is Node2D:
				continue
			var enemy_node := enemy as Node2D
			if enemy_node.global_position.distance_to(player_node.global_position) <= bomb_radius:
				enemy.take_damage(bomb_damage)

	_spawn_bomb_burst(world_position)
	_show_powerup("bomb", world_position)
	if feedback_manager != null and feedback_manager.has_method("shake"):
		feedback_manager.shake(5.0, 0.18)


func _apply_magnet_burst(world_position: Vector2) -> void:
	if pickup_container != null and player != null:
		var player_node := player as Node2D
		for pickup in pickup_container.get_children():
			if not is_instance_valid(pickup):
				continue
			if not pickup is Node2D:
				continue
			if not pickup.has_method("force_magnet_to_player"):
				continue
			var pickup_node := pickup as Node2D
			if pickup_node.global_position.distance_to(player_node.global_position) <= magnet_burst_radius:
				pickup.force_magnet_to_player(player_node)

	_show_powerup("magnet_burst", world_position)


func _apply_move_speed_boost(world_position: Vector2) -> void:
	if player_buff_manager != null and player_buff_manager.has_method("apply_move_speed_boost"):
		player_buff_manager.apply_move_speed_boost(move_speed_multiplier, move_speed_duration)
	_show_powerup("move_speed_boost", world_position)


func _apply_attack_speed_boost(world_position: Vector2) -> void:
	if player_buff_manager != null and player_buff_manager.has_method("apply_attack_speed_boost"):
		player_buff_manager.apply_attack_speed_boost(attack_speed_multiplier, attack_speed_duration)
	_show_powerup("attack_speed_boost", world_position)


func _show_powerup(powerup_id: String, world_position: Vector2) -> void:
	if feedback_manager != null and feedback_manager.has_method("show_powerup"):
		feedback_manager.show_powerup(powerup_id, world_position)
	elif floating_text_spawner != null and floating_text_spawner.has_method("spawn_powerup_text"):
		floating_text_spawner.spawn_powerup_text(powerup_id, world_position)
	elif floating_text_spawner != null and floating_text_spawner.has_method("show_pickup"):
		floating_text_spawner.show_pickup(powerup_id.to_upper(), world_position)


func _spawn_bomb_burst(world_position: Vector2) -> void:
	if bomb_burst_scene == null:
		return

	var burst_node := bomb_burst_scene.instantiate()
	if not burst_node is Node2D:
		push_warning("BombBurst scene root must be Node2D.")
		burst_node.queue_free()
		return

	var burst := burst_node as Node2D
	var burst_parent := get_parent() if get_parent() != null else get_tree().current_scene
	if burst_parent == null:
		burst.queue_free()
		return

	burst_parent.add_child(burst)
	if burst.has_method("play"):
		burst.play(world_position, bomb_radius)
	else:
		burst.global_position = world_position
