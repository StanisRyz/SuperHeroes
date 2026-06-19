extends Node

signal ability_cooldown_changed(slot: int, cooldown_remaining: float, cooldown_total: float)
signal ability_cast(slot: int, ability_id: String)

const KIT_SOLAR := "solar_guardian"
const KIT_TACTICIAN := "night_tactician"
const KIT_VANGUARD := "fury_vanguard"
const KIT_GENERIC := "generic"

# Slot 1 legacy tuning hook: Nova Pulse / hero area ability.
@export var nova_damage: int = 18
@export var nova_radius: float = 220.0
@export var nova_cooldown: float = 6.0
@export var pulse_feedback_scene: PackedScene
@export var nova_aftershock_feedback_scene: PackedScene
@export var nova_aftershock_enabled: bool = false
@export var nova_aftershock_damage: int = 8
@export var nova_aftershock_radius: float = 180.0
@export var nova_aftershock_delay: float = 0.45

# Slot 2 legacy tuning hook: Laser Beam / hero forward ability.
@export var laser_damage: int = 35
@export var laser_range: float = 520.0
@export var laser_width: float = 80.0
@export var laser_cooldown: float = 7.0
@export var laser_feedback_scene: PackedScene
@export var laser_double_pulse_enabled: bool = false
@export var laser_second_pulse_delay: float = 0.22
@export var laser_second_pulse_damage_multiplier: float = 0.55

# Slot 3 legacy tuning hook: Hero Slam / hero impact ability.
@export var slam_damage: int = 45
@export var slam_radius: float = 180.0
@export var slam_cooldown: float = 9.0
@export var slam_feedback_scene: PackedScene
@export var slam_second_wave_enabled: bool = false
@export var slam_second_wave_delay: float = 0.35
@export var slam_second_wave_damage_multiplier: float = 0.55
@export var slam_second_wave_radius_multiplier: float = 1.25

@export var solar_charge_max: float = 100.0
@export var solar_charge_per_hit: float = 14.0
@export var solar_empower_threshold: float = 60.0
@export var solar_empower_cost: float = 55.0
@export var solar_empower_damage_multiplier: float = 1.35
@export var solar_empower_radius_multiplier: float = 1.18
@export var aerial_impact_invulnerability: float = 0.35

@export var tactical_mark_damage_multiplier: float = 1.45
@export var tactical_mark_refresh_radius: float = 760.0
@export var smoke_slow_duration: float = 2.0
@export var smoke_slow_multiplier: float = 0.72
@export var shock_trap_delay: float = 0.28
@export var shock_trap_radius_multiplier: float = 0.9

@export var rage_max: float = 100.0
@export var rage_per_damage_taken: float = 2.0
@export var rage_per_hit: float = 6.0
@export var rage_decay_per_second: float = 4.0
@export var rage_damage_multiplier_at_max: float = 1.45
@export var rage_spend_fraction: float = 0.45

var player: Node2D
var enemy_container: Node
var _feedback_manager: Node = null

var current_hero_id: String = ""
var current_kit_id: String = KIT_GENERIC
var _kit_data: Dictionary = {}
var solar_charge: float = 0.0
var rage: float = 0.0
var tactical_mark_target: Node2D = null

var _cooldowns := {1: 0.0, 2: 0.0, 3: 0.0}
var _last_emitted := {1: -1.0, 2: -1.0, 3: -1.0}
var _ability_display_names: Dictionary = {}


func setup(new_player: Node2D, new_enemy_container: Node) -> void:
	player = new_player
	enemy_container = new_enemy_container
	if player != null and player.has_signal("damage_taken") and not player.damage_taken.is_connected(_on_player_damage_taken):
		player.damage_taken.connect(_on_player_damage_taken)


func setup_feedback_manager(fm: Node) -> void:
	_feedback_manager = fm
	_emit_cooldown_changed(1, true)
	_emit_cooldown_changed(2, true)
	_emit_cooldown_changed(3, true)


