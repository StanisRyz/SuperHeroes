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
@export var explode_radius: float = 110.0
@export var explode_damage: int = 22
@export var explode_windup: float = 0.65
@export var explode_trigger_distance: float = 70.0
@export var orbit_distance: float = 135.0
@export var orbit_strength: float = 0.85
@export var orbit_direction: float = 1.0
@export var approach_distance: float = 230.0
@export var support_radius: float = 300.0
@export var support_interval: float = 4.0
@export var support_damage_multiplier: float = 1.25
@export var support_speed_multiplier: float = 1.18
@export var support_buff_duration: float = 5.0
@export var max_shield_value: int = 0

var current_health: int
var shield_value: int = 0
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
var _velocity_override_active: bool = false
var _velocity_override: Vector2 = Vector2.ZERO
var _explode_state := "ready"
var _explode_timer := 0.0
var _support_cooldown_remaining := 0.0
var _temporary_modifiers: Dictionary = {}
var _base_speed: float = 120.0
var _base_contact_damage: int = 10

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
	if variant.has("explode_radius"):
		explode_radius = float(variant["explode_radius"])
	if variant.has("explode_damage"):
		explode_damage = int(variant["explode_damage"])
	if variant.has("explode_windup"):
		explode_windup = float(variant["explode_windup"])
	if variant.has("explode_trigger_distance"):
		explode_trigger_distance = float(variant["explode_trigger_distance"])
	if variant.has("orbit_distance"):
		orbit_distance = float(variant["orbit_distance"])
	if variant.has("orbit_strength"):
		orbit_strength = float(variant["orbit_strength"])
	if variant.has("orbit_direction"):
		orbit_direction = float(variant["orbit_direction"])
	if variant.has("approach_distance"):
		approach_distance = float(variant["approach_distance"])
	if variant.has("support_radius"):
		support_radius = float(variant["support_radius"])
	if variant.has("support_interval"):
		support_interval = float(variant["support_interval"])
	if variant.has("support_damage_multiplier"):
		support_damage_multiplier = float(variant["support_damage_multiplier"])
	if variant.has("support_speed_multiplier"):
		support_speed_multiplier = float(variant["support_speed_multiplier"])
	if variant.has("support_buff_duration"):
		support_buff_duration = float(variant["support_buff_duration"])
	if variant.has("shield_value"):
		max_shield_value = int(variant["shield_value"])
		shield_value = max_shield_value
	if variant.has("body_color") and body_visual != null:
		body_visual.set("color", variant["body_color"])
	if variant.has("core_color") and core_visual != null:
		core_visual.set("color", variant["core_color"])

	current_health = max_health
	_base_speed = speed
	_base_contact_damage = contact_damage
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
		_base_speed = speed

	if modifier.has("damage_multiplier"):
		contact_damage = int(contact_damage * modifier["damage_multiplier"])
		_base_contact_damage = contact_damage

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


func set_velocity_override(vel: Vector2) -> void:
	_velocity_override = vel
	_velocity_override_active = true


func clear_velocity_override() -> void:
	_velocity_override_active = false
	_velocity_override = Vector2.ZERO


func apply_knockback(direction: Vector2, force: float, duration: float = 0.22) -> void:
	set_velocity_override(direction * force)
	var t := create_tween()
	t.tween_interval(duration)
	t.tween_callback(clear_velocity_override)


func _physics_process(delta: float) -> void:
	_tick_temporary_modifiers(delta)

	if not is_instance_valid(target):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if _velocity_override_active:
		velocity = _velocity_override
		move_and_slide()
		_tick_contact_damage(delta)
		return

	match behavior_id:
		"chase":
			_tick_chase_behavior(delta)
		"charger":
			_tick_charger_behavior(delta)
		"shooter":
			_tick_shooter_behavior(delta)
		"exploder":
			_tick_exploder_behavior(delta)
		"swarm":
			_tick_swarm_behavior(delta)
		"support":
			_tick_support_behavior(delta)
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

	var remaining_damage := amount
	var absorbed_damage := 0
	if shield_value > 0:
		absorbed_damage = mini(shield_value, remaining_damage)
		shield_value -= absorbed_damage
		remaining_damage -= absorbed_damage

	var previous_health := current_health
	if remaining_damage > 0:
		current_health = clampi(current_health - remaining_damage, 0, max_health)

	var actual_damage := absorbed_damage + previous_health - current_health
	if actual_damage > 0:
		damage_taken.emit(actual_damage, global_position)
		health_changed.emit(current_health, max_health)
		_update_health_bar()
		if absorbed_damage > 0 and remaining_damage == 0:
			_play_hit_flash(true)
		else:
			_play_hit_flash(false)

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
		target.take_damage(_get_effective_contact_damage())
		_contact_damage_cooldown = contact_damage_interval


func _tick_chase_behavior(_delta: float) -> void:
	var offset := target.global_position - global_position
	velocity = Vector2.ZERO if offset.is_zero_approx() else offset.normalized() * _get_effective_speed()


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
			velocity = _charge_direction * _get_effective_speed() * charge_speed_multiplier
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
		if distance > preferred_distance:
			velocity = direction * _get_effective_speed()
		else:
			velocity = Vector2.ZERO

	if distance <= shoot_range and _shoot_cooldown_remaining <= 0.0:
		_spawn_enemy_projectile(target.global_position)
		_shoot_cooldown_remaining = shoot_interval


