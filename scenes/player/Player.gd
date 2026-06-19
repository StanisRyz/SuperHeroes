extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)
signal experience_changed(current_xp: int, xp_to_next_level: int, level: int)
signal level_up_available(level: int)
signal died

@export var speed: float = 260.0
@export var bounds_margin: float = 24.0
@export var max_health: int = 100
@export var xp_to_next_level: int = 10

var current_health: int
var current_xp: int = 0
var level: int = 1
var external_move_vector: Vector2 = Vector2.ZERO
var _playable_rect: Rect2
var _has_playable_rect := false
var _hit_flash_tween: Tween

@onready var camera: Camera2D = $Camera2D
@onready var body_visual: CanvasItem = get_node_or_null("Body")
@onready var core_visual: CanvasItem = get_node_or_null("Core")

func _ready() -> void:
	current_health = max_health


func _physics_process(_delta: float) -> void:
	if is_dead():
		velocity = Vector2.ZERO
		return

	var keyboard_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := external_move_vector if not external_move_vector.is_zero_approx() else keyboard_direction
	direction = direction.limit_length(1.0)
	velocity = direction * speed
	move_and_slide()
	_clamp_to_playable_rect()


func take_damage(amount: int) -> void:
	if amount <= 0 or is_dead():
		return

	var previous_health := current_health
	current_health = clampi(current_health - amount, 0, max_health)

	if current_health != previous_health:
		health_changed.emit(current_health, max_health)
		_play_hit_flash()

	if current_health == 0:
		died.emit()


func is_dead() -> bool:
	return current_health <= 0


func add_experience(amount: int) -> void:
	if amount <= 0:
		return

	current_xp += amount
	var gained_levels: Array[int] = []
	while current_xp >= xp_to_next_level:
		current_xp -= xp_to_next_level
		level += 1
		gained_levels.append(level)
		xp_to_next_level += 5

	experience_changed.emit(current_xp, xp_to_next_level, level)
	for gained_level in gained_levels:
			level_up_available.emit(gained_level)


func set_external_move_vector(direction: Vector2) -> void:
	external_move_vector = direction.limit_length(1.0)


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


func _play_hit_flash() -> void:
	if _hit_flash_tween != null:
		_hit_flash_tween.kill()

	var visuals := _get_flash_visuals()
	if visuals.is_empty():
		return

	for visual in visuals:
		visual.modulate = Color(1.0, 1.0, 1.0, 1.0)

	_hit_flash_tween = create_tween()
	for visual in visuals:
		_hit_flash_tween.parallel().tween_property(visual, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.04)
	for visual in visuals:
		_hit_flash_tween.parallel().tween_property(visual, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.08).from(Color(1.0, 0.45, 0.45, 1.0))
	_hit_flash_tween.finished.connect(_reset_hit_flash)


func _reset_hit_flash() -> void:
	for visual in _get_flash_visuals():
		visual.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _get_flash_visuals() -> Array[CanvasItem]:
	var visuals: Array[CanvasItem] = []
	if body_visual != null:
		visuals.append(body_visual)
	if core_visual != null:
		visuals.append(core_visual)
	return visuals
