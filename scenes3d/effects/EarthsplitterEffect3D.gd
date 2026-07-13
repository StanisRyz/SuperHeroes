extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
var _material: StandardMaterial3D


func setup(world_position: Vector3, direction: Vector3, maximum_range: float, width: float, duration: float) -> void:
	global_position = world_position + Vector3.UP * 0.04
	rotation.y = atan2(-direction.x, -direction.z)
	var crack_mesh := PlaneMesh.new()
	crack_mesh.size = Vector2(width, maximum_range)
	mesh_instance.mesh = crack_mesh
	mesh_instance.position = Vector3(0.0, 0.0, -maximum_range * 0.5)
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.albedo_color = Color(1.0, 0.38, 0.08, 0.84)
	mesh_instance.material_override = _material
	var tween := create_tween()
	tween.tween_method(_set_alpha, 0.84, 0.0, duration)
	tween.tween_callback(queue_free)


func _set_alpha(alpha: float) -> void:
	var color := _material.albedo_color
	color.a = alpha
	_material.albedo_color = color
