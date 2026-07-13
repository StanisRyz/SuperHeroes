class_name PassiveArcEffect3D
extends MeshInstance3D

var _material: StandardMaterial3D


func setup(start_world_position: Vector3, end_world_position: Vector3, duration: float, color: Color, thickness: float) -> void:
	var offset := end_world_position - start_world_position
	var length := offset.length()
	if length <= 0.001:
		queue_free()
		return
	global_position = start_world_position.lerp(end_world_position, 0.5)
	look_at(end_world_position, Vector3.UP)
	var arc_mesh := BoxMesh.new()
	arc_mesh.size = Vector3(thickness, thickness, length)
	mesh = arc_mesh
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.albedo_color = color
	material_override = _material
	var tween := create_tween()
	tween.tween_method(_set_alpha, color.a, 0.0, duration)
	tween.tween_callback(queue_free)


func _set_alpha(alpha: float) -> void:
	var current_color := _material.albedo_color
	current_color.a = alpha
	_material.albedo_color = current_color
