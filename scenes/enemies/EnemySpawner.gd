extends Node

const NO_SPAWN_POSITION := Vector2(1.0e20, 1.0e20)

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 1.5
@export var max_alive_enemies: int = 12
@export var min_spawn_distance_from_player: float = 500.0
@export var max_spawn_attempts: int = 12

var player: Node2D
var playable_rect: Rect2
var enemy_container: Node

@onready var spawn_timer: Timer = $SpawnTimer

func _ready() -> void:
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false


func setup(new_player: Node2D, new_playable_rect: Rect2, new_enemy_container: Node) -> void:
	player = new_player
	playable_rect = new_playable_rect
	enemy_container = new_enemy_container

	spawn_timer.wait_time = spawn_interval
	if _can_spawn():
		spawn_timer.start()


func _on_spawn_timer_timeout() -> void:
	if not _can_spawn():
		return

	if enemy_container.get_child_count() >= max_alive_enemies:
		return

	var spawn_position: Vector2 = _find_spawn_position()
	if spawn_position == NO_SPAWN_POSITION:
		return

	var enemy_node := enemy_scene.instantiate()
	if not enemy_node is Node2D:
		push_warning("EnemySpawner enemy_scene root must be Node2D.")
		enemy_node.queue_free()
		return

	var enemy := enemy_node as Node2D
	enemy_container.add_child(enemy)
	enemy.global_position = spawn_position
	enemy.add_to_group("enemies")

	if enemy.has_method("set_target"):
		enemy.set_target(player)
	else:
		push_warning("Spawned enemy does not implement set_target(new_target).")


func _can_spawn() -> bool:
	return enemy_scene != null and is_instance_valid(player) and is_instance_valid(enemy_container)


func _find_spawn_position() -> Vector2:
	for attempt in range(max_spawn_attempts):
		var point := Vector2(
			randf_range(playable_rect.position.x, playable_rect.end.x),
			randf_range(playable_rect.position.y, playable_rect.end.y)
		)

		if point.distance_to(player.global_position) >= min_spawn_distance_from_player:
			return point

	return NO_SPAWN_POSITION
