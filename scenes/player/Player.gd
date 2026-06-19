extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)
signal experience_changed(current_xp: int, xp_to_next_level: int, level: int)
signal level_up_available(level: int)
signal died
signal dash_cooldown_changed(cooldown_remaining: float, cooldown_total: float)
signal dash_started
signal dash_finished
signal invulnerability_changed(is_invulnerable: bool)

@export var speed: float = 260.0
@export var bounds_margin: float = 24.0
@export var max_health: int = 100
@export var xp_to_next_level: int = 10
@export var dash_speed_multiplier: float = 3.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 1.2
@export var dash_invulnerability_duration: float = 0.25
@export var dash_burst_scene: PackedScene

var current_health: int
var current_xp: int = 0
var level: int = 1
var external_move_vector: Vector2 = Vector2.ZERO
var is_dashing := false
var dash_direction := Vector2.ZERO
var dash_time_remaining := 0.0
var dash_cooldown_remaining := 0.0
var invulnerability_time_remaining := 0.0
var debug_invulnerable: bool = false
var _playable_rect: Rect2
var _has_playable_rect := false
var _hit_flash_tween: Tween
var _camera_shake_tween: Tween
var _screen_shake_enabled := true
var last_aim_direction: Vector2 = Vector2.RIGHT
var _last_move_direction := Vector2.RIGHT
var _was_invulnerable := false

@onready var camera: Camera2D = $Camera2D
@onready var body_visual: CanvasItem = get_node_or_null("Body")
@onready var core_visual: CanvasItem = get_node_or_null("Core")

func _ready() -> void:
	add_to_group("player")
	current_health = max_health


func _physics_process(delta: float) -> void:
	if is_dead():
		velocity = Vector2.ZERO
		is_dashing = false
		return

	_tick_dash_cooldown(delta)
	_tick_invulnerability(delta)

	if is_dashing:
		dash_time_remaining = maxf(dash_time_remaining - delta, 0.0)
		velocity = dash_direction * speed * dash_speed_multiplier
		if dash_time_remaining <= 0.0:
			is_dashing = false
			dash_finished.emit()
	else:
		var direction := _get_current_move_direction()
		if not direction.is_zero_approx():
			_last_move_direction = direction
			last_aim_direction = direction
		velocity = direction * speed

	move_and_slide()
	_clamp_to_playable_rect()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dash") and not get_tree().paused:
		if try_dash():
			get_viewport().set_input_as_handled()


func take_damage(amount: int) -> void:
	if amount <= 0 or is_dead() or is_invulnerable() or debug_invulnerable:
		return

	var buff_manager := get_node_or_null("PlayerBuffManager")
	if buff_manager != null and buff_manager.has_method("consume_shield_charge"):
		if buff_manager.consume_shield_charge():
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


func try_dash() -> bool:
	if not can_dash():
		return false

	dash_direction = _get_dash_direction()
	last_aim_direction = dash_direction
	is_dashing = true
	dash_time_remaining = dash_duration
	dash_cooldown_remaining = dash_cooldown
	invulnerability_time_remaining = maxf(invulnerability_time_remaining, dash_invulnerability_duration)
	_update_invulnerability_visual(true)
	_was_invulnerable = true
	dash_started.emit()
	invulnerability_changed.emit(true)
	dash_cooldown_changed.emit(dash_cooldown_remaining, dash_cooldown)
	_spawn_dash_burst()
	return true


func can_dash() -> bool:
	return not get_tree().paused and not is_dead() and dash_cooldown_remaining <= 0.0


func is_invulnerable() -> bool:
	return invulnerability_time_remaining > 0.0


func set_debug_invulnerable(enabled: bool) -> void:
	debug_invulnerable = enabled
	print("DEBUG_PLAYER: invulnerable=%s" % enabled)


func is_debug_invulnerable() -> bool:
	return debug_invulnerable


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


