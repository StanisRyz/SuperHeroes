extends Node2D

@export var lifetime: float = 0.18

@onready var beam: Line2D = get_node_or_null("Beam")


func play(origin: Vector2, direction: Vector2, length: float, width: float) -> void:
	global_position = origin

	if beam != null:
		beam.width = width
		beam.points = PackedVector2Array([Vector2.ZERO, direction * length])
		beam.default_color = Color(0.15, 0.85, 1.0, 0.9)

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, lifetime)
	tween.tween_callback(queue_free)
