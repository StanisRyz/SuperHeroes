extends Node2D

@export var lifetime: float = 0.18

@onready var burst: Polygon2D = get_node_or_null("Burst")


func play(world_position: Vector2, direction: Vector2) -> void:
	global_position = world_position
	if not direction.is_zero_approx():
		rotation = direction.angle() + PI

	scale = Vector2.ONE * 0.45
	if burst != null:
		burst.modulate = Color(0.55, 0.9, 1.0, 0.8)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE * 1.15, lifetime)
	if burst != null:
		tween.tween_property(burst, "modulate", Color(0.55, 0.9, 1.0, 0.0), lifetime)
	tween.chain().tween_callback(queue_free)
