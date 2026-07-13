extends Node3D

## Presentation-only legacy Guardian Drone orbit. Attacks remain manager-owned.
const ORBIT_RADIUS := 1.45
const ORBIT_SPEED := -1.8

var _player: Node3D
var _orbit_angle := 0.0


func setup(player: Node3D) -> void:
	_player = player


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player) or _player.is_queued_for_deletion():
		queue_free()
		return
	_orbit_angle += ORBIT_SPEED * delta
	global_position = _player.global_position + Vector3(cos(_orbit_angle) * ORBIT_RADIUS, 0.72, sin(_orbit_angle) * ORBIT_RADIUS)
