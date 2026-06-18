extends CharacterBody2D

@export var speed: float = 120.0

var target: Node2D

func set_target(new_target: Node2D) -> void:
	target = new_target


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(target):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var offset := target.global_position - global_position
	if offset.is_zero_approx():
		velocity = Vector2.ZERO
	else:
		velocity = offset.normalized() * speed

	move_and_slide()
