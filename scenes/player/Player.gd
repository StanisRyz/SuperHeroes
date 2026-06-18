extends CharacterBody2D

@export var speed: float = 260.0
@export var bounds_margin: float = 24.0

var _playable_rect: Rect2
var _has_playable_rect := false

@onready var camera: Camera2D = $Camera2D

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
	_clamp_to_playable_rect()


func set_playable_rect(rect: Rect2) -> void:
	_playable_rect = rect
	_has_playable_rect = true


func set_camera_limits(rect: Rect2) -> void:
	camera.limit_left = int(rect.position.x)
	camera.limit_top = int(rect.position.y)
	camera.limit_right = int(rect.end.x)
	camera.limit_bottom = int(rect.end.y)


func _clamp_to_playable_rect() -> void:
	if not _has_playable_rect:
		return

	global_position = Vector2(
		clampf(global_position.x, _playable_rect.position.x + bounds_margin, _playable_rect.end.x - bounds_margin),
		clampf(global_position.y, _playable_rect.position.y + bounds_margin, _playable_rect.end.y - bounds_margin)
	)
