class_name PassivePulseEffect3D
extends Node3D

const GroundMeshBuilder = preload("res://scenes3d/effects/GroundEffectMeshBuilder3D.gd")

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
var _material: StandardMaterial3D


func setup(world_position: Vector3, radius: float, duration: float, color: Color, inner_radius_ratio: float = 0.68) -> void:
	global_position = world_position + Vector3.UP * 0.05
	mesh_instance.mesh = GroundMeshBuilder.build_ring(clampf(inner_radius_ratio, 0.05, 0.95), 1.0)
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.albedo_color = color
	mesh_instance.material_override = _material
	scale = Vector3(0.14, 1.0, 0.14)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector3(radius, 1.0, radius), duration)
	tween.parallel().tween_method(_set_alpha, color.a, 0.0, duration)
	tween.tween_callback(queue_free)


func _set_alpha(alpha: float) -> void:
	var current_color := _material.albedo_color
	current_color.a = alpha
	_material.albedo_color = current_color
