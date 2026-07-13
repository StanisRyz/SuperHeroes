class_name ExperiencePickup3D
extends Area3D

@export var experience_value: int = 1
@export var hover_height: float = 0.12
@export var hover_speed: float = 2.0
@export var rotation_speed: float = 2.4

var _collected: bool = false
var _base_y: float = 0.0
var _elapsed: float = 0.0


func _ready() -> void:
	_base_y = position.y


func _process(delta: float) -> void:
	_elapsed += delta
	position.y = _base_y + sin(_elapsed * hover_speed) * hover_height
	rotate_y(rotation_speed * delta)


func _on_body_entered(body: Node3D) -> void:
	if _collected or not body is Player3D:
		return
	_collected = true
	var player := body as Player3D
	player.add_experience(experience_value)
	queue_free()
