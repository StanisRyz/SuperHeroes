class_name EnemySpawner3D
extends Node

const EnemyVariantAdapter = preload("res://scenes3d/enemies/EnemyVariant3DAdapter.gd")

@export var enemy_scene: PackedScene
@export var experience_pickup_scene: PackedScene
@export var min_spawn_distance: float = 8.0
@export var max_spawn_distance: float = 12.0
@export var max_spawn_attempts: int = 12

var _player: Player3D = null
var _arena: Node3D = null
var _enemy_container: Node3D = null
var _pickup_container: Node3D = null
var _spawn_director: Node = null

@onready var spawn_timer: Timer = $SpawnTimer
@onready var wave_timer: Timer = $WaveTimer


func setup(player: Player3D, arena: Node3D, enemy_container: Node3D, pickup_container: Node3D, spawn_director: Node) -> void:
	_player = player
	_arena = arena
	_enemy_container = enemy_container
	_pickup_container = pickup_container
	_spawn_director = spawn_director
	_refresh_timers()
	spawn_timer.start()
	wave_timer.start()


func debug_kill_nearest_enemy() -> void:
	if _player == null or not is_instance_valid(_player) or _enemy_container == null:
		return
	var nearest_enemy: Enemy3D = null
	var nearest_distance: float = INF
	for child: Node in _enemy_container.get_children():
		if not child is Enemy3D:
			continue
		var enemy := child as Enemy3D
		if enemy.is_dead():
			continue
		var distance: float = enemy.global_position.distance_to(_player.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy
	if nearest_enemy != null:
		nearest_enemy.take_damage(nearest_enemy.current_health)


func _on_spawn_timer_timeout() -> void:
	_refresh_timers()
	if _alive_enemy_count() >= _get_max_alive_count():
		return
	_spawn_variant(_get_director_variant())


func _on_wave_timer_timeout() -> void:
	_refresh_timers()
	if _spawn_director == null or not _spawn_director.has_method("get_wave_package"):
		return
	var wave: Dictionary = _spawn_director.get_wave_package()
	for variant_id: Variant in wave.get("variant_ids", []):
		if _alive_enemy_count() >= _get_max_alive_count():
			break
		var variant: Dictionary = {}
		if _spawn_director.has_method("get_enemy_variant_by_id"):
			variant = _spawn_director.get_enemy_variant_by_id(str(variant_id))
		_spawn_variant(variant)


func _spawn_variant(variant: Dictionary) -> void:
	if enemy_scene == null or _player == null or not is_instance_valid(_player) or _enemy_container == null:
		return
	var spawn_position: Vector3 = _find_spawn_position()
	if is_inf(spawn_position.x):
		return
	var enemy_node := enemy_scene.instantiate()
	if not enemy_node is Enemy3D:
		enemy_node.queue_free()
		push_warning("EnemySpawner3D: enemy scene root must be Enemy3D.")
		return
	var enemy := enemy_node as Enemy3D
	_enemy_container.add_child(enemy)
	enemy.global_position = spawn_position
	enemy.apply_variant(EnemyVariantAdapter.adapt_variant(variant))
	enemy.set_target(_player)
	enemy.died.connect(_on_enemy_died)


func _on_enemy_died(enemy: Enemy3D) -> void:
	if experience_pickup_scene == null or _pickup_container == null:
		return
	var pickup_node := experience_pickup_scene.instantiate()
	if not pickup_node is ExperiencePickup3D:
		pickup_node.queue_free()
		push_warning("EnemySpawner3D: experience pickup scene root must be ExperiencePickup3D.")
		return
	var pickup := pickup_node as ExperiencePickup3D
	_pickup_container.add_child(pickup)
	pickup.global_position = enemy.global_position + Vector3.UP * 0.4
	pickup.experience_value = enemy.get_experience_value()


func _find_spawn_position() -> Vector3:
	if _arena == null or not _arena.has_method("is_world_position_inside_playable_bounds"):
		return Vector3(INF, 0.0, 0.0)
	for attempt: int in range(max_spawn_attempts):
		var angle: float = randf() * TAU
		var distance: float = randf_range(min_spawn_distance, max_spawn_distance)
		var candidate: Vector3 = _player.global_position + Vector3(cos(angle) * distance, 1.0, sin(angle) * distance)
		if not _arena.is_world_position_inside_playable_bounds(candidate):
			continue
		if candidate.distance_to(_player.global_position) < min_spawn_distance:
			continue
		return candidate
	return Vector3(INF, 0.0, 0.0)


func _alive_enemy_count() -> int:
	if _enemy_container == null:
		return 0
	var alive_count: int = 0
	for child: Node in _enemy_container.get_children():
		if child is Enemy3D and not (child as Enemy3D).is_dead():
			alive_count += 1
	return alive_count


func _get_director_variant() -> Dictionary:
	if _spawn_director != null and _spawn_director.has_method("get_enemy_variant"):
		return _spawn_director.get_enemy_variant()
	return {}


func _get_max_alive_count() -> int:
	if _spawn_director != null and _spawn_director.has_method("get_max_alive_enemies"):
		return int(_spawn_director.get_max_alive_enemies())
	return 12


func _refresh_timers() -> void:
	if _spawn_director != null and _spawn_director.has_method("get_spawn_interval"):
		spawn_timer.wait_time = float(_spawn_director.get_spawn_interval())
	if _spawn_director != null and _spawn_director.has_method("get_wave_interval"):
		wave_timer.wait_time = float(_spawn_director.get_wave_interval())
