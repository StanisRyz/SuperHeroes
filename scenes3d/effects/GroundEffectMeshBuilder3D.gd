class_name GroundEffectMeshBuilder3D
extends RefCounted

const DEFAULT_SEGMENTS := 32


static func build_ring(inner_radius: float, outer_radius: float, segments: int = DEFAULT_SEGMENTS) -> ArrayMesh:
	var safe_segments := maxi(segments, 3)
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	for index in range(safe_segments + 1):
		var angle := TAU * float(index) / float(safe_segments)
		var direction := Vector3(sin(angle), 0.0, -cos(angle))
		vertices.append(direction * inner_radius)
		vertices.append(direction * outer_radius)
	for index in range(safe_segments):
		var base := index * 2
		indices.append_array(PackedInt32Array([base, base + 1, base + 3, base, base + 3, base + 2]))
	return _build_mesh(vertices, indices)


static func build_sector(radius: float, full_angle_degrees: float, segments: int = DEFAULT_SEGMENTS) -> ArrayMesh:
	var safe_segments := maxi(segments, 3)
	var vertices := PackedVector3Array([Vector3.ZERO])
	var indices := PackedInt32Array()
	var half_angle := deg_to_rad(full_angle_degrees) * 0.5
	for index in range(safe_segments + 1):
		var angle := lerpf(-half_angle, half_angle, float(index) / float(safe_segments))
		vertices.append(Vector3(sin(angle) * radius, 0.0, -cos(angle) * radius))
	for index in range(safe_segments):
		indices.append_array(PackedInt32Array([0, index + 1, index + 2]))
	return _build_mesh(vertices, indices)


static func _build_mesh(vertices: PackedVector3Array, indices: PackedInt32Array) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
