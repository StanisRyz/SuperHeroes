extends Node

const NO_SPAWN_POSITION := Vector2(1.0e20, 1.0e20)

@export var enemy_scene: PackedScene
@export var experience_gem_scene: PackedScene
@export var spawn_interval: float = 1.5
@export var max_alive_enemies: int = 12
@export var min_spawn_distance_from_player: float = 500.0
@export var max_spawn_attempts: int = 12

var player: Node2D
var playable_rect: Rect2
var enemy_container: Node
var pickup_container: Node
var run_manager: Node
var spawn_director: Node

@onready var spawn_timer: Timer = $SpawnTimer

func _ready() -> void:
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false


func setup(new_player: Node2D, new_playable_rect: Rect2, new_enemy_container: Node, new_pickup_container: Node = null, new_run_manager: Node = null, new_spawn_director: Node = null) -> void:
	player = new_player
	playable_rect = new_playable_rect
	enemy_container = new_enemy_container
	pickup_container = new_pickup_container
	run_manager = new_run_manager
	spawn_director = new_spawn_director

	spawn_timer.wait_time = _get_current_spawn_interval()
	if _can_spawn():
		spawn_timer.start()


func _on_spawn_timer_timeout() -> void:
	if not _can_spawn():
		return

	spawn_timer.wait_time = _get_current_spawn_interval()
	if enemy_container.get_child_count() >= _get_current_max_alive_enemies():
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

	var variant := _get_enemy_variant()
	if not variant.is_empty() and enemy.has_method("apply_variant"):
		enemy.apply_variant(variant)

	if enemy.has_method("set_target"):
		enemy.set_target(player)
	else:
		push_warning("Spawned enemy does not implement set_target(new_target).")

	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)


func _on_enemy_died(enemy: Node) -> void:
	if run_manager != null and run_manager.has_method("register_enemy_kill"):
		run_manager.register_enemy_kill()

	var dropped_experience := 1
	if enemy != null and enemy.has_method("get_experience_value"):
		dropped_experience = int(enemy.get_experience_value())

	if experience_gem_scene == null or not is_instance_valid(pickup_container):
		return

	var enemy_node := enemy as Node2D
	if enemy_node == null:
		return

	var gem_node := experience_gem_scene.instantiate()
	if not gem_node is Node2D:
		push_warning("EnemySpawner experience_gem_scene root must be Node2D.")
		gem_node.queue_free()
		return

	var gem := gem_node as Node2D
	if "experience_value" in gem:
		gem.experience_value = dropped_experience

	pickup_container.add_child(gem)
	gem.global_position = enemy_node.global_position


func _can_spawn() -> bool:
	if run_manager != null and run_manager.get("is_run_active") == false:
		return false

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


func _get_current_spawn_interval() -> float:
	if spawn_director != null and spawn_director.has_method("get_spawn_interval"):
		return maxf(float(spawn_director.get_spawn_interval()), 0.05)

	return spawn_interval


func _get_current_max_alive_enemies() -> int:
	if spawn_director != null and spawn_director.has_method("get_max_alive_enemies"):
		return maxi(int(spawn_director.get_max_alive_enemies()), 0)

	return max_alive_enemies


func _get_enemy_variant() -> Dictionary:
	if spawn_director != null and spawn_director.has_method("get_enemy_variant"):
		var variant = spawn_director.get_enemy_variant()
		if variant is Dictionary:
			return variant

	return {}
