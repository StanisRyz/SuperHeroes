extends Node

const NO_SPAWN_POSITION := Vector2(1.0e20, 1.0e20)

@export var enemy_scene: PackedScene
@export var experience_gem_scene: PackedScene
@export var death_burst_scene: PackedScene
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
var floating_text_spawner: Node
var audio_manager: Node

@onready var spawn_timer: Timer = $SpawnTimer

func _ready() -> void:
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false


func setup(new_player: Node2D, new_playable_rect: Rect2, new_enemy_container: Node, new_pickup_container: Node = null, new_run_manager: Node = null, new_spawn_director: Node = null, new_floating_text_spawner: Node = null, new_audio_manager: Node = null) -> void:
	player = new_player
	playable_rect = new_playable_rect
	enemy_container = new_enemy_container
	pickup_container = new_pickup_container
	run_manager = new_run_manager
	spawn_director = new_spawn_director
	floating_text_spawner = new_floating_text_spawner
	audio_manager = new_audio_manager

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
		if not enemy.died.is_connected(_on_enemy_died):
			enemy.died.connect(_on_enemy_died)

	if enemy.has_signal("damage_taken") and floating_text_spawner != null and floating_text_spawner.has_method("show_damage"):
		if not enemy.damage_taken.is_connected(floating_text_spawner.show_damage):
			enemy.damage_taken.connect(floating_text_spawner.show_damage)


func _on_enemy_died(enemy: Node) -> void:
	if audio_manager != null and audio_manager.has_method("play_enemy_death"):
		audio_manager.play_enemy_death()

	if run_manager != null and run_manager.has_method("register_enemy_kill"):
		run_manager.register_enemy_kill()

	var dropped_experience := 1
	if enemy != null and enemy.has_method("get_experience_value"):
		dropped_experience = int(enemy.get_experience_value())

	var enemy_node := enemy as Node2D
	if enemy_node == null:
		return

	_spawn_death_burst(enemy_node.global_position)

	if experience_gem_scene == null or not is_instance_valid(pickup_container):
		return

	var gem_node := experience_gem_scene.instantiate()
	if not gem_node is Node2D:
		push_warning("EnemySpawner experience_gem_scene root must be Node2D.")
		gem_node.queue_free()
		return

	var gem := gem_node as Node2D
	if "experience_value" in gem:
		gem.experience_value = dropped_experience
	if gem.has_method("setup_audio_manager"):
		gem.setup_audio_manager(audio_manager)

	pickup_container.add_child(gem)
	gem.global_position = enemy_node.global_position


func _spawn_death_burst(world_position: Vector2) -> void:
	if death_burst_scene == null:
		return

	var burst_node := death_burst_scene.instantiate()
	if not burst_node is Node2D:
		push_warning("DeathBurst scene root must be Node2D.")
		burst_node.queue_free()
		return

	var burst := burst_node as Node2D
	var effect_parent := enemy_container.get_parent() if enemy_container != null else null
	if effect_parent == null:
		burst.queue_free()
		return

	effect_parent.add_child(burst)
	if burst.has_method("play"):
		burst.play(world_position, Color(1.0, 0.35, 0.28, 1.0))
	else:
		burst.global_position = world_position


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
