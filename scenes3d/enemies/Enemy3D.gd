class_name Enemy3D
extends CharacterBody3D

signal health_changed(current_health: int, max_health: int)
signal damage_taken(amount: int, world_position: Vector3)
signal died(enemy: Enemy3D)

@export var movement_speed: float = 3.0
@export var gravity: float = 24.0
@export var rotation_speed: float = 10.0
@export var max_health: int = 20
@export var contact_damage: int = 10
@export var contact_damage_interval: float = 1.0
@export var attack_range: float = 1.35
@export var experience_value: int = 1

var current_health: int
var variant_id: String = ""
var display_name: String = ""
var role: String = ""
var behavior_id: String = "chase"
var target: Player3D = null

var _dead: bool = false
var _target_in_contact: bool = false
var _attack_cooldown_remaining: float = 0.0
var _attack_damage_armed: bool = false
var _knockback_velocity: Vector3 = Vector3.ZERO
var _knockback_time_remaining: float = 0.0
var _temporary_modifiers: Dictionary = {}
var _base_movement_speed: float = 3.0
var _base_contact_damage: int = 10

@onready var visual_root: Node3D = $VisualRoot
@onready var skeleton_visual: SkeletonWarriorVisual = $VisualRoot/SkeletonWarriorVisual
@onready var contact_damage_area: Area3D = $ContactDamageArea


func _ready() -> void:
	current_health = max_health
	_base_movement_speed = movement_speed
	_base_contact_damage = contact_damage
	add_to_group("enemies3d")
	if skeleton_visual.attack_impact.is_connected(_on_attack_impact) == false:
		skeleton_visual.attack_impact.connect(_on_attack_impact)
	if skeleton_visual.death_animation_finished.is_connected(_on_death_animation_finished) == false:
		skeleton_visual.death_animation_finished.connect(_on_death_animation_finished)


func _physics_process(delta: float) -> void:
	if _dead:
		velocity = Vector3.ZERO
		return
	_tick_attack_cooldown(delta)
	_tick_temporary_modifiers(delta)
	_apply_gravity(delta)
	var horizontal_velocity: Vector3 = _get_horizontal_velocity(delta)
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z
	if not horizontal_velocity.is_zero_approx():
		_update_visual_facing(horizontal_velocity, delta)
	skeleton_visual.set_locomotion_amount(Vector2(velocity.x, velocity.z).length() / maxf(movement_speed, 0.001))
	move_and_slide()
	_try_start_contact_attack()


func set_target(new_target: Player3D) -> void:
	target = new_target


func apply_variant(variant: Dictionary) -> void:
	variant_id = str(variant.get("id", variant_id))
	display_name = str(variant.get("display_name", display_name))
	role = str(variant.get("role", role))
	behavior_id = "chase"
	movement_speed = float(variant.get("world_speed", movement_speed))
	max_health = int(variant.get("max_health", max_health))
	contact_damage = int(variant.get("contact_damage", contact_damage))
	experience_value = int(variant.get("experience_value", experience_value))
	current_health = max_health
	_base_movement_speed = movement_speed
	_base_contact_damage = contact_damage
	_recalculate_temporary_modifiers()


func apply_temporary_modifier(modifier_id: String, values: Dictionary, duration: float) -> void:
	if is_dead() or modifier_id.is_empty():
		return
	_temporary_modifiers[modifier_id] = {"values": values.duplicate(), "remaining": maxf(duration, 0.0)}
	_recalculate_temporary_modifiers()


func apply_special_modifier(modifier: Dictionary) -> void:
	max_health = int(round(float(max_health) * float(modifier.get("health_multiplier", 1.0))))
	current_health = max_health
	movement_speed *= float(modifier.get("speed_multiplier", 1.0))
	contact_damage = int(round(float(contact_damage) * float(modifier.get("damage_multiplier", 1.0))))
	experience_value = int(round(float(experience_value) * float(modifier.get("xp_multiplier", 1.0))))
	if modifier.has("display_name"):
		display_name = str(modifier["display_name"])
	if modifier.has("scale_multiplier"):
		scale *= float(modifier["scale_multiplier"])


