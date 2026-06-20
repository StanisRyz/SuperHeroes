extends Node

const SOLAR_RAY_INTERVAL_MIN := 0.20
const STATUS_SENTINEL := Vector2(100000000.0, 100000000.0)

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
@export var rocket_priority_targeting_enabled: bool = false
@export var projectile_bounce: int = 0
@export var projectile_bounce_range: float = 260.0
@export var projectile_scene: PackedScene
@export var max_projectile_count: int = 7
@export var max_projectile_bounce: int = 5
@export var max_projectile_explosion_radius: float = 180.0
@export var solar_ray_width: float = 40.0
@export var solar_ray_burn_damage: int = 0
@export var solar_ray_tick_rate_bonus: float = 0.0
@export var solar_ray_empowered_bonus: float = 0.0
@export var solar_ray_lingering_heat_enabled: bool = false
@export var solar_ray_focus_bonus: float = 0.0
@export var solar_ray_execution_threshold: float = 0.0
@export var solar_ray_sky_lance_enabled: bool = false
@export var solar_ray_sky_lance_range_bonus: float = 360.0
@export var solar_ray_sky_lance_width_bonus: float = 52.0
@export var solar_ray_burning_judgment_enabled: bool = false
@export var solar_ray_burning_judgment_damage: int = 8
@export var solar_ray_glacier_front_enabled: bool = false
@export var solar_ray_line_pulse_enabled: bool = false
@export var splash_melee_radius: float = 85.0
@export var splash_melee_knockback: float = 0.0
@export var splash_melee_shockwave_enabled: bool = false
@export var splash_melee_lifesteal: float = 0.0
@export var splash_melee_combo_enabled: bool = false
@export var splash_melee_combo_bonus: float = 0.0
@export var splash_melee_execute_threshold: float = 0.0
@export var rocket_tactical_cover_enabled: bool = false
@export var rocket_support_count_bonus: int = 2
@export var rocket_choking_zone_enabled: bool = false
@export var rocket_impact_slow_enabled: bool = false
@export var rocket_cluster_minefield_enabled: bool = false
@export var rocket_cluster_explosion_count: int = 4
@export var rocket_cluster_explosion_radius: float = 96.0
@export var splash_melee_earthsplitter_enabled: bool = false
@export var splash_melee_earthsplitter_range: float = 260.0
@export var splash_melee_crushing_storm_enabled: bool = false
@export var splash_melee_crushing_storm_rage_bonus: float = 1.35
@export var splash_melee_seismic_fan_enabled: bool = false
@export var splash_melee_seismic_fan_width: float = 82.0

var projectile_container: Node
var audio_manager: Node
var feedback_manager: Node
var _cooldown := 0.0
var _enemies_in_range: Array[Node2D] = []
var _missing_projectile_warning_shown := false
var _attack_sequence_id: int = 0
var _splash_combo_stacks: int = 0
var _splash_combo_decay_timer: float = 0.0
var _selected_attack_evolutions: Dictionary = {}

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
	if splash_melee_combo_enabled and _splash_combo_decay_timer > 0.0:
		_splash_combo_decay_timer -= delta
		if _splash_combo_decay_timer <= 0.0:
			_splash_combo_stacks = 0

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
		_cooldown = _get_attack_cooldown()


func setup_projectile_container(container: Node) -> void:
	projectile_container = container


func setup_audio_manager(new_audio_manager: Node) -> void:
	audio_manager = new_audio_manager


func setup_feedback_manager(new_feedback_manager: Node) -> void:
	feedback_manager = new_feedback_manager


# Called by HeroApplier after hero stats are applied. Sets weapon identity and
# applies weapon-specific property defaults (speed, size, range, bounce).
# Upgrade hooks (attack_damage, attack_interval, attack_range, projectile_count,
# projectile_pierce, projectile_size_multiplier, projectile_explosion_radius,
# projectile_bounce, projectile_speed) remain fully effective on top of these.
func set_primary_weapon(_hero_id: String, weapon_id: String, weapon_data: Dictionary) -> void:
	_primary_weapon_id = weapon_id
	_primary_weapon_data = weapon_data
	_reset_attack_evolution_state()

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


