class_name RampageImpactEffect3D
extends Node3D

const GroundMeshBuilder = preload("res://scenes3d/effects/GroundEffectMeshBuilder3D.gd")

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
var _material: StandardMaterial3D


func setup(world_position: Vector3, direction: Vector3, impact_range: float, full_angle: float, duration: float, impact_index: int) -> void:
	global_position = world_position + Vector3.UP * 0.05
	rotation.y = atan2(-direction.x, -direction.z)
	mesh_instance.mesh = GroundMeshBuilder.build_sector(impact_range, full_angle)
	_material = _make_material(_impact_color(impact_index))
	mesh_instance.material_override = _material
	var tween := create_tween()
	tween.tween_method(_set_alpha, _material.albedo_color.a, 0.0, duration if impact_index == 1 else duration * 0.75)
	tween.tween_callback(queue_free)


func _impact_color(impact_index: int) -> Color:
	return Color(1.0, 0.24, 0.05, 0.94) if impact_index == 1 else Color(1.0, 0.72, 0.18, 0.78)


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = color
	return material


func _set_alpha(alpha: float) -> void:
	var color := _material.albedo_color
	color.a = alpha
	_material.albedo_color = color
