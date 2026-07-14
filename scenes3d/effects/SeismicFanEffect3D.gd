extends Node3D

const GroundCrackMeshBuilder = preload("res://scenes3d/effects/GroundCrackMeshBuilder3D.gd")

const SIDE_ANGLE := 34.0
const SIDE_WIDTH := 0.697
const CENTER_WIDTH := 0.861

@onready var strips: Array[MeshInstance3D] = [$Left, $Center, $Right]
var _materials: Array[StandardMaterial3D] = []
var _base_alphas: Array[float] = []


func setup(world_position: Vector3, direction: Vector3, maximum_range: float, duration: float) -> void:
	global_position = world_position + Vector3.UP * 0.045
	rotation.y = atan2(-direction.x, -direction.z)
	_configure_strip(strips[0], -SIDE_ANGLE, SIDE_WIDTH, maximum_range, Color(1.0, 0.62, 0.16, 0.68))
	_configure_strip(strips[1], 0.0, CENTER_WIDTH, maximum_range, Color(1.0, 0.72, 0.24, 0.74))
	_configure_strip(strips[2], SIDE_ANGLE, SIDE_WIDTH, maximum_range, Color(1.0, 0.62, 0.16, 0.68))
	var tween := create_tween()
	tween.tween_method(_set_alpha, 1.0, 0.0, duration)
	tween.tween_callback(queue_free)


func _configure_strip(strip: MeshInstance3D, angle_degrees: float, width: float, maximum_range: float, color: Color) -> void:
	strip.mesh = GroundCrackMeshBuilder.build_crack(maximum_range, width, 6, width * 0.10, 0.38, hash(world_position) + roundi(angle_degrees * 10.0))
	strip.rotation.y = deg_to_rad(angle_degrees)
	# Crack geometry begins at the Knight and already spans its full local -Z range.
	strip.position = Vector3.ZERO
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = color
	strip.material_override = material
	_materials.append(material)
	_base_alphas.append(color.a)


func _set_alpha(alpha_multiplier: float) -> void:
	for index in _materials.size():
		var material := _materials[index]
		var color := material.albedo_color
		color.a = _base_alphas[index] * alpha_multiplier
		material.albedo_color = color
