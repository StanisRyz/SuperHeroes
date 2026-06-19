extends Node2D

@export var lifetime: float = 0.28

@onready var ring: Line2D = get_node_or_null("Ring")


func play(world_position: Vector2, color: Color = Color.WHITE) -> void:
	global_position = world_position
	scale = Vector2.ONE * 0.25

	if ring != null:
		ring.default_color = color
		ring.modulate = Color(color.r, color.g, color.b, 0.9)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE * 1.25, lifetime)
	if ring != null:
		tween.tween_property(ring, "modulate", Color(color.r, color.g, color.b, 0.0), lifetime)
	tween.chain().tween_callback(queue_free)
