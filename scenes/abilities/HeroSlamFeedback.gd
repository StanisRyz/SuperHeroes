extends Node2D

@export var lifetime: float = 0.22
@export var start_scale: float = 0.2
@export var end_scale: float = 1.0

@onready var ring: Line2D = get_node_or_null("Ring")


func play(world_position: Vector2, radius: float) -> void:
	global_position = world_position

	if ring != null:
		_update_ring_points(radius)
		ring.default_color = Color(1.0, 0.5, 0.1, 0.9)

	scale = Vector2.ONE * start_scale
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE * end_scale, lifetime)
	if ring != null:
		tween.tween_property(ring, "default_color", Color(1.0, 0.5, 0.1, 0.0), lifetime)
	tween.chain().tween_callback(queue_free)


func _update_ring_points(radius: float) -> void:
	if ring == null:
		return
	var points := PackedVector2Array()
	var segment_count := 36
	for index in range(segment_count + 1):
		var angle := TAU * float(index) / float(segment_count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	ring.points = points
