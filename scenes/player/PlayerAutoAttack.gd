extends Node

@export var attack_damage: int = 5
@export var attack_interval: float = 0.6
@export var attack_range: float = 260.0
@export var projectile_speed: float = 520.0
@export var projectile_count: int = 1
@export var projectile_spread_degrees: float = 0.0
@export var minimum_multishot_spread_degrees: float = 14.0
@export var projectile_pierce: int = 0
@export var projectile_size_multiplier: float = 1.0
@export var projectile_explosion_radius: float = 0.0
@export var projectile_explosion_damage_multiplier: float = 0.6
@export var projectile_bounce: int = 0
@export var projectile_bounce_range: float = 260.0
@export var projectile_scene: PackedScene
@export var max_projectile_count: int = 7
@export var max_projectile_bounce: int = 5
@export var max_projectile_explosion_radius: float = 180.0

var projectile_container: Node
var audio_manager: Node
var _cooldown := 0.0
var _enemies_in_range: Array[Node2D] = []
var _missing_projectile_warning_shown := false
var _attack_sequence_id: int = 0

# Primary weapon identity set by HeroApplier via set_primary_weapon().
# Defaults to empty so existing scenes with no hero selected fall back to
# the generic projectile path (_tick_solar_bolt).
var _primary_weapon_id: String = ""
var _primary_weapon_data: Dictionary = {}
var _ability_manager_ref: Node = null

@onready var attack_range_area: Area2D = get_node_or_null("AttackRangeArea")
@onready var attack_shape: CollisionShape2D = get_node_or_null("AttackRangeArea/CollisionShape2D")
@onready var owner_body: Node2D = get_parent() as Node2D

func _ready() -> void:
	if attack_range_area == null:
		push_warning("PlayerAutoAttack could not find AttackRangeArea.")
		return

	attack_range_area.body_entered.connect(_on_attack_range_area_body_entered)
	attack_range_area.body_exited.connect(_on_attack_range_area_body_exited)
	_update_attack_range_shape()


func _physics_process(delta: float) -> void:
	_sync_attack_range_area()

	if _cooldown > 0.0:
		_cooldown -= delta

	if _cooldown > 0.0:
		return

	if owner_body == null:
		return
	if owner_body.has_method("is_dead") and owner_body.is_dead():
		return

	var attacked := false
	match _primary_weapon_id:
		"shockwave_strike":
			attacked = _tick_shockwave_strike()
		"gadget_darts":
			attacked = _tick_gadget_darts()
		_:
			# "solar_bolt" and generic/fallback path
			var enemy := _find_nearest_enemy()
			if enemy != null:
				attacked = _tick_solar_bolt(enemy)

	if attacked:
		_cooldown = attack_interval


func setup_projectile_container(container: Node) -> void:
	projectile_container = container


func setup_audio_manager(new_audio_manager: Node) -> void:
	audio_manager = new_audio_manager


# Called by HeroApplier after hero stats are applied. Sets weapon identity and
# applies weapon-specific property defaults (speed, size, range, bounce).
# Upgrade hooks (attack_damage, attack_interval, attack_range, projectile_count,
# projectile_pierce, projectile_size_multiplier, projectile_explosion_radius,
# projectile_bounce, projectile_speed) remain fully effective on top of these.
func set_primary_weapon(_hero_id: String, weapon_id: String, weapon_data: Dictionary) -> void:
	_primary_weapon_id = weapon_id
	_primary_weapon_data = weapon_data

	if weapon_data.has("projectile_speed"):
		projectile_speed = float(weapon_data["projectile_speed"])
	if weapon_data.has("projectile_size_multiplier"):
		projectile_size_multiplier = float(weapon_data["projectile_size_multiplier"])
	if weapon_data.has("projectile_pierce"):
		projectile_pierce = maxi(int(weapon_data["projectile_pierce"]), 0)
	if weapon_data.has("projectile_bounce"):
		projectile_bounce = clampi(int(weapon_data["projectile_bounce"]), 0, max_projectile_bounce)
	if weapon_data.has("attack_range"):
		attack_range = float(weapon_data["attack_range"])
		_update_attack_range_shape()


func set_ability_manager_ref(manager: Node) -> void:
	_ability_manager_ref = manager


