extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
var _material: StandardMaterial3D

func setup(world_position: Vector3, direction: Vector3, size: float, heavy: bool) -> void:
	global_position = world_position + Vector3.UP * 0.055
	rotation.y = atan2(-direction.x, -direction.z)
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(size * (1.45 if heavy else 1.0), size * 0.24)
	mesh_instance.mesh = mesh
	mesh_instance.position = Vector3(0.0, 0.0, -size * 0.65)
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.albedo_color = Color(1.0, 0.72, 0.22, 0.92 if heavy else 0.70)
	mesh_instance.material_override = _material
	var tween := create_tween()
	tween.parallel().tween_property(mesh_instance, "scale", Vector3(1.2, 1.0, 1.2), 0.12)
	tween.tween_method(_set_alpha, _material.albedo_color.a, 0.0, 0.12)
	tween.tween_callback(queue_free)

func _set_alpha(alpha: float) -> void:
	var color := _material.albedo_color
	color.a = alpha
	_material.albedo_color = color