func heal(amount: int) -> void:
	if amount <= 0 or is_dead():
		return

	var previous_health := current_health
	current_health = clampi(current_health + amount, 0, max_health)
	if current_health != previous_health:
		health_changed.emit(current_health, max_health)


func debug_gain_one_level() -> void:
	if is_dead():
		return

	level += 1
	print("DEBUG_PLAYER: level increased to %d" % level)
	experience_changed.emit(current_xp, xp_to_next_level, level)
	level_up_available.emit(level)


func get_aim_direction() -> Vector2:
	return last_aim_direction if not last_aim_direction.is_zero_approx() else Vector2.RIGHT


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


func shake_camera(strength: float = 6.0, duration: float = 0.12) -> void:
	if camera == null or not _screen_shake_enabled:
		return

	if _camera_shake_tween != null:
		_camera_shake_tween.kill()

	camera.offset = Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
	_camera_shake_tween = create_tween()
	_camera_shake_tween.tween_property(camera, "offset", Vector2.ZERO, duration)


func set_screen_shake_enabled(enabled: bool) -> void:
	_screen_shake_enabled = enabled
	if not _screen_shake_enabled and camera != null:
		if _camera_shake_tween != null:
			_camera_shake_tween.kill()
		camera.offset = Vector2.ZERO


func _clamp_to_playable_rect() -> void:
	if not _has_playable_rect:
		return

	global_position = Vector2(
		clampf(global_position.x, _playable_rect.position.x + bounds_margin, _playable_rect.end.x - bounds_margin),
		clampf(global_position.y, _playable_rect.position.y + bounds_margin, _playable_rect.end.y - bounds_margin)
	)


func _tick_dash_cooldown(delta: float) -> void:
	if dash_cooldown_remaining <= 0.0:
		return

	dash_cooldown_remaining = maxf(dash_cooldown_remaining - delta, 0.0)
	dash_cooldown_changed.emit(dash_cooldown_remaining, dash_cooldown)


func _tick_invulnerability(delta: float) -> void:
	if invulnerability_time_remaining > 0.0:
		invulnerability_time_remaining = maxf(invulnerability_time_remaining - delta, 0.0)

	var now_invulnerable := is_invulnerable()
	if now_invulnerable != _was_invulnerable:
		_was_invulnerable = now_invulnerable
		_update_invulnerability_visual(now_invulnerable)
		invulnerability_changed.emit(now_invulnerable)


func _get_current_move_direction() -> Vector2:
	var keyboard_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := external_move_vector if not external_move_vector.is_zero_approx() else keyboard_direction
	return direction.limit_length(1.0)


func _get_dash_direction() -> Vector2:
	var direction := _get_current_move_direction()
	if direction.is_zero_approx():
		direction = _last_move_direction
	if direction.is_zero_approx():
		direction = Vector2.RIGHT

	return direction.normalized()


func _spawn_dash_burst() -> void:
	if dash_burst_scene == null:
		return

	var burst_node := dash_burst_scene.instantiate()
	if not burst_node is Node2D:
		push_warning("DashBurst scene root must be Node2D.")
		burst_node.queue_free()
		return

	var burst := burst_node as Node2D
	var burst_parent := get_parent()
	if burst_parent == null:
		burst_parent = get_tree().current_scene
	if burst_parent == null:
		burst.queue_free()
		return

	burst_parent.add_child(burst)
	if burst.has_method("play"):
		burst.play(global_position, dash_direction)
	else:
		burst.global_position = global_position


func _update_invulnerability_visual(enabled: bool) -> void:
	var alpha := 0.58 if enabled else 1.0
	for visual in _get_flash_visuals():
		visual.modulate = Color(1.0, 1.0, 1.0, alpha)


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
	_update_invulnerability_visual(is_invulnerable())


func _get_flash_visuals() -> Array[CanvasItem]:
	var visuals: Array[CanvasItem] = []
	if body_visual != null:
		visuals.append(body_visual)
	if core_visual != null:
		visuals.append(core_visual)
	return visuals
