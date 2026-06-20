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
@export var solar_ray_width: float = 40.0
@export var splash_melee_radius: float = 85.0
@export var splash_melee_knockback: float = 0.0

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
		"solar_ray":
			attacked = _tick_solar_ray()
		"homing_rockets":
			attacked = _tick_homing_rockets()
		"splash_melee":
			attacked = _tick_splash_melee()
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


# Solar Guardian (solar_ray weapon): beam autoattack. Finds the nearest enemy
# to establish aim direction, then damages all enemies within a narrow corridor
# along that direction. No projectile spawned — direct line hit detection.
# attack_damage, attack_interval, attack_range, and solar_ray_width all apply.
# Empowered x2 multiplier is read from the ability manager if available.
func _tick_solar_ray() -> bool:
	_cleanup_invalid_enemies()
	if _enemies_in_range.is_empty():
		return false
	var nearest := _find_nearest_enemy()
	if nearest == null:
		return false

	var origin := owner_body.global_position
	var direction := (nearest.global_position - origin).normalized()
	if direction.is_zero_approx():
		direction = Vector2.RIGHT

	var ray_damage := _get_solar_ray_damage()
	var half_width := solar_ray_width * 0.5
	var perp_axis := direction.orthogonal()
	var hit_any := false

	for target in _enemies_in_range:
		if not _is_valid_enemy(target):
			continue
		var to_target: Vector2 = (target as Node2D).global_position - origin
		var proj: float = to_target.dot(direction)
		if proj < 0.0 or proj > attack_range:
			continue
		if absf(to_target.dot(perp_axis)) <= half_width:
			target.take_damage(ray_damage)
			hit_any = true

	_spawn_solar_ray_visual(origin, direction)
	return hit_any


func _get_solar_ray_damage() -> int:
	var multiplier := 1.0
	if _ability_manager_ref != null and is_instance_valid(_ability_manager_ref):
		if _ability_manager_ref.has_method("get_solar_damage_multiplier"):
			multiplier = float(_ability_manager_ref.get_solar_damage_multiplier())
	return maxi(roundi(float(attack_damage) * multiplier), 1)


func _spawn_solar_ray_visual(origin: Vector2, direction: Vector2) -> void:
	if owner_body == null:
		return
	var parent: Node = null
	if projectile_container != null and is_instance_valid(projectile_container):
		parent = projectile_container
	elif owner_body.get_parent() != null:
		parent = owner_body.get_parent()
	if parent == null:
		return

	var line := Line2D.new()
	line.width = maxf(solar_ray_width * 0.28, 4.0)
	line.default_color = Color(1.0, 0.18, 0.0, 0.88)
	line.add_point(origin)
	line.add_point(origin + direction * attack_range)
	parent.add_child(line)
	var timer := line.get_tree().create_timer(0.10)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(line):
			line.queue_free()
	)


# Fury Vanguard: splash melee autoattack. Damages all enemies within
# splash_melee_radius of the player with a Rage-scaled damage multiplier.
# No projectile — direct hit detection. Reports hits back to AbilityManager
# so rage builds from autoattack damage dealt.
func _tick_splash_melee() -> bool:
	_cleanup_invalid_enemies()
	if _enemies_in_range.is_empty():
		return false
	var origin := owner_body.global_position
	var multiplier := _get_splash_melee_rage_multiplier()
	var hit_damage := maxi(roundi(float(attack_damage) * multiplier), 1)
	var hit_any := false
	for target in _enemies_in_range:
		if not _is_valid_enemy(target):
			continue
		var target_node := target as Node2D
		if origin.distance_to(target_node.global_position) > splash_melee_radius:
			continue
		target.take_damage(hit_damage)
		hit_any = true
		if splash_melee_knockback > 0.0 and target.has_method("apply_knockback"):
			var away := (target_node.global_position - origin).normalized()
			target.apply_knockback(away, splash_melee_knockback)
	if hit_any:
		_spawn_splash_melee_visual(origin)
		if _ability_manager_ref != null and is_instance_valid(_ability_manager_ref):
			if _ability_manager_ref.has_method("add_rage"):
				_ability_manager_ref.add_rage(_ability_manager_ref.rage_per_hit if "rage_per_hit" in _ability_manager_ref else 6.0)
	return hit_any


