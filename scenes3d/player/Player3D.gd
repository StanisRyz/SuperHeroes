class_name Player3D
extends CharacterBody3D

const ActionControllerScript = preload("res://scenes3d/player/PlayerActionController3D.gd")

## Reusable 3D player controller for the isolated migration prototype.
## Its public health, experience, movement, and dash methods mirror Player.gd where practical.

signal health_changed(current_health: int, max_health: int)
signal damage_taken(amount: int)
signal experience_changed(current_xp: int, xp_to_next_level: int, level: int)
signal level_up_available(level: int)
signal died
signal dash_cooldown_changed(cooldown_remaining: float, cooldown_total: float)
signal dash_started
signal dash_finished
signal invulnerability_changed(is_invulnerable: bool)
signal shield_changed(current: int, maximum: int)
signal shield_blocked(blocked_damage: int, remaining: int, maximum: int)

@export_category("Movement")
@export var movement_speed: float = 6.0
@export var gravity: float = 24.0
@export var rotation_speed: float = 12.0
@export var playable_bounds_margin: float = 0.75
@export_category("Health and experience")
@export var max_health: int = 100
@export var xp_to_next_level: int = 10
@export var experience_gain_multiplier: float = 1.0
@export_category("Dash")
@export var dash_speed_multiplier: float = 3.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 1.2
@export var dash_invulnerability_duration: float = 0.25
@export_category("Prototype debug")
@export var prototype_debug_enabled: bool = false

var current_health: int
var current_xp: int = 0
var level: int = 1
var external_move_vector: Vector2 = Vector2.ZERO
var is_dashing: bool = false
var dash_direction: Vector3 = Vector3.FORWARD
var dash_time_remaining: float = 0.0
var dash_cooldown_remaining: float = 0.0
var invulnerability_time_remaining: float = 0.0
var last_aim_direction: Vector2 = Vector2(0.0, -1.0)
var _shield_charges := 0
var _maximum_shield_charges := 0
var _shield_block_count := 0

var _last_move_direction: Vector3 = Vector3.FORWARD
var _has_playable_bounds: bool = false
var _playable_width: float = 0.0
var _playable_depth: float = 0.0
var _death_emitted: bool = false
var _was_invulnerable: bool = false
var _combat_facing_locked: bool = false
var _combat_facing_direction: Vector3 = Vector3.FORWARD
var _scripted_motion_active: bool = false
var _scripted_motion_direction: Vector3 = Vector3.ZERO
var _scripted_motion_time: float = 0.0
var _scripted_motion_duration: float = 0.0
var _scripted_motion_speed: float = 0.0
var _dash_action_token: int = 0

@onready var visual_root: Node3D = $VisualRoot
@onready var knight_visual: KnightVisual = $VisualRoot/KnightVisual
@onready var action_controller: Node = $ActionController
@onready var action_debug_tracer: Node = $ActionDebugTracer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	current_health = max_health
	set_external_move_vector(Vector2.ZERO)
	add_to_group("player3d")
	if action_debug_tracer != null and action_debug_tracer.has_method("setup"):
		action_debug_tracer.setup(action_controller, self, get_node_or_null("AbilityManager"), get_node_or_null("AutoAttack"), knight_visual)

func get_debug_state() -> Dictionary:
	return {"dead": is_dead(), "dashing": is_dashing, "dash_remaining": dash_time_remaining, "dash_cooldown": dash_cooldown_remaining, "scripted_motion": _scripted_motion_active, "scripted_remaining": _scripted_motion_time, "velocity": velocity, "invulnerable": is_invulnerable(), "action": action_controller.get_current_action_state()}


func _physics_process(delta: float) -> void:
	if is_dead():
		velocity = Vector3.ZERO
		cancel_dash("death")
		return

	_tick_dash_cooldown(delta)
	_tick_invulnerability(delta)
	_apply_gravity(delta)

	if _scripted_motion_active:
		_scripted_motion_time = maxf(_scripted_motion_time - delta, 0.0)
		velocity.x = _scripted_motion_direction.x * _get_scripted_motion_speed()
		velocity.z = _scripted_motion_direction.z * _get_scripted_motion_speed()
		if _scripted_motion_time <= 0.0:
			_scripted_motion_active = false
	elif is_dashing:
		dash_time_remaining = maxf(dash_time_remaining - delta, 0.0)
		velocity.x = dash_direction.x * movement_speed * dash_speed_multiplier
		velocity.z = dash_direction.z * movement_speed * dash_speed_multiplier
		if dash_time_remaining <= 0.0:
			_finish_dash()
	else:
		var move_direction: Vector3 = Vector3.ZERO if _is_normal_movement_blocked() else _get_current_move_direction()
		if not move_direction.is_zero_approx():
			_last_move_direction = move_direction
			last_aim_direction = WorldPlane.world_to_horizontal(move_direction)
			_update_visual_facing(move_direction, delta)
		velocity.x = move_direction.x * movement_speed
		velocity.z = move_direction.z * movement_speed

	if knight_visual != null:
		knight_visual.set_locomotion_amount(Vector2(velocity.x, velocity.z).length() / maxf(movement_speed, 0.001))
	move_and_slide()
	_clamp_to_playable_bounds()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dash") and try_dash():
		get_viewport().set_input_as_handled()
	if prototype_debug_enabled and event.is_action_pressed("debug_add_xp"):
		debug_add_experience(xp_to_next_level)
		get_viewport().set_input_as_handled()
	if prototype_debug_enabled and event.is_action_pressed("ability_1"):
		request_attack_animation()
		get_viewport().set_input_as_handled()
	if prototype_debug_enabled and event.is_action_pressed("ability_2"):
		take_damage(10)
		get_viewport().set_input_as_handled()
	if prototype_debug_enabled and event.is_action_pressed("ability_3"):
		take_damage(max_health)
		get_viewport().set_input_as_handled()


