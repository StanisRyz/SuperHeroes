class_name CameraRig3D
extends Node3D

## Fixed-angle, smoothly following prototype camera. It never inherits player rotation.

@export var height: float = 18.0
@export var backward_distance: float = 14.0
@export var follow_speed: float = 10.0
@export var look_at_height: float = 0.8
@export_range(20.0, 90.0, 1.0) var camera_fov: float = 38.0

var _target: Player3D = null

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	camera.fov = camera_fov
	camera.current = true


func setup(target: Player3D) -> void:
	_target = target
	snap_to_target()


func _process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		return

	var target_position: Vector3 = _get_target_camera_position()
	var follow_weight: float = 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(target_position, follow_weight)


func snap_to_target() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	global_position = _get_target_camera_position()
	look_at(_get_target_look_position(), Vector3.UP)


func _get_target_camera_position() -> Vector3:
	return _target.global_position + Vector3(0.0, height, backward_distance)


func _get_target_look_position() -> Vector3:
	return _target.global_position + Vector3.UP * look_at_height
