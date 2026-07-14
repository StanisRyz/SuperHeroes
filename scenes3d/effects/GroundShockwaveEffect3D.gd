extends Node3D

const GroundMeshBuilder = preload("res://scenes3d/effects/GroundEffectMeshBuilder3D.gd")

@onready var ring: MeshInstance3D = $Ring
@onready var disc: MeshInstance3D = $Disc
var _materials: Array[StandardMaterial3D] = []

func setup(world_position: Vector3, radius: float, duration: float) -> void:
	global_position = world_position + Vector3.UP * 0.035
	ring.mesh = GroundMeshBuilder.build_ring(maxf(radius - maxf(radius * 0.055, 0.035), 0.01), radius, 32)
	disc.mesh = CylinderMesh.new()
	(disc.mesh as CylinderMesh).top_radius = radius * 0.22
	(disc.mesh as CylinderMesh).bottom_radius = radius * 0.22
	(disc.mesh as CylinderMesh).height = 0.01
	for mesh: MeshInstance3D in [ring, disc]:
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = Color(1.0, 0.68, 0.20, 0.78 if mesh == ring else 0.36)
		mesh.material_override = material
		_materials.append(material)
	var tween := create_tween()
	tween.parallel().tween_property(ring, "scale", Vector3(1.08, 1.0, 1.08), duration)
	tween.tween_method(_set_alpha, 1.0, 0.0, duration)
	tween.tween_callback(queue_free)

func _set_alpha(multiplier: float) -> void:
	for material: StandardMaterial3D in _materials:
		var color := material.albedo_color
		color.a = multiplier * (0.78 if material == _materials[0] else 0.36)
		material.albedo_color = color
