extends CharacterBody2D

signal died(enemy: Node)

@export var speed: float = 120.0
@export var max_health: int = 20
@export var contact_damage: int = 10
@export var contact_damage_interval: float = 1.0

var current_health: int
var target: Node2D
var _target_in_contact := false
var _contact_damage_cooldown := 0.0

@onready var contact_damage_area: Area2D = get_node_or_null("ContactDamageArea")

func _ready() -> void:
	current_health = max_health

	if contact_damage_area == null:
		push_warning("Enemy could not find ContactDamageArea.")
		return

	contact_damage_area.body_entered.connect(_on_contact_damage_area_body_entered)
	contact_damage_area.body_exited.connect(_on_contact_damage_area_body_exited)


func set_target(new_target: Node2D) -> void:
	target = new_target


func _physics_process(delta: float) -> void:
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
	_tick_contact_damage(delta)


func take_damage(amount: int) -> void:
	if amount <= 0 or is_dead():
		return

	current_health = clampi(current_health - amount, 0, max_health)
	if current_health == 0:
		die()


func die() -> void:
	if is_queued_for_deletion():
		return

	died.emit(self)
	queue_free()


func is_dead() -> bool:
	return current_health <= 0 or is_queued_for_deletion()


func _tick_contact_damage(delta: float) -> void:
	if _contact_damage_cooldown > 0.0:
		_contact_damage_cooldown -= delta

	if not _target_in_contact or _contact_damage_cooldown > 0.0:
		return

	if is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(contact_damage)
		_contact_damage_cooldown = contact_damage_interval


func _on_contact_damage_area_body_entered(body: Node2D) -> void:
	if body == target:
		_target_in_contact = true


func _on_contact_damage_area_body_exited(body: Node2D) -> void:
	if body == target:
		_target_in_contact = false
