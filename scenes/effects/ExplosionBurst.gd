extends Node2D

@export var lifetime: float = 0.22

@onready var ring: Line2D = get_node_or_null("Ring")


func play(world_position: Vector2, radius: float) -> void:
	global_position = world_position
	scale = Vector2.ONE * 0.2
	if ring != null:
		_update_ring_points(radius)
		ring.modulate = Color(1.0, 0.72, 0.25, 0.82)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, lifetime)
	if ring != null:
		tween.tween_property(ring, "modulate", Color(1.0, 0.72, 0.25, 0.0), lifetime)
	tween.chain().tween_callback(queue_free)


func _update_ring_points(radius: float) -> void:
	var points := PackedVector2Array()
	var segment_count := 36
	for index in range(segment_count + 1):
		var angle := TAU * float(index) / float(segment_count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)

	ring.points = points