func take_damage(amount: int) -> void:
	if amount <= 0 or is_dead() or is_invulnerable():
		return
	if consume_shield_charge():
		_shield_block_count += 1
		shield_blocked.emit(amount, _shield_charges, _maximum_shield_charges)
		return

	var previous_health: int = current_health
	current_health = clampi(current_health - amount, 0, max_health)
	if current_health == previous_health:
		return

	damage_taken.emit(previous_health - current_health)
	health_changed.emit(current_health, max_health)
	if knight_visual != null:
		knight_visual.play_hit()
	if current_health == 0:
		_emit_died_once()


func heal(amount: int) -> void:
	if amount <= 0 or is_dead():
		return

	var previous_health: int = current_health
	current_health = clampi(current_health + amount, 0, max_health)
	if current_health != previous_health:
		health_changed.emit(current_health, max_health)


func configure_shield_charges(maximum: int, refill: bool = false) -> void:
	maximum = maxi(maximum, 0)
	var previous_current := _shield_charges
	var previous_maximum := _maximum_shield_charges
	_maximum_shield_charges = maximum
	_shield_charges = _maximum_shield_charges if refill else mini(_shield_charges, _maximum_shield_charges)
	if _shield_charges != previous_current or _maximum_shield_charges != previous_maximum:
		shield_changed.emit(_shield_charges, _maximum_shield_charges)


func add_shield_charges(amount: int) -> int:
	if amount <= 0 or _maximum_shield_charges <= 0:
		return 0
	var previous_current := _shield_charges
	_shield_charges = clampi(_shield_charges + amount, 0, _maximum_shield_charges)
	var added := _shield_charges - previous_current
	if added > 0:
		shield_changed.emit(_shield_charges, _maximum_shield_charges)
	return added


func consume_shield_charge() -> bool:
	if _shield_charges <= 0:
		return false
	_shield_charges -= 1
	shield_changed.emit(_shield_charges, _maximum_shield_charges)
	return true


func get_shield_charges() -> int:
	return _shield_charges


func get_maximum_shield_charges() -> int:
	return _maximum_shield_charges


func get_shield_block_count() -> int:
	return _shield_block_count


func clear_shield_charges() -> void:
	var previous_current := _shield_charges
	var previous_maximum := _maximum_shield_charges
	_shield_charges = 0
	_maximum_shield_charges = 0
	_shield_block_count = 0
	if previous_current != 0 or previous_maximum != 0:
		shield_changed.emit(0, 0)


func add_experience(amount: int) -> void:
	amount = maxi(roundi(float(amount) * maxf(experience_gain_multiplier, 0.0)), 0)
	if amount <= 0 or is_dead():
		return

	current_xp += amount
	var gained_levels: Array[int] = []
	while current_xp >= xp_to_next_level:
		current_xp -= xp_to_next_level
		level += 1
		gained_levels.append(level)
		xp_to_next_level += 5

	experience_changed.emit(current_xp, xp_to_next_level, level)
	for gained_level: int in gained_levels:
		level_up_available.emit(gained_level)


func debug_add_experience(amount: int) -> void:
	if amount > 0:
		add_experience(amount)


func debug_gain_one_level() -> void:
	if is_dead():
		return
	level += 1
	experience_changed.emit(current_xp, xp_to_next_level, level)
	level_up_available.emit(level)


func is_dead() -> bool:
	return current_health <= 0


func try_dash() -> bool:
	if not can_dash():
		return false
	var action_token: int = int(action_controller.try_begin_dash())
	if action_token == 0:
		return false
	_dash_action_token = action_token

	dash_direction = _get_dash_direction()
	_last_move_direction = dash_direction
	last_aim_direction = WorldPlane.world_to_horizontal(dash_direction)
	is_dashing = true
	dash_time_remaining = dash_duration
	dash_cooldown_remaining = dash_cooldown
	invulnerability_time_remaining = maxf(invulnerability_time_remaining, dash_invulnerability_duration)
	_was_invulnerable = true
	dash_started.emit()
	invulnerability_changed.emit(true)
	dash_cooldown_changed.emit(dash_cooldown_remaining, dash_cooldown)
	return true


