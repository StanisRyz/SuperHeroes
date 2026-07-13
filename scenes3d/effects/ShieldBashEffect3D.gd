class_name ShieldBashEffect3D
extends Node3D

const GroundMeshBuilder = preload("res://scenes3d/effects/GroundEffectMeshBuilder3D.gd")

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
var _material: StandardMaterial3D

func setup(world_position: Vector3, direction: Vector3, attack_range: float, full_angle: float, duration: float) -> void:
	global_position = world_position + Vector3.UP * 0.035
	rotation.y = atan2(-direction.x, -direction.z)
	mesh_instance.mesh = GroundMeshBuilder.build_sector(attack_range, full_angle)
	_material = _make_material(Color(0.3, 0.78, 1.0, 0.75))
	mesh_instance.material_override = _material
	var tween := create_tween()
	tween.tween_property(mesh_instance, "scale", Vector3(1.08, 1.0, 1.08), duration)
	tween.parallel().tween_method(_set_alpha, 0.75, 0.0, duration)
	tween.tween_callback(queue_free)

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
