extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)
signal died(enemy: Node)

@export var speed: float = 120.0
@export var max_health: int = 20
@export var contact_damage: int = 10
@export var contact_damage_interval: float = 1.0

var current_health: int
var target: Node2D
var _target_in_contact := false
var _contact_damage_cooldown := 0.0
var _hit_flash_tween: Tween

@onready var contact_damage_area: Area2D = get_node_or_null("ContactDamageArea")
@onready var health_bar: ProgressBar = get_node_or_null("HealthBar")
@onready var body_visual: CanvasItem = get_node_or_null("Body")
@onready var core_visual: CanvasItem = get_node_or_null("Core")

func _ready() -> void:
	current_health = max_health
	_update_health_bar()

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

	var previous_health := current_health
	current_health = clampi(current_health - amount, 0, max_health)
	if current_health != previous_health:
		health_changed.emit(current_health, max_health)
		_update_health_bar()
		_play_hit_flash()

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


func _update_health_bar() -> void:
	if health_bar == null:
		return

	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.visible = current_health < max_health


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
		_hit_flash_tween.parallel().tween_property(visual, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.08).from(Color(1.0, 0.75, 0.75, 1.0))
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
