extends Node3D

## Isolated visual prototype for the early 3D migration.
## This scene deliberately does not initialize any of the 2D runtime managers.

const WorldPlane = preload("res://scenes3d/utilities/WorldPlane.gd")

@export_range(8.0, 200.0, 1.0) var arena_width: float = 40.0
@export_range(8.0, 200.0, 1.0) var arena_depth: float = 40.0

@onready var player: Player3D = $PlayerContainer/Player3D
@onready var player_spawn: Marker3D = $PlayerSpawn
@onready var camera_rig: CameraRig3D = $CameraRig3D


func _ready() -> void:
	_update_ground_size()
	player.global_position = player_spawn.global_position
	player.set_playable_bounds(arena_width, arena_depth)
	camera_rig.setup(player)


func is_xz_position_inside_playable_bounds(horizontal_position: Vector2) -> bool:
	return absf(horizontal_position.x) <= arena_width * 0.5 and absf(horizontal_position.y) <= arena_depth * 0.5


func is_world_position_inside_playable_bounds(world_position: Vector3) -> bool:
	return is_xz_position_inside_playable_bounds(WorldPlane.world_to_horizontal(world_position))


func clamp_world_position_to_playable_bounds(world_position: Vector3) -> Vector3:
	var horizontal_position: Vector2 = WorldPlane.world_to_horizontal(world_position)
	horizontal_position.x = clampf(horizontal_position.x, -arena_width * 0.5, arena_width * 0.5)
	horizontal_position.y = clampf(horizontal_position.y, -arena_depth * 0.5, arena_depth * 0.5)
	return WorldPlane.horizontal_to_world(horizontal_position, world_position.y)


func _update_ground_size() -> void:
	var ground_mesh := $Ground/MeshInstance3D.mesh as PlaneMesh
	if ground_mesh != null:
		ground_mesh.size = Vector2(arena_width, arena_depth)

	var ground_collision := $Ground/CollisionShape3D.shape as BoxShape3D
	if ground_collision != null:
		ground_collision.size = Vector3(arena_width, 0.5, arena_depth)