func apply_attack_evolution(evolution_id: String, target_id: String) -> bool:
	if has_attack_evolution(evolution_id):
		return false
	match evolution_id:
		"solar_beam_sky_lance":
			if target_id != "solar_ray" or _primary_weapon_id != "solar_ray":
				return false
			solar_ray_sky_lance_enabled = true
			attack_range += solar_ray_sky_lance_range_bonus
			solar_ray_width += solar_ray_sky_lance_width_bonus
			_update_attack_range_shape()
			_mark_attack_evolution(evolution_id, target_id, "Sky Lance")
			_show_status("SKY LANCE")
		"solar_beam_burning_judgment":
			if target_id != "solar_ray" or _primary_weapon_id != "solar_ray":
				return false
			solar_ray_burning_judgment_enabled = true
			_mark_attack_evolution(evolution_id, target_id, "Burning Judgment")
			_show_status("BURNING JUDGMENT")
		"frost_breath_glacier_front":
			if target_id != "solar_ray" or _primary_weapon_id != "solar_ray":
				return false
			solar_ray_glacier_front_enabled = true
			solar_ray_line_pulse_enabled = true
			_mark_attack_evolution(evolution_id, target_id, "Solar Glacier Front")
			_show_status("SOLAR GLACIER FRONT")
		"smoke_screen_tactical_cover":
			if target_id != "homing_rockets" or _primary_weapon_id != "homing_rockets":
				return false
			rocket_tactical_cover_enabled = true
			_mark_attack_evolution(evolution_id, target_id, "Tactical Cover")
			_show_status("TACTICAL COVER")
		"smoke_screen_choking_zone":
			if target_id != "homing_rockets" or _primary_weapon_id != "homing_rockets":
				return false
			rocket_choking_zone_enabled = true
			rocket_impact_slow_enabled = true
			_mark_attack_evolution(evolution_id, target_id, "Choking Zone")
			_show_status("CHOKING ZONE")
		"trap_cluster_minefield":
			if target_id != "homing_rockets" or _primary_weapon_id != "homing_rockets":
				return false
			rocket_cluster_minefield_enabled = true
			_mark_attack_evolution(evolution_id, target_id, "Cluster Minefield")
			_show_status("CLUSTER MINEFIELD")
		"rage_wave_earthsplitter":
			if target_id != "splash_melee" or _primary_weapon_id != "splash_melee":
				return false
			splash_melee_earthsplitter_enabled = true
			_mark_attack_evolution(evolution_id, target_id, "Earthsplitter")
			_show_status("EARTHSPLITTER")
		"rage_wave_crushing_storm":
			if target_id != "splash_melee" or _primary_weapon_id != "splash_melee":
				return false
			splash_melee_crushing_storm_enabled = true
			_mark_attack_evolution(evolution_id, target_id, "Crushing Storm")
			_show_status("CRUSHING STORM")
		"mighty_clap_seismic_fan":
			if target_id != "splash_melee" or _primary_weapon_id != "splash_melee":
				return false
			splash_melee_seismic_fan_enabled = true
			_mark_attack_evolution(evolution_id, target_id, "Seismic Fan")
			_show_status("SEISMIC FAN")
		_:
			return false
	return true


func has_attack_evolution(evolution_id: String) -> bool:
	return _selected_attack_evolutions.has(evolution_id)