func set_ability_display_names(names: Dictionary) -> void:
	_ability_display_names = names.duplicate(true)
	_emit_cooldown_changed(1, true)
	_emit_cooldown_changed(2, true)
	_emit_cooldown_changed(3, true)


func set_hero_kit(hero_id: String, kit_id: String, kit_data: Dictionary = {}) -> void:
	current_hero_id = hero_id
	current_kit_id = kit_id if not kit_id.is_empty() else KIT_GENERIC
	_kit_data = kit_data.duplicate(true)
	solar_charge = 0.0
	rage = 0.0
	tactical_mark_target = null


func _process(delta: float) -> void:
	for slot: int in _cooldowns.keys():
		if _cooldowns[slot] > 0.0:
			_cooldowns[slot] = maxf(_cooldowns[slot] - delta, 0.0)
			_emit_cooldown_changed(slot, false)
	if current_kit_id == KIT_VANGUARD and rage > 0.0:
		rage = maxf(rage - rage_decay_per_second * delta, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ability_1"):
		cast_ability_1()
	elif event.is_action_pressed("ability_2"):
		cast_ability_2()
	elif event.is_action_pressed("ability_3"):
		cast_ability_3()


func cast_ability_1() -> void:
	match current_kit_id:
		KIT_SOLAR:
			_try_cast_solar_burst()
		KIT_TACTICIAN:
			_try_cast_smoke_charge()
		KIT_VANGUARD:
			_try_cast_rage_burst()
		_:
			_try_cast_nova_pulse()


func cast_ability_2() -> void:
	match current_kit_id:
		KIT_SOLAR:
			_try_cast_solar_beam()
		KIT_TACTICIAN:
			_try_cast_grapnel_shot()
		KIT_VANGUARD:
			_try_cast_crushing_leap()
		_:
			_try_cast_laser_beam()


func cast_ability_3() -> void:
	match current_kit_id:
		KIT_SOLAR:
			_try_cast_aerial_impact()
		KIT_TACTICIAN:
			_try_cast_shock_trap()
		KIT_VANGUARD:
			_try_cast_titan_slam()
		_:
			_try_cast_hero_slam()


func get_ability_state(slot: int) -> Dictionary:
	var ability_ids := _get_ability_ids()
	match slot:
		1:
			return {
				"id": ability_ids.get(1, "nova_pulse"),
				"display_name": _get_ability_display_name(1, "Ability 1"),
				"short_name": _get_ability_short_name(1, "A1"),
				"input_action": "ability_1",
				"cooldown_remaining": _cooldowns[1],
				"cooldown_total": nova_cooldown
			}
		2:
			return {
				"id": ability_ids.get(2, "laser_beam"),
				"display_name": _get_ability_display_name(2, "Ability 2"),
				"short_name": _get_ability_short_name(2, "A2"),
				"input_action": "ability_2",
				"cooldown_remaining": _cooldowns[2],
				"cooldown_total": laser_cooldown
			}
		3:
			return {
				"id": ability_ids.get(3, "hero_slam"),
				"display_name": _get_ability_display_name(3, "Ability 3"),
				"short_name": _get_ability_short_name(3, "A3"),
				"input_action": "ability_3",
				"cooldown_remaining": _cooldowns[3],
				"cooldown_total": slam_cooldown
			}
	return {}


func get_all_ability_states() -> Dictionary:
	return {1: get_ability_state(1), 2: get_ability_state(2), 3: get_ability_state(3)}


func get_ability_name(slot: int, prefer_short: bool = false) -> String:
	var state := get_ability_state(slot)
	if state.is_empty():
		return "Ability"
	if prefer_short:
		return str(state.get("short_name", state.get("display_name", "Ability")))
	return str(state.get("display_name", state.get("short_name", "Ability")))


func get_hero_kit_state() -> Dictionary:
	var mark_name := "none"
	if _is_valid_enemy(tactical_mark_target):
		mark_name = _get_enemy_display_name(tactical_mark_target)
	return {
		"hero_id": current_hero_id,
		"kit_id": current_kit_id,
		"passive_name": str(_kit_data.get("passive_name", _get_default_passive_name())),
		"solar_charge": solar_charge,
		"solar_charge_max": solar_charge_max,
		"rage": rage,
		"rage_max": rage_max,
		"tactical_mark_target": mark_name,
		"has_tactical_mark": _is_valid_enemy(tactical_mark_target),
	}


func _get_enemy_display_name(enemy: Node) -> String:
	var display := str(enemy.get("display_name") if enemy.get("display_name") != null else "")
	if not display.is_empty():
		return display
	var variant := str(enemy.get("variant_id") if enemy.get("variant_id") != null else "")
	if not variant.is_empty():
		return variant
	return enemy.name


func _guard_cast(slot: int) -> bool:
	if get_tree().paused:
		return false
	if player == null or not is_instance_valid(player):
		return false
	if player.has_method("is_dead") and player.is_dead():
		return false
	if _cooldowns[slot] > 0.0:
		return false
	return true


func _try_cast_nova_pulse() -> void:
	if not _guard_cast(1):
		return
	var cast_position := player.global_position
	var hits := _damage_enemies_in_radius_at(cast_position, nova_damage, nova_radius)
	if hits <= 0:
		return
	_spawn_pulse_feedback_at(cast_position, nova_radius)
	if nova_aftershock_enabled:
		_schedule_nova_aftershock(cast_position)
	_shake(5.0, 0.14)
	_finish_cast(1, "nova_pulse", nova_cooldown)


func _try_cast_laser_beam() -> void:
	if not _guard_cast(2):
		return
	var direction := _get_player_aim_direction()
	var origin := player.global_position
	var hits := _damage_enemies_in_laser(origin, direction, laser_damage, laser_range, laser_width)
	if hits <= 0:
		return
	_spawn_laser_feedback_at(origin, direction, laser_range, laser_width)
	if laser_double_pulse_enabled:
		_schedule_laser_second_pulse(origin, direction)
	_finish_cast(2, "laser_beam", laser_cooldown)


func _try_cast_hero_slam() -> void:
	if not _guard_cast(3):
		return
	var cast_position := player.global_position
	var hits := _damage_enemies_in_radius_at(cast_position, slam_damage, slam_radius)
	if hits <= 0:
		return
	_spawn_slam_feedback_at(cast_position, slam_radius)
	if slam_second_wave_enabled:
		_schedule_slam_second_wave(cast_position)
	_shake(7.0, 0.18)
	_finish_cast(3, "hero_slam", slam_cooldown)


func _try_cast_solar_burst() -> void:
	if not _guard_cast(1):
		return
	var empowered := _consume_solar_empower()
	var damage := _scale_int(nova_damage, solar_empower_damage_multiplier if empowered else 1.0)
	var radius := nova_radius * (solar_empower_radius_multiplier if empowered else 1.0)
	var hits := _damage_enemies_in_radius_at(player.global_position, damage, radius)
	if hits <= 0:
		return
	if not empowered:
		_add_solar_charge(hits * solar_charge_per_hit)
	_spawn_pulse_feedback_at(player.global_position, radius)
	_status("CHARGE BURST" if empowered else "SOLAR", player.global_position + Vector2.UP * 42.0)
	if nova_aftershock_enabled:
		_schedule_nova_aftershock(player.global_position)
	_shake(5.5, 0.14)
	_finish_cast(1, "solar_burst", nova_cooldown)


func _try_cast_solar_beam() -> void:
	if not _guard_cast(2):
		return
	var empowered := _consume_solar_empower()
	var direction := _get_player_aim_direction()
	var origin := player.global_position
	var damage := _scale_int(laser_damage, solar_empower_damage_multiplier if empowered else 1.0)
	var beam_width := laser_width * (1.1 if empowered else 0.92)
	var hits := _damage_enemies_in_laser(origin, direction, damage, laser_range, beam_width)
	if hits <= 0:
		return
	if not empowered:
		_add_solar_charge(hits * solar_charge_per_hit)
	_spawn_laser_feedback_at(origin, direction, laser_range, beam_width)
	_status("CHARGED BEAM" if empowered else "BEAM", origin + Vector2.UP * 42.0)
	if laser_double_pulse_enabled:
		_schedule_laser_second_pulse(origin, direction)
	_finish_cast(2, "solar_beam", laser_cooldown)


func _try_cast_aerial_impact() -> void:
	if not _guard_cast(3):
		return
	var empowered := _consume_solar_empower()
	var direction := _get_player_aim_direction()
	var impact_position := player.global_position + direction * 90.0
	var damage := _scale_int(slam_damage, 1.25 if empowered else 0.95)
	var radius := slam_radius * (1.25 if empowered else 0.85)
	var hits := _damage_enemies_in_radius_at(impact_position, damage, radius)
	if hits <= 0:
		return
	if not empowered:
		_add_solar_charge(hits * solar_charge_per_hit)
	_grant_brief_invulnerability(aerial_impact_invulnerability)
	_spawn_slam_feedback_at(impact_position, radius)
	if slam_second_wave_enabled:
		_schedule_slam_second_wave(impact_position)
	_status("AERIAL GUARD" if empowered else "IMPACT", player.global_position + Vector2.UP * 42.0)
	_shake(7.5, 0.18)
	_finish_cast(3, "aerial_impact", slam_cooldown)


func _try_cast_smoke_charge() -> void:
	if not _guard_cast(1):
		return
	_refresh_tactical_mark()
	var hits := _damage_enemies_in_radius_at(player.global_position, nova_damage, nova_radius * 0.9)
	if hits <= 0:
		return
	_apply_enemy_modifier_in_radius(player.global_position, nova_radius, "smoke_slow", {"speed_multiplier": smoke_slow_multiplier}, smoke_slow_duration)
	_spawn_pulse_feedback_at(player.global_position, nova_radius * 0.9)
	_status("SMOKE", player.global_position + Vector2.UP * 42.0)
	if nova_aftershock_enabled:
		_schedule_nova_aftershock(player.global_position)
	_shake(4.0, 0.12)
	_finish_cast(1, "smoke_charge", nova_cooldown)


func _try_cast_grapnel_shot() -> void:
	if not _guard_cast(2):
		return
	_refresh_tactical_mark()
	var direction := _get_player_aim_direction()
	var origin := player.global_position
	var hits := _damage_enemies_in_laser(origin, direction, laser_damage, laser_range * 1.08, maxf(laser_width * 0.55, 24.0), tactical_mark_target, tactical_mark_damage_multiplier)
	if hits <= 0:
		return
	_spawn_laser_feedback_at(origin, direction, laser_range * 1.08, maxf(laser_width * 0.55, 24.0))
	_status("MARK HIT" if _is_valid_enemy(tactical_mark_target) else "GRAPNEL", origin + Vector2.UP * 42.0)
	if laser_double_pulse_enabled:
		_schedule_laser_second_pulse(origin, direction)
	_finish_cast(2, "grapnel_shot", laser_cooldown)


func _try_cast_shock_trap() -> void:
	if not _guard_cast(3):
		return
	_refresh_tactical_mark()
	var trap_position := player.global_position
	_spawn_slam_feedback_at(trap_position, slam_radius * shock_trap_radius_multiplier)
	_status("TRAP", trap_position + Vector2.UP * 42.0)
	var timer := get_tree().create_timer(shock_trap_delay)
	timer.timeout.connect(func() -> void:
		if not is_inside_tree():
			return
		var hits := _damage_enemies_in_radius_at(trap_position, slam_damage, slam_radius * shock_trap_radius_multiplier, tactical_mark_target, tactical_mark_damage_multiplier)
		if hits > 0:
			_spawn_slam_feedback_at(trap_position, slam_radius * shock_trap_radius_multiplier)
	)
	if slam_second_wave_enabled:
		_schedule_slam_second_wave(trap_position)
	_finish_cast(3, "shock_trap", slam_cooldown)


func _try_cast_rage_burst() -> void:
	if not _guard_cast(1):
		return
	var multiplier := _get_rage_damage_multiplier()
	var hits := _damage_enemies_in_radius_at(player.global_position, _scale_int(nova_damage, multiplier), nova_radius * (1.0 + 0.12 * _rage_ratio()))
	if hits <= 0:
		return
	_add_rage(hits * rage_per_hit)
	_spawn_pulse_feedback_at(player.global_position, nova_radius * (1.0 + 0.12 * _rage_ratio()))
	_status("RAGE %.0f" % rage, player.global_position + Vector2.UP * 42.0)
	if nova_aftershock_enabled:
		_schedule_nova_aftershock(player.global_position)
	_shake(6.0, 0.16)
	_finish_cast(1, "rage_burst", nova_cooldown)


func _try_cast_crushing_leap() -> void:
	if not _guard_cast(2):
		return
	var direction := _get_player_aim_direction()
	var origin := player.global_position
	var impact_position := origin + direction * 145.0
	var impact_width := maxf(laser_width * 0.9, 60.0)
	var hits := _damage_enemies_in_laser(origin, direction, _scale_int(laser_damage, _get_rage_damage_multiplier()), laser_range * 0.72, impact_width)
	hits += _damage_enemies_in_radius_at(impact_position, maxi(roundi(float(laser_damage) * 0.55), 1), slam_radius * 0.55)
	if hits <= 0:
		return
	_add_rage(hits * rage_per_hit)
	_spawn_laser_feedback_at(origin, direction, laser_range * 0.72, impact_width)
	_spawn_slam_feedback_at(impact_position, slam_radius * 0.55)
	_status("LEAP", origin + Vector2.UP * 42.0)
	if laser_double_pulse_enabled:
		_schedule_laser_second_pulse(origin, direction)
	_shake(6.0, 0.14)
	_finish_cast(2, "crushing_leap", laser_cooldown)


func _try_cast_titan_slam() -> void:
	if not _guard_cast(3):
		return
	var multiplier := _get_rage_damage_multiplier()
	var radius := slam_radius * (1.0 + 0.25 * _rage_ratio())
	var hits := _damage_enemies_in_radius_at(player.global_position, _scale_int(slam_damage, multiplier), radius)
	if hits <= 0:
		return
	_add_rage(hits * rage_per_hit)
	_spend_rage_fraction()
	_spawn_slam_feedback_at(player.global_position, radius)
	if slam_second_wave_enabled:
		_schedule_slam_second_wave(player.global_position)
	_status("TITAN SLAM", player.global_position + Vector2.UP * 42.0)
	_shake(8.5, 0.2)
	_finish_cast(3, "titan_slam", slam_cooldown)


func _finish_cast(slot: int, ability_id: String, cooldown: float) -> void:
	_cooldowns[slot] = maxf(cooldown, 0.0)
	ability_cast.emit(slot, ability_id)
	_emit_cooldown_changed(slot, true)


func _shake(intensity: float, duration: float) -> void:
	if _feedback_manager != null and _feedback_manager.has_method("shake"):
		_feedback_manager.shake(intensity, duration)
	elif player != null and player.has_method("shake_camera"):
		player.shake_camera(intensity, duration)


func _damage_enemies_in_radius(damage: int, radius: float) -> int:
	if player == null or not is_instance_valid(player):
		return 0
	return _damage_enemies_in_radius_at(player.global_position, damage, radius)


func _damage_enemies_in_radius_at(world_position: Vector2, damage: int, radius: float, bonus_target: Node = null, bonus_multiplier: float = 1.0) -> int:
	if enemy_container == null or not is_instance_valid(enemy_container):
		push_warning("AbilityManager is missing EnemyContainer reference.")
		return 0
	var hit_count := 0
	for enemy in enemy_container.get_children():
		if _is_valid_enemy(enemy) and world_position.distance_to((enemy as Node2D).global_position) <= radius:
			enemy.take_damage(_get_damage_for_target(enemy, damage, bonus_target, bonus_multiplier))
			hit_count += 1
	return hit_count


func _damage_enemies_in_laser(origin: Vector2, direction: Vector2, damage: int, beam_range: float, beam_width: float, bonus_target: Node = null, bonus_multiplier: float = 1.0) -> int:
	if enemy_container == null or not is_instance_valid(enemy_container):
		push_warning("AbilityManager is missing EnemyContainer reference.")
		return 0
	var hit_count := 0
	var half_width := beam_width * 0.5
	var perp_axis := direction.orthogonal()
	for enemy in enemy_container.get_children():
		if not _is_valid_enemy(enemy):
			continue
		var to_enemy: Vector2 = (enemy as Node2D).global_position - origin
		var proj: float = to_enemy.dot(direction)
		if proj < 0.0 or proj > beam_range:
			continue
		if absf(to_enemy.dot(perp_axis)) <= half_width:
			enemy.take_damage(_get_damage_for_target(enemy, damage, bonus_target, bonus_multiplier))
			hit_count += 1
	return hit_count


func _get_damage_for_target(enemy: Node, base_damage: int, bonus_target: Node, bonus_multiplier: float) -> int:
	if bonus_target != null and is_instance_valid(bonus_target) and enemy == bonus_target:
		return _scale_int(base_damage, bonus_multiplier)
	return base_damage


func _apply_enemy_modifier_in_radius(world_position: Vector2, radius: float, modifier_id: String, values: Dictionary, duration: float) -> void:
	if enemy_container == null or not is_instance_valid(enemy_container):
		return
	for enemy in enemy_container.get_children():
		if _is_valid_enemy(enemy) and world_position.distance_to((enemy as Node2D).global_position) <= radius and enemy.has_method("apply_temporary_modifier"):
			enemy.apply_temporary_modifier(modifier_id, values, duration)


func _get_player_aim_direction() -> Vector2:
	if player != null and player.has_method("get_aim_direction"):
		return player.get_aim_direction()
	return Vector2.RIGHT


func _spawn_pulse_feedback() -> void:
	_spawn_pulse_feedback_at(player.global_position if player != null else Vector2.ZERO, nova_radius)


func _spawn_pulse_feedback_at(world_position: Vector2, radius: float) -> void:
	if pulse_feedback_scene == null:
		return
	var feedback_node := pulse_feedback_scene.instantiate()
	if not feedback_node is Node2D:
		push_warning("Nova Pulse feedback scene root must be Node2D.")
		feedback_node.queue_free()
		return
	var feedback := feedback_node as Node2D
	_get_feedback_parent().add_child(feedback)
	feedback.global_position = world_position
	if feedback.has_method("play"):
		feedback.play(radius)


func _spawn_laser_feedback(direction: Vector2) -> void:
	if player == null:
		return
	_spawn_laser_feedback_at(player.global_position, direction, laser_range, laser_width)


func _spawn_slam_feedback() -> void:
	if player == null:
		return
	_spawn_slam_feedback_at(player.global_position, slam_radius)


func _spawn_aftershock_feedback(world_position: Vector2, radius: float) -> void:
	if nova_aftershock_feedback_scene == null:
		return
	var feedback_node := nova_aftershock_feedback_scene.instantiate()
	if not feedback_node is Node2D:
		push_warning("Nova Aftershock feedback scene root must be Node2D.")
		feedback_node.queue_free()
		return
	var feedback := feedback_node as Node2D
	_get_feedback_parent().add_child(feedback)
	if feedback.has_method("play"):
		feedback.play(world_position, radius)


func _schedule_nova_aftershock(world_position: Vector2) -> void:
	var timer := get_tree().create_timer(nova_aftershock_delay)
	timer.timeout.connect(func() -> void:
		if not is_inside_tree():
			return
		_damage_enemies_in_radius_at(world_position, nova_aftershock_damage, nova_aftershock_radius)
		_spawn_aftershock_feedback(world_position, nova_aftershock_radius)
	)


func _schedule_laser_second_pulse(origin: Vector2, direction: Vector2) -> void:
	var timer := get_tree().create_timer(laser_second_pulse_delay)
	timer.timeout.connect(func() -> void:
		if not is_inside_tree():
			return
		var second_damage := maxi(roundi(float(laser_damage) * laser_second_pulse_damage_multiplier), 1)
		_damage_enemies_in_laser(origin, direction, second_damage, laser_range, laser_width)
		_spawn_laser_feedback_at(origin, direction, laser_range, laser_width)
	)


func _schedule_slam_second_wave(world_position: Vector2) -> void:
	var timer := get_tree().create_timer(slam_second_wave_delay)
	timer.timeout.connect(func() -> void:
		if not is_inside_tree():
			return
		var second_damage := maxi(roundi(float(slam_damage) * slam_second_wave_damage_multiplier), 1)
		var second_radius := slam_radius * slam_second_wave_radius_multiplier
		_damage_enemies_in_radius_at(world_position, second_damage, second_radius)
		_spawn_slam_feedback_at(world_position, second_radius)
	)


func _spawn_laser_feedback_at(origin: Vector2, direction: Vector2, beam_range: float, beam_width: float) -> void:
	if laser_feedback_scene == null:
		return
	var feedback_node := laser_feedback_scene.instantiate()
	if not feedback_node is Node2D:
		feedback_node.queue_free()
		return
	var feedback := feedback_node as Node2D
	_get_feedback_parent().add_child(feedback)
	if feedback.has_method("play"):
		feedback.play(origin, direction, beam_range, beam_width)


func _spawn_slam_feedback_at(world_position: Vector2, radius: float) -> void:
	if slam_feedback_scene == null:
		return
	var feedback_node := slam_feedback_scene.instantiate()
	if not feedback_node is Node2D:
		feedback_node.queue_free()
		return
	var feedback := feedback_node as Node2D
	_get_feedback_parent().add_child(feedback)
	if feedback.has_method("play"):
		feedback.play(world_position, radius)


func _get_feedback_parent() -> Node:
	if player != null and player.get_parent() != null:
		return player.get_parent()
	if get_parent() != null:
		return get_parent()
	return get_tree().current_scene


func _is_valid_enemy(node: Node) -> bool:
	return (
		node is Node2D
		and is_instance_valid(node)
		and not node.is_queued_for_deletion()
		and node.has_method("take_damage")
	)


func _refresh_tactical_mark() -> void:
	if _is_valid_enemy(tactical_mark_target):
		return
	tactical_mark_target = _find_priority_enemy()
	if _is_valid_enemy(tactical_mark_target):
		_status("MARK", tactical_mark_target.global_position + Vector2.UP * 30.0)


func _find_priority_enemy() -> Node2D:
	if enemy_container == null or not is_instance_valid(enemy_container) or player == null:
		return null
	var best_enemy: Node2D = null
	var best_score := -INF
	for enemy in enemy_container.get_children():
		if not _is_valid_enemy(enemy):
			continue
		var enemy_node := enemy as Node2D
		var distance := player.global_position.distance_to(enemy_node.global_position)
		if distance > tactical_mark_refresh_radius:
			continue
		var score := -distance
		if enemy.get("is_miniboss") == true:
			score += 3000.0
		elif enemy.get("is_elite") == true:
			score += 1800.0
		elif str(enemy.get("variant_id")) == "shielded" or str(enemy.get("behavior_id")) == "support":
			score += 450.0
		if score > best_score:
			best_score = score
			best_enemy = enemy_node
	return best_enemy


func _add_solar_charge(amount: float) -> void:
	solar_charge = clampf(solar_charge + amount, 0.0, solar_charge_max)


func _consume_solar_empower() -> bool:
	if solar_charge < solar_empower_threshold:
		return false
	solar_charge = maxf(solar_charge - solar_empower_cost, 0.0)
	return true


func _add_rage(amount: float) -> void:
	rage = clampf(rage + amount, 0.0, rage_max)


func _spend_rage_fraction() -> void:
	rage = maxf(rage - rage_max * rage_spend_fraction, 0.0)


func _get_rage_damage_multiplier() -> float:
	return lerpf(1.0, rage_damage_multiplier_at_max, _rage_ratio())


func _rage_ratio() -> float:
	return clampf(rage / rage_max, 0.0, 1.0) if rage_max > 0.0 else 0.0


func _on_player_damage_taken(amount: int) -> void:
	if current_kit_id != KIT_VANGUARD:
		return
	_add_rage(float(amount) * rage_per_damage_taken)


func _grant_brief_invulnerability(duration: float) -> void:
	if player == null:
		return
	if player.get("invulnerability_time_remaining") != null:
		player.set("invulnerability_time_remaining", maxf(float(player.get("invulnerability_time_remaining")), duration))
	if player.has_signal("invulnerability_changed"):
		player.invulnerability_changed.emit(true)


func _status(text: String, world_position: Vector2) -> void:
	if _feedback_manager != null and _feedback_manager.has_method("show_status"):
		_feedback_manager.show_status(text, world_position)


func _scale_int(value: int, multiplier: float) -> int:
	return maxi(roundi(float(value) * multiplier), 1)


func _emit_cooldown_changed(slot: int, force: bool) -> void:
	var remaining: float = _cooldowns.get(slot, 0.0)
	var last: float = _last_emitted.get(slot, -1.0)
	var total := _get_cooldown_total(slot)

	var should_emit := force
	if not should_emit:
		should_emit = absf(remaining - last) >= 0.05
	should_emit = should_emit or (remaining == 0.0 and last != 0.0)

	if not should_emit:
		return

	_last_emitted[slot] = remaining
	ability_cooldown_changed.emit(slot, remaining, total)


func _get_cooldown_total(slot: int) -> float:
	match slot:
		1: return nova_cooldown
		2: return laser_cooldown
		3: return slam_cooldown
	return 0.0


func _get_ability_display_name(slot: int, fallback: String) -> String:
	var data: Dictionary = _ability_display_names.get(slot, {})
	return str(data.get("display_name", fallback))


func _get_ability_short_name(slot: int, fallback: String) -> String:
	var data: Dictionary = _ability_display_names.get(slot, {})
	return str(data.get("short_name", data.get("display_name", fallback)))


func _get_ability_ids() -> Dictionary:
	match current_kit_id:
		KIT_SOLAR:
			return {1: "solar_burst", 2: "solar_beam", 3: "aerial_impact"}
		KIT_TACTICIAN:
			return {1: "smoke_charge", 2: "grapnel_shot", 3: "shock_trap"}
		KIT_VANGUARD:
			return {1: "rage_burst", 2: "crushing_leap", 3: "titan_slam"}
	return {1: "nova_pulse", 2: "laser_beam", 3: "hero_slam"}


func _get_default_passive_name() -> String:
	match current_kit_id:
		KIT_SOLAR:
			return "Solar Charge"
		KIT_TACTICIAN:
			return "Tactical Mark"
		KIT_VANGUARD:
			return "Rage"
	return "None"
