extends Node

@export var floating_text_scene: PackedScene


func show_damage(amount: int, world_position: Vector2) -> void:
	_spawn_text(str(amount), world_position)


func show_pickup(text: String, world_position: Vector2) -> void:
	_spawn_text(text, world_position)


func _spawn_text(text: String, world_position: Vector2) -> void:
	if floating_text_scene == null:
		push_warning("FloatingTextSpawner is missing floating_text_scene.")
		return

	var text_node := floating_text_scene.instantiate()
	if not text_node is Node2D:
		push_warning("FloatingText scene root must be Node2D.")
		text_node.queue_free()
		return

	add_child(text_node)
	if text_node.has_method("play"):
		text_node.play(text, world_position)
	else:
		text_node.global_position = world_position
