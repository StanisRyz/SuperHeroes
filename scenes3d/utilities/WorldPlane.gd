class_name WorldPlane
extends RefCounted

## Converts the game-facing horizontal plane (Vector2) to Godot 3D's XZ plane.

static func horizontal_to_world(horizontal_position: Vector2, height: float = 0.0) -> Vector3:
	return Vector3(horizontal_position.x, height, horizontal_position.y)


static func world_to_horizontal(world_position: Vector3) -> Vector2:
	return Vector2(world_position.x, world_position.z)
