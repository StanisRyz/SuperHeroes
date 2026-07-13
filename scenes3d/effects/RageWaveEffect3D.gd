class_name RageWaveEffect3D
extends Node3D

const GroundMeshBuilder = preload("res://scenes3d/effects/GroundEffectMeshBuilder3D.gd")

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
var _material: StandardMaterial3D

func setup(world_position: Vector3, radius: float, duration: float) -> void:
	global_position = world_position + Vector3.UP * 0.03
	mesh_instance.mesh = GroundMeshBuilder.build_ring(0.76, 1.0)
	_material = _make_material(Color(0.95, 0.25, 0.08, 0.9))
	mesh_instance.material_override = _material
	scale = Vector3(0.08, 1.0, 0.08)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector3(radius, 1.0, radius), duration)
	tween.parallel().tween_method(_set_alpha, 0.9, 0.0, duration)
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
