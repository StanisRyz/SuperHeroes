extends Node

@export var attack_damage: int = 5
@export var attack_interval: float = 0.6
@export var attack_range: float = 260.0
@export var projectile_speed: float = 520.0
@export var projectile_count: int = 1
@export var projectile_spread_degrees: float = 0.0
@export var projectile_pierce: int = 0
@export var projectile_size_multiplier: float = 1.0
@export var projectile_explosion_radius: float = 0.0
@export var projectile_explosion_damage_multiplier: float = 0.6
@export var projectile_scene: PackedScene

var projectile_container: Node
var audio_manager: Node
var _cooldown := 0.0
var _enemies_in_range: Array[Node2D] = []
var _missing_projectile_warning_shown := false

@onready var attack_range_area: Area2D = get_node_or_null("AttackRangeArea")
@onready var attack_shape: CollisionShape2D = get_node_or_null("AttackRangeArea/CollisionShape2D")
@onready var owner_body: Node2D = get_parent() as Node2D

func _ready() -> void:
	if attack_range_area == null:
		push_warning("PlayerAutoAttack could not find AttackRangeArea.")
		return

	attack_range_area.body_entered.connect(_on_attack_range_area_body_entered)
	attack_range_area.body_exited.connect(_on_attack_range_area_body_exited)
	_update_attack_range_shape()


func _physics_process(delta: float) -> void:
	_sync_attack_range_area()

	if _cooldown > 0.0:
		_cooldown -= delta

	if _cooldown > 0.0:
		return

	if owner_body == null:
		return
	if owner_body.has_method("is_dead") and owner_body.is_dead():
		return

	var enemy := _find_nearest_enemy()
	if enemy == null:
		return

	if _spawn_projectiles(enemy):
		_cooldown = attack_interval


func setup_projectile_container(container: Node) -> void:
	projectile_container = container


func setup_audio_manager(new_audio_manager: Node) -> void:
	audio_manager = new_audio_manager


func _on_attack_range_area_body_entered(body: Node2D) -> void:
	if _is_valid_enemy(body) and not _enemies_in_range.has(body):
		_enemies_in_range.append(body)


func _on_attack_range_area_body_exited(body: Node2D) -> void:
	_enemies_in_range.erase(body)


func _find_nearest_enemy() -> Node2D:
	var nearest_enemy: Node2D
	var nearest_distance := INF
	var origin: Vector2 = owner_body.global_position

	for enemy in _enemies_in_range:
		if not _is_valid_enemy(enemy):
			continue

		var distance: float = origin.distance_squared_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy

	_cleanup_invalid_enemies()
	return nearest_enemy


func _is_valid_enemy(body: Node) -> bool:
	return (
		body is Node2D
		and is_instance_valid(body)
		and not body.is_queued_for_deletion()
		and (body.is_in_group("enemies") or body.has_method("die"))
		and body.has_method("take_damage")
	)


func _cleanup_invalid_enemies() -> void:
	_enemies_in_range = _enemies_in_range.filter(_is_valid_enemy)


func _spawn_projectiles(enemy: Node2D) -> bool:
	if projectile_scene == null or projectile_container == null:
		if not _missing_projectile_warning_shown:
			push_warning("PlayerAutoAttack is missing projectile_scene or projectile_container.")
			_missing_projectile_warning_shown = true
		return false

	var base_direction := (enemy.global_position - owner_body.global_position).normalized()
	if base_direction.is_zero_approx():
		base_direction = Vector2.RIGHT

	var spawned_any := false
	var safe_count := clampi(projectile_count, 1, 7)
	for direction in _get_projectile_directions(base_direction, safe_count):
		if _spawn_projectile(enemy, direction):
			spawned_any = true

	return spawned_any


func _spawn_projectile(enemy: Node2D, direction: Vector2) -> bool:
	var projectile_node := projectile_scene.instantiate()
	if not projectile_node is Node2D:
		push_warning("PlayerAutoAttack projectile_scene root must be Node2D.")
		projectile_node.queue_free()
		return false

	var projectile := projectile_node as Node2D
	var spawn_position := owner_body.global_position + direction * 24.0

	projectile_container.add_child(projectile)
	if "speed" in projectile:
		projectile.speed = projectile_speed
	if projectile.has_method("setup_audio_manager"):
		projectile.setup_audio_manager(audio_manager)

	if projectile.has_method("setup"):
		projectile.setup(spawn_position, enemy, attack_damage, {
			"speed": projectile_speed,
			"direction": direction,
			"pierce": projectile_pierce,
			"size_multiplier": projectile_size_multiplier,
			"explosion_radius": projectile_explosion_radius,
			"explosion_damage_multiplier": projectile_explosion_damage_multiplier,
		})
	else:
		push_warning("Player projectile does not implement setup(origin, target, damage).")
		projectile.global_position = spawn_position

	return true


func _get_projectile_directions(base_direction: Vector2, count: int) -> Array[Vector2]:
	if count <= 1:
		return [base_direction]

	var directions: Array[Vector2] = []
	var spread_radians := deg_to_rad(projectile_spread_degrees)
	var start_angle := -spread_radians * 0.5
	var step := spread_radians / float(count - 1) if count > 1 else 0.0
	for index in range(count):
		directions.append(base_direction.rotated(start_angle + step * float(index)).normalized())

	return directions


func _update_attack_range_shape() -> void:
	if attack_shape == null:
		push_warning("PlayerAutoAttack could not find attack range CollisionShape2D.")
		return

	var circle := attack_shape.shape as CircleShape2D
	if circle == null:
		push_warning("PlayerAutoAttack attack range shape should be CircleShape2D.")
		return

	circle.radius = attack_range


func refresh_attack_range() -> void:
	_update_attack_range_shape()


func _sync_attack_range_area() -> void:
	if owner_body != null and attack_range_area != null:
		attack_range_area.global_position = owner_body.global_position