func debug_get_attack_evolutions() -> Dictionary:
	return _selected_attack_evolutions.duplicate(true)


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
			target.take_damage(_get_solar_ray_damage_for_target(target, ray_damage, target == nearest))
			if solar_ray_burn_damage > 0:
				target.take_damage(solar_ray_burn_damage)
			if solar_ray_burning_judgment_enabled:
				_apply_burning_judgment(target)
			if solar_ray_lingering_heat_enabled:
				_schedule_solar_ray_lingering_heat(target)
			hit_any = true

	_spawn_solar_ray_visual(origin, direction)
	if solar_ray_line_pulse_enabled:
		_schedule_solar_ray_line_pulse(origin, direction, ray_damage)
	if hit_any:
		if solar_ray_sky_lance_enabled:
			_show_status("SKY LANCE", origin + direction * minf(attack_range, 160.0) + Vector2.UP * 24.0)
		elif solar_ray_burning_judgment_enabled:
			_show_status("BURNING JUDGMENT", origin + direction * minf(attack_range, 160.0) + Vector2.UP * 24.0)
		elif solar_ray_glacier_front_enabled:
			_show_status("SOLAR PULSE", origin + direction * minf(attack_range, 160.0) + Vector2.UP * 24.0)
	return hit_any


func _get_solar_ray_damage() -> int:
	var multiplier := 1.0
	if _ability_manager_ref != null and is_instance_valid(_ability_manager_ref):
		if _ability_manager_ref.has_method("get_solar_damage_multiplier"):
			multiplier = float(_ability_manager_ref.get_solar_damage_multiplier())
		if solar_ray_empowered_bonus > 0.0 and _ability_manager_ref.has_method("is_solar_empowered") and _ability_manager_ref.is_solar_empowered():
			multiplier += solar_ray_empowered_bonus
	return maxi(roundi(float(attack_damage) * multiplier), 1)


func _get_solar_ray_damage_for_target(target: Node2D, base_damage: int, is_primary_target: bool) -> int:
	var multiplier := 1.0
	if is_primary_target and solar_ray_focus_bonus > 0.0:
		multiplier += solar_ray_focus_bonus
	if solar_ray_execution_threshold > 0.0 and target != null:
		var max_health = target.get("max_health")
		var current_health = target.get("current_health")
		if max_health != null and current_health != null and int(max_health) > 0:
			var health_ratio := float(current_health) / float(max_health)
			if health_ratio <= solar_ray_execution_threshold:
				multiplier += 0.35
	return maxi(roundi(float(base_damage) * multiplier), 1)


func _schedule_solar_ray_lingering_heat(target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		return
	var damage := maxi(solar_ray_burn_damage, 1)
	var timer := get_tree().create_timer(0.22)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(target) and target.has_method("take_damage"):
			target.take_damage(damage)
	)


func _apply_burning_judgment(target: Node2D) -> void:
	if target == null or not is_instance_valid(target) or not target.has_method("take_damage"):
		return
	var damage := solar_ray_burning_judgment_damage
	if _ability_manager_ref != null and is_instance_valid(_ability_manager_ref):
		if _ability_manager_ref.has_method("is_solar_empowered") and _ability_manager_ref.is_solar_empowered():
			damage = maxi(roundi(float(damage) * 2.0), 1)
	target.take_damage(damage)
	_schedule_delayed_enemy_damage(target, maxi(roundi(float(damage) * 0.75), 1), 0.18)
	_schedule_delayed_enemy_damage(target, maxi(roundi(float(damage) * 0.55), 1), 0.38)


func _schedule_delayed_enemy_damage(target: Node2D, damage: int, delay: float) -> void:
	var timer := get_tree().create_timer(delay)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(target) and target.has_method("take_damage"):
			target.take_damage(damage)
	)


func _schedule_solar_ray_line_pulse(origin: Vector2, direction: Vector2, base_damage: int) -> void:
	var pulse_range := attack_range * 0.92
	var pulse_width := solar_ray_width * 1.65
	var pulse_damage := maxi(roundi(float(base_damage) * 0.55), 1)
	var timer := get_tree().create_timer(0.20)
	timer.timeout.connect(func() -> void:
		if not is_instance_valid(self):
			return
		_damage_enemies_in_line(origin, direction, pulse_damage, pulse_range, pulse_width)
		_spawn_beam_visual(origin, direction, pulse_range, pulse_width, Color(1.0, 0.78, 0.20, 0.72), 0.24)
	)


