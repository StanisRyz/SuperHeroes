extends Node3D

var _remaining := 0.16
var _direction := Vector3.FORWARD

func setup(origin: Vector3, direction: Vector3) -> void:
	global_position = origin
	_direction = direction.normalized()
	look_at(global_position + _direction, Vector3.UP)

func _process(delta: float) -> void:
	global_position += _direction * 35.0 * delta
	_remaining -= delta
	if _remaining <= 0.0: queue_free()
