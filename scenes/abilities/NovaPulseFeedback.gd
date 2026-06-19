extends Node2D

@export var lifetime: float = 0.25
@export var start_scale: float = 0.25
@export var end_scale: float = 1.0

@onready var ring: Line2D = get_node_or_null("Ring")


func play(radius: float) -> void:
	if ring != null:
		_update_ring_points(radius)
		ring.modulate = Color(0.55, 0.9, 1.0, 0.85)

	scale = Vector2.ONE * start_scale
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE * end_scale, lifetime)
	if ring != null:
		tween.tween_property(ring, "modulate", Color(0.55, 0.9, 1.0, 0.0), lifetime)
	tween.chain().tween_callback(queue_free)


func _update_ring_points(radius: float) -> void:
	var points := PackedVector2Array()
	var segment_count := 48
	for index in range(segment_count + 1):
		var angle := TAU * float(index) / float(segment_count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)

	ring.points = points
