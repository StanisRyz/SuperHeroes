extends Node2D

@export var lifetime: float = 0.16

@onready var spark: Polygon2D = get_node_or_null("Spark")


func play(world_position: Vector2) -> void:
	global_position = world_position
	rotation = randf() * TAU
	scale = Vector2.ONE * 0.45

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE * 1.0, lifetime)
	if spark != null:
		spark.modulate = Color(1.0, 0.95, 0.3, 1.0)
		tween.tween_property(spark, "modulate", Color(1.0, 0.95, 0.3, 0.0), lifetime)
	tween.chain().tween_callback(queue_free)
