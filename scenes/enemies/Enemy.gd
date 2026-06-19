extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)
signal damage_taken(amount: int, world_position: Vector2)
signal died(enemy: Node)

@export var speed: float = 120.0
@export var max_health: int = 20
@export var contact_damage: int = 10
@export var contact_damage_interval: float = 1.0
@export var behavior_id: String = "chase"
@export var preferred_distance: float = 420.0
@export var charge_range: float = 340.0
@export var charge_windup: float = 0.35
@export var charge_speed_multiplier: float = 2.4
@export var charge_duration: float = 0.45
@export var charge_cooldown: float = 2.2
@export var shoot_range: float = 540.0
@export var shoot_interval: float = 1.8
@export var projectile_damage: int = 8
@export var projectile_speed: float = 360.0
@export var enemy_projectile_scene: PackedScene

var current_health: int
var experience_value: int = 1
var variant_id: String = ""
var display_name: String = ""
var is_elite: bool = false
var is_miniboss: bool = false
var guaranteed_powerup: bool = false
var target: Node2D
var _target_in_contact := false
var _contact_damage_cooldown := 0.0
var _hit_flash_tween: Tween
var _unknown_behavior_warning_shown := false
var _charge_state := "ready"
var _charge_timer := 0.0
var _charge_cooldown_remaining := 0.0
var _charge_direction := Vector2.ZERO
var _shoot_cooldown_remaining := 0.0

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


func apply_variant(variant: Dictionary) -> void:
	if variant.has("id"):
		variant_id = str(variant["id"])
	if variant.has("display_name"):
		display_name = str(variant["display_name"])
	if variant.has("behavior_id"):
		behavior_id = str(variant["behavior_id"])
	if variant.has("speed"):
		speed = float(variant["speed"])
	if variant.has("max_health"):
		max_health = int(variant["max_health"])
	if variant.has("contact_damage"):
		contact_damage = int(variant["contact_damage"])
	if variant.has("experience_value"):
		experience_value = int(variant["experience_value"])
	if variant.has("preferred_distance"):
		preferred_distance = float(variant["preferred_distance"])
	if variant.has("charge_range"):
		charge_range = float(variant["charge_range"])
	if variant.has("charge_windup"):
		charge_windup = float(variant["charge_windup"])
	if variant.has("charge_speed_multiplier"):
		charge_speed_multiplier = float(variant["charge_speed_multiplier"])
	if variant.has("charge_duration"):
		charge_duration = float(variant["charge_duration"])
	if variant.has("charge_cooldown"):
		charge_cooldown = float(variant["charge_cooldown"])
	if variant.has("shoot_range"):
		shoot_range = float(variant["shoot_range"])
	if variant.has("shoot_interval"):
		shoot_interval = float(variant["shoot_interval"])
	if variant.has("projectile_damage"):
		projectile_damage = int(variant["projectile_damage"])
	if variant.has("projectile_speed"):
		projectile_speed = float(variant["projectile_speed"])
	if variant.has("body_color") and body_visual != null:
		body_visual.set("color", variant["body_color"])
	if variant.has("core_color") and core_visual != null:
		core_visual.set("color", variant["core_color"])

	current_health = max_health
	_update_health_bar()


func get_experience_value() -> int:
	return experience_value


func apply_special_modifier(modifier: Dictionary) -> void:
	is_elite = modifier.get("is_elite", false)
	is_miniboss = modifier.get("is_miniboss", false)
	guaranteed_powerup = modifier.get("guaranteed_powerup", false)

	if modifier.has("display_name"):
		display_name = str(modifier["display_name"])

	if modifier.has("health_multiplier"):
		max_health = int(max_health * modifier["health_multiplier"])
		current_health = max_health
		_update_health_bar()

	if modifier.has("speed_multiplier"):
		speed *= float(modifier["speed_multiplier"])

	if modifier.has("damage_multiplier"):
		contact_damage = int(contact_damage * modifier["damage_multiplier"])

	if modifier.has("xp_multiplier"):
		experience_value = int(experience_value * modifier["xp_multiplier"])

	if modifier.has("scale_multiplier"):
		scale *= float(modifier["scale_multiplier"])

	if modifier.has("color_override"):
		var color: Color = modifier["color_override"]
		if body_visual != null:
			body_visual.set("color", color)
		if core_visual != null:
			# Darken core to match the visual style used by variants
			core_visual.set("color", color.darkened(0.5))

	# For miniboss, force chase behavior so it always pursues the player
	if is_miniboss:
		behavior_id = "chase"


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	match behavior_id:
		"chase":
			_tick_chase_behavior(delta)
		"charger":
			_tick_charger_behavior(delta)
		"shooter":
			_tick_shooter_behavior(delta)
		_:
			if not _unknown_behavior_warning_shown:
				push_warning("Unknown enemy behavior_id: %s" % behavior_id)
				_unknown_behavior_warning_shown = true
			_tick_chase_behavior(delta)

	move_and_slide()
	_tick_contact_damage(delta)


