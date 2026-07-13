class_name ShieldBashEffect3D
extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func setup(world_position: Vector3, direction: Vector3, attack_range: float, _angle: float, duration: float) -> void:
	global_position = world_position + Vector3.UP * 0.5
	rotation.y = atan2(-direction.x, -direction.z)
	scale = Vector3(attack_range, 1.0, attack_range)
	var tween := create_tween()
	tween.tween_property(mesh_instance, "scale", Vector3(1.25, 1.0, 1.25), duration)
	tween.tween_callback(queue_free)