func get_primary_weapon_id() -> String:
	return _primary_weapon_id


func get_primary_weapon_display_name() -> String:
	return str(_primary_weapon_data.get("display_name", _primary_weapon_id))


# ── Per-weapon tick methods ───────────────────────────────────────────────────

# Solar Guardian: slow heavy homing bolt. Uses standard projectile path with
# the slower speed + larger size set by weapon data. Pierce upgrades apply.
func _tick_solar_bolt(enemy: Node2D) -> bool:
	return _spawn_projectiles(enemy)


# Night Tactician: fast light darts with default bounce. Prefers the
# ability manager's Tactical Mark target when it is in range.
func _tick_gadget_darts() -> bool:
	var target := _find_marked_target()
	if target == null:
		target = _find_nearest_enemy()
	if target == null:
		return false
	return _spawn_projectiles(target)


# Fury Vanguard: close-range shockwave. Damages all enemies currently in the
# (shorter) attack range area directly. No projectile is spawned.
# Projectile-specific upgrades are safely ignored here; attack_damage and
# attack_interval still apply normally.
func _tick_shockwave_strike() -> bool:
	_cleanup_invalid_enemies()
	if _enemies_in_range.is_empty():
		return false

	var hit_any := false
	for enemy in _enemies_in_range:
		if not _is_valid_enemy(enemy):
			continue
		enemy.take_damage(attack_damage)
		hit_any = true

	return hit_any


# Returns the Tactical Mark target from AbilityManager if it is valid and
# within current attack range. Returns null otherwise.
func _find_marked_target() -> Node2D:
	if _ability_manager_ref == null or not is_instance_valid(_ability_manager_ref):
		return null
	var mark_target = _ability_manager_ref.get("tactical_mark_target")
	if not mark_target is Node2D or not is_instance_valid(mark_target as Node2D):
		return null
	var target := mark_target as Node2D
	if not _is_valid_enemy(target):
		return null
	if owner_body != null:
		var dist_sq := owner_body.global_position.distance_squared_to(target.global_position)
		if dist_sq > attack_range * attack_range:
			return null
	return target


func _on_attack_range_area_body_entered(body: Node2D) -> void:
	if _is_valid_enemy(body) and not _enemies_in_range.has(body):
		_enemies_in_range.append(body)


func _on_attack_range_area_body_exited(body: Node2D) -> void:
	_enemies_in_range.erase(body)


func _find_nearest_enemy() -> Node2D:
	var nearest_enemy: Node2D
	var nearest_distance := INF
	var origin: Vector2 = owner_body.global_position

	for enemy in _enemies_in_range:
		if not _is_valid_enemy(enemy):
			continue

		var distance: float = origin.distance_squared_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy

	_cleanup_invalid_enemies()
	return nearest_enemy


func _is_valid_enemy(body: Node) -> bool:
	return (
		body is Node2D
		and is_instance_valid(body)
		and not body.is_queued_for_deletion()
		and (body.is_in_group("enemies") or body.has_method("die"))
		and body.has_method("take_damage")
	)


func _cleanup_invalid_enemies() -> void:
	_enemies_in_range = _enemies_in_range.filter(_is_valid_enemy)


func _spawn_projectiles(enemy: Node2D) -> bool:
	if projectile_scene == null or projectile_container == null:
		if not _missing_projectile_warning_shown:
			push_warning("PlayerAutoAttack is missing projectile_scene or projectile_container.")
			_missing_projectile_warning_shown = true
		return false

	var base_direction := (enemy.global_position - owner_body.global_position).normalized()
	if base_direction.is_zero_approx():
		base_direction = Vector2.RIGHT

	var spawned_any := false
	var safe_count := clampi(projectile_count, 1, max_projectile_count)
	var effective_spread := _get_effective_spread_degrees(safe_count)
	var homing_enabled := not (safe_count > 1 or effective_spread > 0.0)
	var directions := _get_projectile_directions(base_direction, safe_count, effective_spread)
	var next_attack_id := _attack_sequence_id + 1
	for index in range(directions.size()):
		var spawn_offset := _get_multishot_spawn_offset(base_direction, index, safe_count)
		if _spawn_projectile(enemy, directions[index], spawn_offset, homing_enabled, next_attack_id, index):
			spawned_any = true

	if spawned_any:
		_attack_sequence_id = next_attack_id

	return spawned_any


