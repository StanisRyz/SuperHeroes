extends Area2D

@export var experience_value: int = 1
@export var pickup_radius: float = 16.0

var _picked_up := false

@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	var circle := collision_shape.shape as CircleShape2D if collision_shape != null else null
	if circle != null:
		circle.radius = pickup_radius


func _on_body_entered(body: Node2D) -> void:
	if _picked_up or not body.has_method("add_experience"):
		return

	_picked_up = true
	body.add_experience(experience_value)
	queue_free()