func _get_attack_cooldown() -> float:
	if _primary_weapon_id == "solar_ray" and solar_ray_tick_rate_bonus > 0.0:
		return maxf(SOLAR_RAY_INTERVAL_MIN, attack_interval - solar_ray_tick_rate_bonus)
	return attack_interval


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
	line.width = maxf(solar_ray_width * (0.42 if solar_ray_sky_lance_enabled else 0.28), 4.0)
	line.default_color = Color(1.0, 0.05, 0.0, 0.92) if solar_ray_sky_lance_enabled else Color(1.0, 0.18, 0.0, 0.88)
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
	var facing := _get_forward_direction()
	var multiplier := _get_splash_melee_rage_multiplier()
	if splash_melee_crushing_storm_enabled:
		multiplier += _get_rage_ratio() * splash_melee_crushing_storm_rage_bonus
	var combo_multiplier := 1.0
	if splash_melee_combo_enabled and _splash_combo_stacks > 0:
		combo_multiplier = 1.0 + float(_splash_combo_stacks) * splash_melee_combo_bonus
	var hit_damage := maxi(roundi(float(attack_damage) * multiplier * combo_multiplier), 1)
	var hit_any := false
	var hit_count := 0
	for target in _enemies_in_range:
		if not _is_valid_enemy(target):
			continue
		var target_node := target as Node2D
		if origin.distance_to(target_node.global_position) > splash_melee_radius:
			continue
		var target_damage := hit_damage
		if splash_melee_execute_threshold > 0.0:
			var max_hp = target.get("max_health")
			var cur_hp = target.get("current_health")
			if max_hp != null and cur_hp != null and int(max_hp) > 0:
				if float(cur_hp) / float(max_hp) <= splash_melee_execute_threshold:
					target_damage = maxi(roundi(float(target_damage) * 1.45), 1)
		target.take_damage(target_damage)
		hit_any = true
		hit_count += 1
		if splash_melee_knockback > 0.0 and target.has_method("apply_knockback"):
			var away := (target_node.global_position - origin).normalized()
			target.apply_knockback(away, splash_melee_knockback)
	if hit_any:
		_spawn_splash_melee_visual(origin)
		if _ability_manager_ref != null and is_instance_valid(_ability_manager_ref):
			if _ability_manager_ref.has_method("add_rage"):
				_ability_manager_ref.add_rage(_ability_manager_ref.rage_per_hit if "rage_per_hit" in _ability_manager_ref else 6.0)
		if splash_melee_lifesteal > 0.0:
			_apply_splash_lifesteal(hit_count)
		if splash_melee_combo_enabled:
			_splash_combo_stacks = mini(_splash_combo_stacks + 1, 5)
			_splash_combo_decay_timer = 3.0
		if splash_melee_shockwave_enabled:
			_schedule_splash_shockwave(origin)
		if splash_melee_earthsplitter_enabled:
			_apply_earthsplitter(origin, facing, hit_damage)
		if splash_melee_crushing_storm_enabled:
			_apply_crushing_storm(origin, hit_damage)
		if splash_melee_seismic_fan_enabled:
			_apply_seismic_fan(origin, facing, hit_damage)
	return hit_any


func _get_splash_melee_rage_multiplier() -> float:
	if _ability_manager_ref != null and is_instance_valid(_ability_manager_ref):
		if _ability_manager_ref.has_method("get_rage_damage_multiplier"):
			return float(_ability_manager_ref.get_rage_damage_multiplier())
	return 1.0


func _get_rage_ratio() -> float:
	if _ability_manager_ref != null and is_instance_valid(_ability_manager_ref):
		if _ability_manager_ref.has_method("get_rage_state"):
			var state: Dictionary = _ability_manager_ref.get_rage_state()
			return clampf(float(state.get("rage_ratio", 0.0)), 0.0, 1.0)
	return 0.0


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


