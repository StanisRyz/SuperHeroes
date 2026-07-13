class_name CrushingLeapImpactEffect3D
extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func setup(world_position: Vector3, radius: float, duration: float) -> void:
	global_position = world_position + Vector3.UP * 0.04
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(radius, 1.0, radius), duration)
	tween.tween_callback(queue_free)