func _spawn_projectile(enemy: Node2D, direction: Vector2, spawn_offset: Vector2 = Vector2.ZERO, homing_enabled: bool = true, attack_id: int = -1, projectile_index: int = 0) -> bool:
	var projectile_node := projectile_scene.instantiate()
	if not projectile_node is Node2D:
		push_warning("PlayerAutoAttack projectile_scene root must be Node2D.")
		projectile_node.queue_free()
		return false

	var projectile := projectile_node as Node2D
	var spawn_position := owner_body.global_position + direction * 24.0 + spawn_offset

	projectile_container.add_child(projectile)
	if "speed" in projectile:
		projectile.speed = projectile_speed
	if projectile.has_method("setup_audio_manager"):
		projectile.setup_audio_manager(audio_manager)

	if projectile.has_method("setup"):
		projectile.setup(spawn_position, enemy, attack_damage, {
			"speed": projectile_speed,
			"direction": direction,
			"pierce": projectile_pierce,
			"size_multiplier": projectile_size_multiplier,
			"explosion_radius": minf(projectile_explosion_radius, max_projectile_explosion_radius),
			"explosion_damage_multiplier": projectile_explosion_damage_multiplier,
			"bounce": mini(projectile_bounce, max_projectile_bounce),
			"bounce_range": projectile_bounce_range,
			"homing_enabled": homing_enabled,
			"attack_id": attack_id,
			"projectile_index": projectile_index,
		})
	else:
		push_warning("Player projectile does not implement setup(origin, target, damage).")
		projectile.global_position = spawn_position

	return true


func _get_projectile_directions(base_direction: Vector2, count: int, effective_spread_degrees: float = -1.0) -> Array[Vector2]:
	if count <= 1:
		return [base_direction]

	var directions: Array[Vector2] = []
	var spread_degrees := effective_spread_degrees if effective_spread_degrees >= 0.0 else projectile_spread_degrees
	var spread_radians := deg_to_rad(spread_degrees)
	var start_angle := -spread_radians * 0.5
	var step := spread_radians / float(count - 1) if count > 1 else 0.0
	for index in range(count):
		directions.append(base_direction.rotated(start_angle + step * float(index)).normalized())

	return directions


func _get_effective_spread_degrees(count: int) -> float:
	if count <= 1:
		return projectile_spread_degrees
	if projectile_spread_degrees > 0.0:
		return projectile_spread_degrees

	return minimum_multishot_spread_degrees * float(count - 1)


func _get_multishot_spawn_offset(base_direction: Vector2, index: int, count: int) -> Vector2:
	if count <= 1:
		return Vector2.ZERO

	var perpendicular := base_direction.orthogonal().normalized()
	var spacing := 10.0
	var center := (float(count) - 1.0) * 0.5
	return perpendicular * ((float(index) - center) * spacing)


func get_weapon_stats() -> Dictionary:
	return {
		"attack_damage": attack_damage,
		"attack_interval": attack_interval,
		"attack_range": attack_range,
		"projectile_speed": projectile_speed,
		"projectile_count": projectile_count,
		"projectile_spread_degrees": projectile_spread_degrees,
		"projectile_pierce": projectile_pierce,
		"projectile_size_multiplier": projectile_size_multiplier,
		"projectile_explosion_radius": projectile_explosion_radius,
		"projectile_bounce": projectile_bounce,
		"max_projectile_count": max_projectile_count,
	}


func _update_attack_range_shape() -> void:
	if attack_shape == null:
		push_warning("PlayerAutoAttack could not find attack range CollisionShape2D.")
		return

	var circle := attack_shape.shape as CircleShape2D
	if circle == null:
		push_warning("PlayerAutoAttack attack range shape should be CircleShape2D.")
		return

	circle.radius = attack_range


func refresh_attack_range() -> void:
	_update_attack_range_shape()


func _sync_attack_range_area() -> void:
	if owner_body != null and attack_range_area != null:
		attack_range_area.global_position = owner_body.global_position
