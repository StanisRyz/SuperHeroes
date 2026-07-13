class_name WorldbreakerPulseEffect3D
extends Node3D

const GroundMeshBuilder = preload("res://scenes3d/effects/GroundEffectMeshBuilder3D.gd")

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
var _material: StandardMaterial3D


func setup(world_position: Vector3, radius: float, duration: float, pulse_index: int) -> void:
	global_position = world_position + Vector3.UP * 0.045
	mesh_instance.mesh = GroundMeshBuilder.build_ring(_ring_inner_radius(pulse_index), 1.0)
	_material = _make_material(_pulse_color(pulse_index))
	mesh_instance.material_override = _material
	scale = Vector3(0.16, 1.0, 0.16)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector3(radius, 1.0, radius), duration)
	tween.parallel().tween_method(_set_alpha, _material.albedo_color.a, 0.0, duration)
	tween.tween_callback(queue_free)


func _pulse_color(pulse_index: int) -> Color:
	match pulse_index:
		1: return Color(0.78, 0.12, 0.03, 0.94)
		2: return Color(1.0, 0.36, 0.05, 0.88)
		_: return Color(1.0, 0.62, 0.12, 0.82)


func _ring_inner_radius(pulse_index: int) -> float:
	return 0.62 if pulse_index == 1 else (0.70 if pulse_index == 2 else 0.78)


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
