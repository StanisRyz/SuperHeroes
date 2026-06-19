extends Node2D

func play(world_position: Vector2, radius: float) -> void:
	global_position = world_position
	var ring := Line2D.new()
	ring.closed = true
	ring.width = 5.0
	ring.default_color = Color(0.45, 0.95, 1.0, 0.85)
	for index in range(48):
		var angle := TAU * float(index) / 48.0
		ring.add_point(Vector2.RIGHT.rotated(angle) * radius)
	add_child(ring)

	var tween := create_tween()
	scale = Vector2.ONE * 0.45
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.18)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.28)
	tween.tween_callback(queue_free)
