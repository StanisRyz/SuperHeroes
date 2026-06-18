extends Node

@export var attack_damage: int = 5
@export var attack_interval: float = 0.6
@export var attack_range: float = 260.0

var _cooldown := 0.0
var _enemies_in_range: Array[Node2D] = []

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

	var enemy := _find_nearest_enemy()
	if enemy == null:
		return

	enemy.take_damage(attack_damage)
	_cooldown = attack_interval


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
		and (body.is_in_group("enemies") or body.has_method("take_damage"))
		and body.has_method("take_damage")
	)


func _cleanup_invalid_enemies() -> void:
	_enemies_in_range = _enemies_in_range.filter(_is_valid_enemy)


func _update_attack_range_shape() -> void:
	if attack_shape == null:
		push_warning("PlayerAutoAttack could not find attack range CollisionShape2D.")
		return

	var circle := attack_shape.shape as CircleShape2D
	if circle == null:
		push_warning("PlayerAutoAttack attack range shape should be CircleShape2D.")
		return

	circle.radius = attack_range


func _sync_attack_range_area() -> void:
	if owner_body != null and attack_range_area != null:
		attack_range_area.global_position = owner_body.global_position
