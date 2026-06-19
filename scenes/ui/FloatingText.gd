extends Node2D

@export var rise_distance: float = 42.0

@onready var label: Label = get_node_or_null("Label")


func play(text: String, world_position: Vector2, duration: float = 0.6) -> void:
	global_position = world_position

	if label != null:
		label.text = text
		label.modulate = Color(1.0, 1.0, 1.0, 1.0)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", world_position + Vector2.UP * rise_distance, duration)
	if label != null:
		tween.tween_property(label, "modulate", Color(1.0, 1.0, 1.0, 0.0), duration)
	tween.chain().tween_callback(queue_free)
