class_name ExperiencePickup3D
extends Area3D

@export var experience_value: int = 1
@export var hover_height: float = 0.12
@export var hover_speed: float = 2.0
@export var rotation_speed: float = 2.4

var _collected: bool = false
var _base_y: float = 0.0
var _elapsed: float = 0.0
var _attraction_target: Node3D
var _attraction_speed := 0.0


func _ready() -> void:
	_base_y = global_position.y


func set_world_height(world_height: float) -> void:
	_base_y = world_height
	global_position.y = world_height


func set_attraction_target(target: Node3D, speed: float) -> void:
	_attraction_target = target
	_attraction_speed = maxf(speed, 0.0)


func clear_attraction_target() -> void:
	_attraction_target = null
	_attraction_speed = 0.0


func is_attracted() -> bool:
	return _attraction_target != null and is_instance_valid(_attraction_target)


func _process(delta: float) -> void:
	_elapsed += delta
	if is_attracted() and not _collected:
		var target_position := _attraction_target.global_position
		var horizontal_target := Vector3(target_position.x, global_position.y, target_position.z)
		global_position = global_position.move_toward(horizontal_target, _attraction_speed * delta)
	global_position.y = _base_y + sin(_elapsed * hover_speed) * hover_height
	rotate_y(rotation_speed * delta)


func _on_body_entered(body: Node3D) -> void:
	if _collected or not body is Player3D:
		return
	_collected = true
	var player := body as Player3D
	player.add_experience(experience_value)
	queue_free()
