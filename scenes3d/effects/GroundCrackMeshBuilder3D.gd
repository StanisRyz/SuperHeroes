class_name GroundCrackMeshBuilder3D
extends RefCounted

static func build_crack(length: float, base_width: float, segments: int, lateral_variation: float, taper: float, visual_seed: int) -> ArrayMesh:
	var count := clampi(segments, 4, 8)
	var rng := RandomNumberGenerator.new()
	rng.seed = visual_seed
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var lateral := 0.0
	for index in range(count + 1):
		var progress := float(index) / float(count)
		lateral += rng.randf_range(-lateral_variation, lateral_variation)
		var width := base_width * lerpf(1.0, taper, progress)
		var center := Vector3(lateral, 0.0, -length * progress)
		vertices.append(center + Vector3(-width * 0.5, 0.0, 0.0))
		vertices.append(center + Vector3(width * 0.5, 0.0, 0.0))
	for index in range(count):
		var base := index * 2
		indices.append_array(PackedInt32Array([base, base + 1, base + 3, base, base + 3, base + 2]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