func take_damage(amount: int) -> void:
	if amount <= 0 or is_dead():
		return

	var previous_health := current_health
	current_health = clampi(current_health - amount, 0, max_health)
	if current_health != previous_health:
		damage_taken.emit(previous_health - current_health, global_position)
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


func _tick_chase_behavior(_delta: float) -> void:
	var offset := target.global_position - global_position
	velocity = Vector2.ZERO if offset.is_zero_approx() else offset.normalized() * speed


func _tick_charger_behavior(delta: float) -> void:
	if _charge_cooldown_remaining > 0.0:
		_charge_cooldown_remaining = maxf(_charge_cooldown_remaining - delta, 0.0)

	match _charge_state:
		"ready":
			var offset := target.global_position - global_position
			if offset.length() <= charge_range and _charge_cooldown_remaining <= 0.0 and not offset.is_zero_approx():
				_charge_state = "windup"
				_charge_timer = charge_windup
				_charge_direction = offset.normalized()
				_set_windup_visual(true)
				velocity = Vector2.ZERO
			else:
				_tick_chase_behavior(delta)
		"windup":
			_charge_timer -= delta
			velocity = Vector2.ZERO
			if _charge_timer <= 0.0:
				_charge_state = "charging"
				_charge_timer = charge_duration
				_set_windup_visual(false)
		"charging":
			_charge_timer -= delta
			velocity = _charge_direction * speed * charge_speed_multiplier
			if _charge_timer <= 0.0:
				_charge_state = "ready"
				_charge_cooldown_remaining = charge_cooldown
				velocity = Vector2.ZERO
		_:
			_charge_state = "ready"
			_set_windup_visual(false)


func _tick_shooter_behavior(delta: float) -> void:
	if _shoot_cooldown_remaining > 0.0:
		_shoot_cooldown_remaining = maxf(_shoot_cooldown_remaining - delta, 0.0)

	var offset := target.global_position - global_position
	var distance := offset.length()
	if offset.is_zero_approx():
		velocity = Vector2.ZERO
	else:
		var direction := offset.normalized()
		if distance > preferred_distance + 40.0:
			velocity = direction * speed
		elif distance < preferred_distance - 40.0:
			velocity = -direction * speed
		else:
			velocity = Vector2.ZERO

	if distance <= shoot_range and _shoot_cooldown_remaining <= 0.0:
		_spawn_enemy_projectile(target.global_position)
		_shoot_cooldown_remaining = shoot_interval


func _spawn_enemy_projectile(target_position: Vector2) -> void:
	if enemy_projectile_scene == null:
		push_warning("Shooter enemy is missing enemy_projectile_scene.")
		return

	var projectile_node := enemy_projectile_scene.instantiate()
	if not projectile_node is Node2D:
		push_warning("EnemyProjectile scene root must be Node2D.")
		projectile_node.queue_free()
		return

	var enemy_parent := get_parent()
	var spawn_parent := enemy_parent.get_parent() if enemy_parent != null else null
	if spawn_parent == null:
		spawn_parent = get_tree().current_scene
	if spawn_parent == null:
		projectile_node.queue_free()
		return

	var projectile := projectile_node as Node2D
	spawn_parent.add_child(projectile)
	if projectile.has_method("setup"):
		projectile.setup(global_position, target_position, projectile_damage, projectile_speed)
	else:
		projectile.global_position = global_position


func _set_windup_visual(enabled: bool) -> void:
	var color := Color(1.0, 0.82, 0.45, 1.0) if enabled else Color(1.0, 1.0, 1.0, 1.0)
	for visual in _get_flash_visuals():
		visual.modulate = color


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