func _apply_splash_lifesteal(hit_count: int) -> void:
	if owner_body == null or hit_count <= 0:
		return
	var heal_amount := int(splash_melee_lifesteal * float(hit_count))
	if heal_amount > 0 and owner_body.has_method("heal"):
		owner_body.heal(heal_amount)


func _schedule_splash_shockwave(origin: Vector2) -> void:
	var shockwave_radius := splash_melee_radius * 1.5
	get_tree().create_timer(0.18).timeout.connect(func() -> void:
		if not is_instance_valid(self) or owner_body == null:
			return
		for target in _enemies_in_range.duplicate():
			if not _is_valid_enemy(target):
				continue
			var target_node := target as Node2D
			if origin.distance_to(target_node.global_position) > shockwave_radius:
				continue
			var shockwave_damage := maxi(roundi(float(attack_damage) * 0.5), 1)
			target.take_damage(shockwave_damage)
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

	if rocket_priority_targeting_enabled and _ability_manager_ref != null and is_instance_valid(_ability_manager_ref):
		if _ability_manager_ref.has_method("get_tactical_mark_multiplier"):
			var marked: Array[Node2D] = []
			var unmarked: Array[Node2D] = []
			for e in valid_enemies:
				if float(_ability_manager_ref.get_tactical_mark_multiplier(e)) > 1.0:
					marked.append(e)
				else:
					unmarked.append(e)
			valid_enemies = marked + unmarked

	var support_bonus := rocket_support_count_bonus if rocket_tactical_cover_enabled else 0
	var safe_count := clampi(projectile_count + support_bonus, 1, max_projectile_count + support_bonus)
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
		if rocket_tactical_cover_enabled:
			_show_status("TACTICAL COVER", owner_body.global_position + Vector2.UP * 42.0)
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
			"hit_callback": Callable(self, "_on_homing_rocket_hit") if _has_rocket_impact_evolution() else Callable(),
		})
	else:
		projectile.global_position = spawn_position
	return true


func _on_homing_rocket_hit(enemy: Node2D, world_position: Vector2, rocket_damage: int) -> void:
	if rocket_choking_zone_enabled:
		_apply_rocket_choking_zone(world_position)
	if rocket_cluster_minefield_enabled:
		_apply_rocket_cluster_minefield(world_position, rocket_damage)
	if rocket_tactical_cover_enabled and enemy != null and is_instance_valid(enemy):
		_spawn_ring_visual(world_position, 54.0, Color(0.35, 0.72, 1.0, 0.82), 0.18, 3.0)


func _has_rocket_impact_evolution() -> bool:
	return rocket_choking_zone_enabled or rocket_cluster_minefield_enabled or rocket_tactical_cover_enabled


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


func _apply_earthsplitter(origin: Vector2, direction: Vector2, base_damage: int) -> void:
	var damage := maxi(roundi(float(base_damage) * 0.75), 1)
	var width := splash_melee_seismic_fan_width * 0.65
	var hits := _damage_enemies_in_line(origin, direction, damage, splash_melee_earthsplitter_range, width)
	_spawn_beam_visual(origin, direction, splash_melee_earthsplitter_range, width, Color(1.0, 0.46, 0.12, 0.70), 0.22)
	if hits > 0:
		_show_status("EARTHSPLITTER", origin + direction * 120.0 + Vector2.UP * 22.0)


func _apply_crushing_storm(origin: Vector2, base_damage: int) -> void:
	var ratio := _get_rage_ratio()
	var radius := splash_melee_radius * lerpf(1.55, 2.45, ratio)
	var damage := maxi(roundi(float(base_damage) * lerpf(0.55, 1.15, ratio)), 1)
	var hits := _damage_enemies_in_radius(origin, radius, damage)
	_apply_modifier_in_radius(origin, radius, "crushing_storm_pressure", {"speed_multiplier": lerpf(0.62, 0.28, ratio)}, 1.25 + ratio)
	_spawn_ring_visual(origin, radius, Color(0.95, 0.28, 0.08, 0.78), 0.24, 5.0)
	if hits > 0:
		_show_status("CRUSHING STORM", origin + Vector2.UP * 52.0)