func take_damage(amount: int) -> void:
	if amount <= 0 or is_dead():
		return
	var previous_health: int = current_health
	current_health = clampi(current_health - amount, 0, max_health)
	if current_health == previous_health:
		return
	damage_taken.emit(previous_health - current_health, global_position)
	health_changed.emit(current_health, max_health)
	skeleton_visual.play_hit()
	if current_health == 0:
		die()


func die() -> void:
	if _dead:
		return
	_dead = true
	_temporary_modifiers.clear()
	velocity = Vector3.ZERO
	contact_damage_area.monitoring = false
	contact_damage_area.monitorable = false
	died.emit(self)
	if not skeleton_visual.play_death():
		queue_free()


func is_dead() -> bool:
	return _dead or current_health <= 0 or is_queued_for_deletion()


func get_experience_value() -> int:
	return experience_value


func apply_knockback(direction: Vector3, force: float, duration: float) -> void:
	if is_dead() or direction.is_zero_approx():
		return
	_knockback_velocity = direction.normalized() * maxf(force, 0.0)
	_knockback_velocity.y = 0.0
	_knockback_time_remaining = maxf(duration, 0.0)


func _get_horizontal_velocity(delta: float) -> Vector3:
	if _knockback_time_remaining > 0.0:
		_knockback_time_remaining = maxf(_knockback_time_remaining - delta, 0.0)
		return _knockback_velocity
	if target == null or not is_instance_valid(target) or target.is_dead():
		return Vector3.ZERO
	var to_target: Vector3 = target.global_position - global_position
	to_target.y = 0.0
	if to_target.length() <= attack_range:
		return Vector3.ZERO
	return to_target.normalized() * movement_speed


func _try_start_contact_attack() -> void:
	if _dead or not _target_in_contact or _attack_cooldown_remaining > 0.0:
		return
	if target == null or not is_instance_valid(target) or target.is_dead():
		return
	if _horizontal_distance_to_target() > attack_range:
		return
	if skeleton_visual.play_attack():
		_attack_damage_armed = true
		_attack_cooldown_remaining = contact_damage_interval


func _on_attack_impact() -> void:
	if not _attack_damage_armed or _dead:
		return
	_attack_damage_armed = false
	if target == null or not is_instance_valid(target) or target.is_dead() or target.is_invulnerable():
		return
	if _horizontal_distance_to_target() <= attack_range:
		target.take_damage(contact_damage)


func _on_contact_damage_area_body_entered(body: Node3D) -> void:
	if body == target:
		_target_in_contact = true


func _on_contact_damage_area_body_exited(body: Node3D) -> void:
	if body == target:
		_target_in_contact = false


func _on_death_animation_finished() -> void:
	if _dead:
		queue_free()


func _tick_attack_cooldown(delta: float) -> void:
	_attack_cooldown_remaining = maxf(_attack_cooldown_remaining - delta, 0.0)


func _tick_temporary_modifiers(delta: float) -> void:
	var changed := false
	for modifier_id: String in _temporary_modifiers.keys():
		var modifier: Dictionary = _temporary_modifiers[modifier_id]
		modifier["remaining"] = float(modifier["remaining"]) - delta
		if float(modifier["remaining"]) <= 0.0:
			_temporary_modifiers.erase(modifier_id)
		else:
			_temporary_modifiers[modifier_id] = modifier
		changed = true
	if changed:
		_recalculate_temporary_modifiers()


func _recalculate_temporary_modifiers() -> void:
	var speed_multiplier := 1.0
	var damage_multiplier := 1.0
	var stunned := false
	for modifier: Dictionary in _temporary_modifiers.values():
		var values: Dictionary = modifier.get("values", {})
		speed_multiplier *= float(values.get("movement_speed_multiplier", 1.0))
		damage_multiplier *= float(values.get("contact_damage_multiplier", 1.0))
		stunned = stunned or bool(values.get("stun", false))
	movement_speed = 0.0 if stunned else _base_movement_speed * speed_multiplier
	contact_damage = maxi(roundi(_base_contact_damage * damage_multiplier), 0)


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravity * delta


func _update_visual_facing(direction: Vector3, delta: float) -> void:
	var target_yaw: float = atan2(-direction.x, -direction.z)
	visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_yaw, 1.0 - exp(-rotation_speed * delta))


func _horizontal_distance_to_target() -> float:
	var offset: Vector3 = target.global_position - global_position
	offset.y = 0.0
	return offset.length()
