extends Node2D

@export var arena_size: Vector2 = Vector2(4000.0, 4000.0)

@onready var player: Node = get_node_or_null("Player")
@onready var enemy_container: Node = get_node_or_null("EnemyContainer")
@onready var enemy_spawner: Node = get_node_or_null("EnemySpawner")

func _ready() -> void:
	var playable_rect := get_playable_rect()

	if player == null:
		push_warning("Arena could not find Player node to apply playable bounds.")
		return

	if player.has_method("set_playable_rect"):
		player.set_playable_rect(playable_rect)
	else:
		push_warning("Player does not implement set_playable_rect(rect).")

	if player.has_method("set_camera_limits"):
		player.set_camera_limits(playable_rect)
	else:
		push_warning("Player does not implement set_camera_limits(rect).")

	if enemy_container == null:
		push_warning("Arena could not find EnemyContainer node for spawned enemies.")
	elif enemy_spawner == null:
		push_warning("Arena could not find EnemySpawner node.")
	elif enemy_spawner.has_method("setup"):
		enemy_spawner.setup(player, playable_rect, enemy_container)
	else:
		push_warning("EnemySpawner does not implement setup(player, playable_rect, enemy_container).")


func get_playable_rect() -> Rect2:
	return Rect2(-arena_size * 0.5, arena_size)
