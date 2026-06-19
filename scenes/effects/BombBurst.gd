extends Node2D

@export var lifetime: float = 0.30


func play(world_position: Vector2, radius: float) -> void:
	global_position = world_position
	scale = Vector2.ONE * 0.15

	var ring := get_node_or_null("Ring") as Line2D
	if ring != null:
		_update_ring_points(ring, radius)
		ring.modulate = Color(1.0, 0.38, 0.12, 0.9)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, lifetime)
	if ring != null:
		tween.tween_property(ring, "modulate", Color(1.0, 0.38, 0.12, 0.0), lifetime)
	tween.chain().tween_callback(queue_free)


func _update_ring_points(ring: Line2D, radius: float) -> void:
	var points := PackedVector2Array()
	var segment_count := 36
	for index in range(segment_count + 1):
		var angle := TAU * float(index) / float(segment_count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	ring.points = points
