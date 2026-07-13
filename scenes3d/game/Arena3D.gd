extends Node3D

## Isolated visual prototype for the early 3D migration.
## This scene deliberately does not initialize any of the 2D runtime managers.

@export_range(8.0, 200.0, 1.0) var arena_width: float = 40.0
@export_range(8.0, 200.0, 1.0) var arena_depth: float = 40.0

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	_update_ground_size()
	_position_camera()


func is_xz_position_inside_playable_bounds(horizontal_position: Vector2) -> bool:
	return absf(horizontal_position.x) <= arena_width * 0.5 and absf(horizontal_position.y) <= arena_depth * 0.5


func is_world_position_inside_playable_bounds(world_position: Vector3) -> bool:
	return is_xz_position_inside_playable_bounds(Vector2(world_position.x, world_position.z))


func _update_ground_size() -> void:
	var ground_mesh := $Ground/MeshInstance3D.mesh as PlaneMesh
	if ground_mesh != null:
		ground_mesh.size = Vector2(arena_width, arena_depth)

	var ground_collision := $Ground/CollisionShape3D.shape as BoxShape3D
	if ground_collision != null:
		ground_collision.size = Vector3(arena_width, 0.5, arena_depth)


func _position_camera() -> void:
	# The target is the arena centre; this keeps the fixed prototype view near 55 degrees downward.
	var horizontal_distance: float = maxf(arena_depth * 0.5, 12.0)
	var camera_height: float = horizontal_distance * tan(deg_to_rad(55.0))
	camera.position = Vector3(0.0, camera_height, horizontal_distance)
	camera.look_at(Vector3.ZERO, Vector3.UP)