func _tick_exploder_behavior(delta: float) -> void:
	var offset := target.global_position - global_position
	var distance := offset.length()
	match _explode_state:
		"ready":
			if distance <= explode_trigger_distance:
				_explode_state = "windup"
				_explode_timer = explode_windup
				velocity = Vector2.ZERO
				_set_windup_visual(true)
			else:
				_tick_chase_behavior(delta)
		"windup":
			velocity = Vector2.ZERO
			_explode_timer -= delta
			scale = Vector2.ONE * (1.0 + 0.12 * absf(sin(_explode_timer * 18.0)))
			if _explode_timer <= 0.0:
				_explode_state = "done"
				_explode_now()
		_:
			velocity = Vector2.ZERO


func _explode_now() -> void:
	if is_instance_valid(target) and target.has_method("take_damage"):
		var target_node := target as Node2D
		if target_node != null and global_position.distance_to(target_node.global_position) <= explode_radius:
			target.take_damage(explode_damage)
	die()


func _tick_swarm_behavior(_delta: float) -> void:
	var offset := target.global_position - global_position
	if offset.is_zero_approx():
		velocity = Vector2.ZERO
		return

	var distance := offset.length()
	var toward := offset.normalized()
	var direction_sign := 1.0 if orbit_direction >= 0.0 else -1.0
	var tangent := toward.orthogonal() * direction_sign
	if distance > approach_distance:
		velocity = toward * _get_effective_speed()
	elif distance > orbit_distance:
		velocity = (toward * 0.65 + tangent * orbit_strength).normalized() * _get_effective_speed()
	else:
		velocity = (toward * 0.22 + tangent * orbit_strength).normalized() * _get_effective_speed()


func _tick_support_behavior(delta: float) -> void:
	if _support_cooldown_remaining > 0.0:
		_support_cooldown_remaining = maxf(_support_cooldown_remaining - delta, 0.0)

	var offset := target.global_position - global_position
	var distance := offset.length()
	if distance > support_radius and not offset.is_zero_approx():
		velocity = offset.normalized() * _get_effective_speed()
	else:
		velocity = Vector2.ZERO

	if _support_cooldown_remaining <= 0.0:
		_apply_support_buff()
		_support_cooldown_remaining = support_interval


func _apply_support_buff() -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		if node == self or not node is Node2D or not is_instance_valid(node):
			continue
		if node.get("behavior_id") == "support" or node.get("is_miniboss") == true:
			continue
		if global_position.distance_to((node as Node2D).global_position) > support_radius:
			continue
		if node.has_method("apply_temporary_modifier"):
			node.apply_temporary_modifier("support_buff", {
				"speed_multiplier": support_speed_multiplier,
				"contact_damage_multiplier": support_damage_multiplier,
			}, support_buff_duration)


func apply_temporary_modifier(modifier_id: String, values: Dictionary, duration: float) -> void:
	_temporary_modifiers[modifier_id] = {
		"values": values.duplicate(),
		"duration": maxf(duration, 0.0),
	}
	if body_visual != null:
		body_visual.modulate = Color(1.18, 1.12, 0.75, 1.0)


func has_temporary_modifier(modifier_id: String) -> bool:
	return _temporary_modifiers.has(modifier_id)


func _tick_temporary_modifiers(delta: float) -> void:
	if _temporary_modifiers.is_empty():
		return

	var expired: Array[String] = []
	for modifier_id in _temporary_modifiers:
		var entry: Dictionary = _temporary_modifiers[modifier_id]
		entry["duration"] = float(entry["duration"]) - delta
		_temporary_modifiers[modifier_id] = entry
		if float(entry["duration"]) <= 0.0:
			expired.append(modifier_id)

	for modifier_id in expired:
		_temporary_modifiers.erase(modifier_id)

	if _temporary_modifiers.is_empty() and body_visual != null:
		body_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _get_effective_speed() -> float:
	var value := _base_speed
	for modifier_id in _temporary_modifiers:
		var values: Dictionary = _temporary_modifiers[modifier_id].get("values", {})
		value *= float(values.get("speed_multiplier", 1.0))
	return value


func _get_effective_contact_damage() -> int:
	var value := float(_base_contact_damage)
	for modifier_id in _temporary_modifiers:
		var values: Dictionary = _temporary_modifiers[modifier_id].get("values", {})
		value *= float(values.get("contact_damage_multiplier", 1.0))
	return maxi(roundi(value), 0)


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


func _play_hit_flash(shield_absorbed: bool = false) -> void:
	if _hit_flash_tween != null:
		_hit_flash_tween.kill()

	var visuals := _get_flash_visuals()
	if visuals.is_empty():
		return

	# Shield-absorbed hit: blue-white flash. Normal hit: bright white flash.
	var flash_color := Color(0.6, 0.85, 1.0, 1.0) if shield_absorbed else Color(1.0, 1.0, 1.0, 1.0)
	var start_color := Color(0.5, 0.75, 1.0, 1.0) if shield_absorbed else Color(1.0, 0.35, 0.35, 1.0)

	for visual in visuals:
		visual.modulate = flash_color

	_hit_flash_tween = create_tween()
	for visual in visuals:
		_hit_flash_tween.parallel().tween_property(visual, "modulate", flash_color, 0.0)
	for visual in visuals:
		_hit_flash_tween.parallel().tween_property(visual, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12).from(start_color)
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
