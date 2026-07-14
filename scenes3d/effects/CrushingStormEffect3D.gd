extends Node3D

const GroundMeshBuilder = preload("res://scenes3d/effects/GroundEffectMeshBuilder3D.gd")

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
var _material: StandardMaterial3D


func setup(world_position: Vector3, radius: float, duration: float, rage_ratio: float = 0.0) -> void:
	global_position = world_position + Vector3.UP * 0.045
	mesh_instance.mesh = GroundMeshBuilder.build_ring(0.58, 1.0)
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.albedo_color = Color(0.62 + rage_ratio * 0.25, 0.06, 0.08, 0.70 + rage_ratio * 0.20)
	mesh_instance.material_override = _material
	scale = Vector3(0.12, 1.0, 0.12)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(radius, 1.0, radius), duration)
	tween.parallel().tween_method(_set_alpha, 0.78, 0.0, duration)
	tween.tween_callback(queue_free)


func _set_alpha(alpha: float) -> void:
	var color := _material.albedo_color
	color.a = alpha
	_material.albedo_color = color