func _apply_seismic_fan(origin: Vector2, direction: Vector2, base_damage: int) -> void:
	var range_dist := splash_melee_radius + 175.0
	var half_angle := deg_to_rad(34.0)
	var damage := maxi(roundi(float(base_damage) * 0.85), 1)
	var hits := 0
	for node in get_tree().get_nodes_in_group("enemies"):
		if not _is_valid_enemy(node):
			continue
		var target := node as Node2D
		var to_target := target.global_position - origin
		if to_target.length() > range_dist:
			continue
		var angle := 0.0
		if not to_target.is_zero_approx():
			angle = absf(direction.angle_to(to_target.normalized()))
		if angle <= half_angle:
			node.take_damage(damage)
			hits += 1
	_spawn_fan_visual(origin, direction, range_dist, splash_melee_seismic_fan_width)
	if hits > 0:
		_show_status("SEISMIC FAN", origin + direction * 110.0 + Vector2.UP * 24.0)


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


func _reset_attack_evolution_state() -> void:
	_selected_attack_evolutions.clear()
	solar_ray_sky_lance_enabled = false
	solar_ray_burning_judgment_enabled = false
	solar_ray_glacier_front_enabled = false
	solar_ray_line_pulse_enabled = false
	rocket_tactical_cover_enabled = false
	rocket_choking_zone_enabled = false
	rocket_impact_slow_enabled = false
	rocket_cluster_minefield_enabled = false
	splash_melee_earthsplitter_enabled = false
	splash_melee_crushing_storm_enabled = false
	splash_melee_seismic_fan_enabled = false


func _mark_attack_evolution(evolution_id: String, target_id: String, title: String) -> void:
	_selected_attack_evolutions[evolution_id] = {
		"target_id": target_id,
		"title": title,
	}


func _get_forward_direction() -> Vector2:
	var nearest := _find_nearest_enemy()
	if nearest != null and owner_body != null:
		var to_target := nearest.global_position - owner_body.global_position
		if not to_target.is_zero_approx():
			return to_target.normalized()
	return Vector2.RIGHT


func _damage_enemies_in_line(origin: Vector2, direction: Vector2, damage: int, range_dist: float, width: float) -> int:
	var half_width := width * 0.5
	var perp_axis := direction.orthogonal()
	var hits := 0
	for node in get_tree().get_nodes_in_group("enemies"):
		if not _is_valid_enemy(node):
			continue
		var target := node as Node2D
		var to_target: Vector2 = target.global_position - origin
		var proj := to_target.dot(direction)
		if proj < 0.0 or proj > range_dist:
			continue
		if absf(to_target.dot(perp_axis)) <= half_width:
			node.take_damage(damage)
			hits += 1
	return hits


func _damage_enemies_in_radius(origin: Vector2, radius: float, damage: int) -> int:
	var hits := 0
	var radius_sq := radius * radius
	for node in get_tree().get_nodes_in_group("enemies"):
		if not _is_valid_enemy(node):
			continue
		var enemy := node as Node2D
		if origin.distance_squared_to(enemy.global_position) <= radius_sq:
			enemy.take_damage(damage)
			hits += 1
	return hits


func _apply_modifier_in_radius(origin: Vector2, radius: float, modifier_id: String, values: Dictionary, duration: float) -> void:
	var radius_sq := radius * radius
	for node in get_tree().get_nodes_in_group("enemies"):
		if not _is_valid_enemy(node) or not node.has_method("apply_temporary_modifier"):
			continue
		var enemy := node as Node2D
		if origin.distance_squared_to(enemy.global_position) <= radius_sq:
			node.apply_temporary_modifier(modifier_id, values, duration)


