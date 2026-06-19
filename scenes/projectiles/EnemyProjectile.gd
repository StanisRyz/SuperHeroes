extends Area2D

@export var speed: float = 360.0
@export var damage: int = 8
@export var max_lifetime: float = 3.0

var direction := Vector2.RIGHT
var _lifetime := 0.0
var _has_hit := false


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func setup(origin: Vector2, target_position: Vector2, new_damage: int, new_speed: float) -> void:
	global_position = origin
	damage = new_damage
	speed = new_speed

	var offset := target_position - origin
	if not offset.is_zero_approx():
		direction = offset.normalized()

	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	_lifetime += delta
	if _lifetime >= max_lifetime:
		queue_free()
		return

	global_position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if _has_hit or not _is_valid_target(body):
		return

	_has_hit = true
	body.take_damage(damage)
	queue_free()


func _is_valid_target(body: Node) -> bool:
	return (
		body is Node2D
		and is_instance_valid(body)
		and not body.is_queued_for_deletion()
		and body.has_method("take_damage")
		and (body.is_in_group("player") or body.has_method("is_dead"))
	)