func _get_splash_melee_rage_multiplier() -> float:
	if _ability_manager_ref != null and is_instance_valid(_ability_manager_ref):
		if _ability_manager_ref.has_method("get_rage_damage_multiplier"):
			return float(_ability_manager_ref.get_rage_damage_multiplier())
	return 1.0


func _spawn_splash_melee_visual(origin: Vector2) -> void:
	var parent: Node = null
	if projectile_container != null and is_instance_valid(projectile_container):
		parent = projectile_container
	elif owner_body != null and owner_body.get_parent() != null:
		parent = owner_body.get_parent()
	if parent == null:
		return
	var ring := Line2D.new()
	ring.width = 4.0
	ring.default_color = Color(0.82, 0.22, 0.12, 0.72)
	ring.closed = true
	var n := 20
	for i in range(n):
		var a := TAU * float(i) / float(n)
		ring.add_point(origin + Vector2(cos(a), sin(a)) * splash_melee_radius)
	parent.add_child(ring)
	var timer := ring.get_tree().create_timer(0.10)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(ring):
			ring.queue_free()
	)


# Night Tactician (legacy gadget_darts path — kept for safety but not active).
func _tick_gadget_darts() -> bool:
	var target := _find_marked_target()
	if target == null:
		target = _find_nearest_enemy()
	if target == null:
		return false
	return _spawn_projectiles(target)


# Night Tactician: homing rockets. Each rocket homes to a target independently.
# Multiple rockets prefer different enemies; all target the same enemy when only
# one is in range. Pierce is always 0; bounce is always 0. Mark multiplier is
# applied per-rocket based on the ability manager's Tactical Mark system.
func _tick_homing_rockets() -> bool:
	_cleanup_invalid_enemies()
	if _enemies_in_range.is_empty():
		return false
	if projectile_scene == null or projectile_container == null:
		if not _missing_projectile_warning_shown:
			push_warning("PlayerAutoAttack (homing_rockets): missing projectile_scene or projectile_container.")
			_missing_projectile_warning_shown = true
		return false

	var valid_enemies: Array[Node2D] = []
	for body in _enemies_in_range:
		if _is_valid_enemy(body):
			valid_enemies.append(body as Node2D)
	if valid_enemies.is_empty():
		return false

	var safe_count := clampi(projectile_count, 1, max_projectile_count)
	var next_attack_id := _attack_sequence_id + 1
	var spawned_any := false

	for i in range(safe_count):
		var rocket_target := valid_enemies[i % valid_enemies.size()]
		var base_damage := attack_damage
		if _ability_manager_ref != null and is_instance_valid(_ability_manager_ref):
			if _ability_manager_ref.has_method("get_tactical_mark_multiplier"):
				var mark_mult: float = float(_ability_manager_ref.get_tactical_mark_multiplier(rocket_target))
				if mark_mult > 1.0:
					base_damage = maxi(roundi(float(base_damage) * mark_mult), 1)
		var direction := (rocket_target.global_position - owner_body.global_position).normalized()
		if direction.is_zero_approx():
			direction = Vector2.RIGHT
		if _spawn_homing_rocket(rocket_target, direction, base_damage, next_attack_id, i):
			spawned_any = true

	if spawned_any:
		_attack_sequence_id = next_attack_id
	return spawned_any


func _spawn_homing_rocket(target: Node2D, direction: Vector2, rocket_damage: int, attack_id: int, index: int) -> bool:
	var projectile_node := projectile_scene.instantiate()
	if not projectile_node is Node2D:
		projectile_node.queue_free()
		return false
	var projectile := projectile_node as Node2D
	projectile_container.add_child(projectile)
	if "speed" in projectile:
		projectile.speed = projectile_speed
	if projectile.has_method("setup_audio_manager"):
		projectile.setup_audio_manager(audio_manager)
	var spawn_position := owner_body.global_position + direction * 24.0
	if projectile.has_method("setup"):
		projectile.setup(spawn_position, target, rocket_damage, {
			"speed": projectile_speed,
			"direction": direction,
			"pierce": 0,
			"size_multiplier": projectile_size_multiplier,
			"explosion_radius": minf(projectile_explosion_radius, max_projectile_explosion_radius),
			"explosion_damage_multiplier": projectile_explosion_damage_multiplier,
			"bounce": 0,
			"bounce_range": 0.0,
			"homing_enabled": true,
			"attack_id": attack_id,
			"projectile_index": index,
		})
	else:
		projectile.global_position = spawn_position
	return true


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