func _apply_rocket_choking_zone(world_position: Vector2) -> void:
	var radius := 128.0
	_apply_modifier_in_radius(world_position, radius, "rocket_choking_zone", {"speed_multiplier": 0.42}, 1.65)
	for node in get_tree().get_nodes_in_group("enemies"):
		if not _is_valid_enemy(node):
			continue
		var enemy := node as Node2D
		if world_position.distance_to(enemy.global_position) > radius:
			continue
		if _ability_manager_ref != null and is_instance_valid(_ability_manager_ref) and _ability_manager_ref.has_method("apply_tactical_mark"):
			_ability_manager_ref.apply_tactical_mark(enemy)
	_spawn_ring_visual(world_position, radius, Color(0.48, 0.58, 0.66, 0.62), 0.28, 4.0)
	_show_status("CHOKING ZONE", world_position + Vector2.UP * 28.0)


func _apply_rocket_cluster_minefield(world_position: Vector2, rocket_damage: int) -> void:
	var count := clampi(rocket_cluster_explosion_count, 1, 6)
	var damage := maxi(roundi(float(rocket_damage) * 0.45), 1)
	for index in range(count):
		var angle := TAU * float(index) / float(count)
		var center := world_position + Vector2(cos(angle), sin(angle)) * (rocket_cluster_explosion_radius * 0.42)
		_damage_enemies_in_radius(center, rocket_cluster_explosion_radius, damage)
		_spawn_ring_visual(center, rocket_cluster_explosion_radius, Color(1.0, 0.48, 0.10, 0.72), 0.22, 3.0)
	_show_status("CLUSTER MINEFIELD", world_position + Vector2.UP * 28.0)


func _spawn_ring_visual(world_position: Vector2, radius: float, color: Color, duration: float, width: float) -> void:
	var parent := _get_feedback_parent()
	if parent == null:
		return
	var line := Line2D.new()
	line.width = width
	line.default_color = color
	line.z_index = 30
	var segments := 32
	for i in range(segments + 1):
		var angle := TAU * float(i) / float(segments)
		line.add_point(world_position + Vector2(cos(angle), sin(angle)) * radius)
	parent.add_child(line)
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, duration)
	tween.finished.connect(line.queue_free)


func _spawn_beam_visual(origin: Vector2, direction: Vector2, range_dist: float, width: float, color: Color, duration: float) -> void:
	var parent := _get_feedback_parent()
	if parent == null:
		return
	var line := Line2D.new()
	line.width = width
	line.default_color = color
	line.z_index = 30
	line.add_point(origin)
	line.add_point(origin + direction * range_dist)
	parent.add_child(line)
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, duration)
	tween.finished.connect(line.queue_free)


func _spawn_fan_visual(origin: Vector2, direction: Vector2, range_dist: float, width: float) -> void:
	var parent := _get_feedback_parent()
	if parent == null:
		return
	var left := direction.rotated(deg_to_rad(-34.0)).normalized()
	var right := direction.rotated(deg_to_rad(34.0)).normalized()
	_spawn_beam_visual(origin, left, range_dist, width * 0.34, Color(1.0, 0.62, 0.16, 0.68), 0.20)
	_spawn_beam_visual(origin, direction, range_dist, width * 0.42, Color(1.0, 0.72, 0.24, 0.74), 0.20)
	_spawn_beam_visual(origin, right, range_dist, width * 0.34, Color(1.0, 0.62, 0.16, 0.68), 0.20)


func _get_feedback_parent() -> Node:
	if projectile_container != null and is_instance_valid(projectile_container):
		return projectile_container
	if owner_body != null and owner_body.get_parent() != null:
		return owner_body.get_parent()
	return get_tree().current_scene


func _show_status(text: String, world_position: Vector2 = STATUS_SENTINEL) -> void:
	if feedback_manager == null or not feedback_manager.has_method("show_status"):
		return
	var pos := world_position
	if pos == STATUS_SENTINEL and owner_body != null:
		pos = owner_body.global_position + Vector2.UP * 42.0
	feedback_manager.show_status(text, pos)


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