func can_dash() -> bool:
	return not get_tree().paused and not is_dead() and not _scripted_motion_active and dash_cooldown_remaining <= 0.0

func _finish_dash() -> void:
	is_dashing = false
	dash_time_remaining = 0.0
	if _dash_action_token != 0:
		action_controller.finish_action(_dash_action_token)
		_dash_action_token = 0
	dash_finished.emit()

func cancel_dash(reason: String = "") -> void:
	is_dashing = false
	dash_time_remaining = 0.0
	if _dash_action_token != 0:
		action_controller.cancel_action(_dash_action_token, reason)
		_dash_action_token = 0


func start_scripted_motion(owner_token: int, direction: Vector3, distance: float, duration: float, invulnerability_duration: float) -> bool:
	if is_dead() or is_dashing or not action_controller.is_action_active(ActionControllerScript.ActionType.ABILITY) or owner_token != int(action_controller.get_current_action_state().get("token", 0)) or _scripted_motion_active or duration <= 0.0:
		return false
	direction.y = 0.0
	if direction.is_zero_approx():
		return false
	_scripted_motion_active = true
	_scripted_motion_direction = direction.normalized()
	_scripted_motion_duration = duration
	_scripted_motion_time = duration
	_scripted_motion_speed = maxf(distance, 0.0) / duration
	invulnerability_time_remaining = maxf(invulnerability_time_remaining, invulnerability_duration)
	return true


func is_scripted_motion_active() -> bool:
	return _scripted_motion_active


func cancel_scripted_motion() -> void:
	_scripted_motion_active = false




func _get_scripted_motion_speed() -> float:
	return _scripted_motion_speed


func is_invulnerable() -> bool:
	return invulnerability_time_remaining > 0.0


func set_external_move_vector(direction: Vector2) -> void:
	external_move_vector = direction.limit_length(1.0)


func get_aim_direction() -> Vector2:
	return last_aim_direction if not last_aim_direction.is_zero_approx() else Vector2(0.0, -1.0)


func request_attack_animation() -> bool:
	return knight_visual != null and knight_visual.play_attack()


func lock_combat_facing(direction: Vector3) -> void:
	direction.y = 0.0
	if direction.is_zero_approx():
		return
	_combat_facing_locked = true
	_combat_facing_direction = direction.normalized()
	_update_visual_facing(_combat_facing_direction, 0.2)


func release_combat_facing() -> void:
	_combat_facing_locked = false


func set_playable_bounds(width: float, depth: float) -> void:
	_playable_width = maxf(width, 0.0)
	_playable_depth = maxf(depth, 0.0)
	_has_playable_bounds = _playable_width > 0.0 and _playable_depth > 0.0
	_clamp_to_playable_bounds()


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravity * delta


func _get_current_move_direction() -> Vector3:
	var keyboard_direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var horizontal_direction: Vector2 = keyboard_direction if not keyboard_direction.is_zero_approx() else external_move_vector
	return WorldPlane.horizontal_to_world(horizontal_direction.limit_length(1.0)).normalized()


func _is_normal_movement_blocked() -> bool:
	return action_controller != null and action_controller.is_action_active(ActionControllerScript.ActionType.ABILITY)


func _get_dash_direction() -> Vector3:
	var direction: Vector3 = _get_current_move_direction()
	if direction.is_zero_approx():
		direction = _last_move_direction
	return direction.normalized() if not direction.is_zero_approx() else Vector3.FORWARD


func _update_visual_facing(direction: Vector3, delta: float) -> void:
	if _combat_facing_locked:
		direction = _combat_facing_direction
	var target_yaw: float = atan2(-direction.x, -direction.z)
	visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_yaw, 1.0 - exp(-rotation_speed * delta))


func _clamp_to_playable_bounds() -> void:
	if not _has_playable_bounds:
		return

	var half_width: float = maxf(_playable_width * 0.5 - playable_bounds_margin, 0.0)
	var half_depth: float = maxf(_playable_depth * 0.5 - playable_bounds_margin, 0.0)
	global_position = Vector3(
		clampf(global_position.x, -half_width, half_width),
		global_position.y,
		clampf(global_position.z, -half_depth, half_depth)
	)


func _tick_dash_cooldown(delta: float) -> void:
	if dash_cooldown_remaining <= 0.0:
		return
	dash_cooldown_remaining = maxf(dash_cooldown_remaining - delta, 0.0)
	dash_cooldown_changed.emit(dash_cooldown_remaining, dash_cooldown)


func _tick_invulnerability(delta: float) -> void:
	if invulnerability_time_remaining > 0.0:
		invulnerability_time_remaining = maxf(invulnerability_time_remaining - delta, 0.0)

	var now_invulnerable: bool = is_invulnerable()
	if now_invulnerable != _was_invulnerable:
		_was_invulnerable = now_invulnerable
		invulnerability_changed.emit(now_invulnerable)


func _emit_died_once() -> void:
	if _death_emitted:
		return
	_death_emitted = true
	if knight_visual != null:
		knight_visual.play_death()
	died.emit()
