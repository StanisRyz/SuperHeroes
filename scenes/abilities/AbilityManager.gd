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

# Solar Guardian tuning — Solar Energy passive + 3 abilities
@export var solar_energy_per_second: float = 2.0
@export var solar_energy_max: float = 100.0
@export var solar_empowered_duration: float = 15.0
@export var solar_empowered_damage_multiplier: float = 2.0

@export var solar_beam_damage: int = 30
@export var solar_beam_range: float = 520.0
@export var solar_beam_width: float = 80.0
@export var solar_beam_cooldown: float = 7.0

@export var frost_breath_damage: int = 18
@export var frost_breath_range: float = 280.0
@export var frost_breath_cone_degrees: float = 55.0
@export var frost_breath_cooldown: float = 8.0
@export var frost_breath_slow_multiplier: float = 0.55
@export var frost_breath_slow_duration: float = 2.5

@export var death_dash_damage: int = 28
@export var death_dash_distance: float = 220.0
@export var death_dash_path_width: float = 60.0
@export var death_dash_cooldown: float = 9.0
@export var death_dash_invulnerability: float = 0.30

# Night Tactician — Smoke Screen
@export var smoke_screen_radius: float = 200.0
@export var smoke_screen_duration: float = 5.0
@export var smoke_screen_cooldown: float = 8.0
@export var smoke_screen_slow_multiplier: float = 0.55
@export var smoke_screen_slow_duration: float = 2.5
@export var smoke_screen_damage_reduction: float = 0.30

# Night Tactician — Explosive Trap
@export var explosive_trap_damage: int = 35
@export var explosive_trap_trigger_radius: float = 60.0
@export var explosive_trap_explosion_radius: float = 160.0
@export var explosive_trap_duration: float = 10.0
@export var explosive_trap_cooldown: float = 10.0

# Night Tactician — Grappling Hook
@export var grappling_hook_damage: int = 50
@export var grappling_hook_range: float = 380.0
@export var grappling_hook_cooldown: float = 9.0
@export var grappling_hook_invulnerability: float = 0.20

# Night Tactician — Tactical Mark (multi-enemy, duration-based)
@export var tactical_mark_duration: float = 6.0
@export var tactical_mark_autoattack_damage_multiplier: float = 1.35

@export var rage_max: float = 100.0
@export var rage_per_damage_taken: float = 2.0
@export var rage_per_hit: float = 6.0
@export var rage_per_damage_dealt: float = 0.08
@export var rage_decay_per_second: float = 4.0
@export var rage_damage_multiplier_at_max: float = 1.45

# Fury Vanguard — Rage Wave (slot 1)
@export var rage_wave_damage: int = 20
@export var rage_wave_radius: float = 210.0
@export var rage_wave_cooldown: float = 6.0
@export var rage_wave_slow_multiplier: float = 0.55
@export var rage_wave_slow_duration: float = 2.0
@export var rage_wave_radius_rage_bonus: float = 0.0

# Fury Vanguard — Mighty Clap (slot 2)
@export var mighty_clap_damage: int = 28
@export var mighty_clap_cone_degrees: float = 60.0
@export var mighty_clap_range: float = 185.0
@export var mighty_clap_cooldown: float = 7.0
@export var mighty_clap_knockback_force: float = 180.0

# Fury Vanguard — Rage Leap (slot 3)
@export var rage_leap_distance: float = 210.0
@export var rage_leap_damage: int = 35
@export var rage_leap_radius: float = 160.0
@export var rage_leap_cooldown: float = 9.0
@export var rage_leap_slow_multiplier: float = 0.55
@export var rage_leap_slow_duration: float = 2.0
@export var rage_leap_invulnerability: float = 0.22

var player: Node2D
var enemy_container: Node
var _feedback_manager: Node = null

var current_hero_id: String = ""
var current_kit_id: String = KIT_GENERIC
var _kit_data: Dictionary = {}
var solar_energy: float = 0.0
var _solar_empowered: bool = false
var _solar_empowered_time_left: float = 0.0
var rage: float = 0.0
# Tactical Mark: maps enemy Node -> seconds remaining
var _tactical_marks: Dictionary = {}
var _active_smoke_screens: Array[Dictionary] = []
var _active_explosive_traps: Array[Dictionary] = []

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
	solar_energy = 0.0
	_solar_empowered = false
	_solar_empowered_time_left = 0.0
	rage = 0.0
	_tactical_marks.clear()
	for screen in _active_smoke_screens:
		var visual = screen.get("visual")
		if visual != null and is_instance_valid(visual):
			visual.queue_free()
	_active_smoke_screens.clear()
	for trap in _active_explosive_traps:
		var visual = trap.get("visual")
		if visual != null and is_instance_valid(visual):
			visual.queue_free()
	_active_explosive_traps.clear()
	if player != null and player.get("damage_reduction") != null:
		player.set("damage_reduction", 0.0)


func _process(delta: float) -> void:
	for slot: int in _cooldowns.keys():
		if _cooldowns[slot] > 0.0:
			_cooldowns[slot] = maxf(_cooldowns[slot] - delta, 0.0)
			_emit_cooldown_changed(slot, false)
	if current_kit_id == KIT_SOLAR:
		_tick_solar_energy(delta)
	if current_kit_id == KIT_VANGUARD and rage > 0.0:
		rage = maxf(rage - rage_decay_per_second * delta, 0.0)
	if current_kit_id == KIT_TACTICIAN:
		_tick_tactical_marks(delta)
		_tick_smoke_screens(delta)
		_tick_explosive_traps(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ability_1"):
		cast_ability_1()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ability_2"):
		cast_ability_2()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ability_3"):
		cast_ability_3()
		get_viewport().set_input_as_handled()


func cast_ability_1() -> void:
	match current_kit_id:
		KIT_SOLAR:
			_try_cast_solar_beam_ability()
		KIT_TACTICIAN:
			_try_cast_smoke_screen()
		KIT_VANGUARD:
			_try_cast_rage_wave()
		_:
			_try_cast_nova_pulse()


func cast_ability_2() -> void:
	match current_kit_id:
		KIT_SOLAR:
			_try_cast_frost_breath()
		KIT_TACTICIAN:
			_try_cast_explosive_trap()
		KIT_VANGUARD:
			_try_cast_mighty_clap()
		_:
			_try_cast_laser_beam()


func cast_ability_3() -> void:
	match current_kit_id:
		KIT_SOLAR:
			_try_cast_death_dash()
		KIT_TACTICIAN:
			_try_cast_grappling_hook()
		KIT_VANGUARD:
			_try_cast_rage_leap()
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
				"cooldown_total": _get_cooldown_total(1)
			}
		2:
			return {
				"id": ability_ids.get(2, "laser_beam"),
				"display_name": _get_ability_display_name(2, "Ability 2"),
				"short_name": _get_ability_short_name(2, "A2"),
				"input_action": "ability_2",
				"cooldown_remaining": _cooldowns[2],
				"cooldown_total": _get_cooldown_total(2)
			}
		3:
			return {
				"id": ability_ids.get(3, "hero_slam"),
				"display_name": _get_ability_display_name(3, "Ability 3"),
				"short_name": _get_ability_short_name(3, "A3"),
				"input_action": "ability_3",
				"cooldown_remaining": _cooldowns[3],
				"cooldown_total": _get_cooldown_total(3)
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
	var marked_count := get_marked_enemy_count()
	return {
		"hero_id": current_hero_id,
		"kit_id": current_kit_id,
		"passive_name": str(_kit_data.get("passive_name", _get_default_passive_name())),
		"solar_energy": solar_energy,
		"solar_energy_max": solar_energy_max,
		"solar_empowered": _solar_empowered,
		"solar_empowered_time_left": _solar_empowered_time_left,
		"rage": rage,
		"rage_max": rage_max,
		"rage_damage_multiplier": get_rage_damage_multiplier(),
		"tactical_mark_count": marked_count,
		"tactical_mark_target": str(marked_count) + " marked" if marked_count > 0 else "none",
		"has_tactical_mark": marked_count > 0,
	}


func add_rage(amount: float) -> void:
	if current_kit_id != KIT_VANGUARD:
		return
	_add_rage(amount)


func get_rage_damage_multiplier() -> float:
	return _get_rage_damage_multiplier()


func get_rage_state() -> Dictionary:
	return {
		"rage": rage,
		"rage_max": rage_max,
		"rage_damage_multiplier": _get_rage_damage_multiplier(),
		"rage_ratio": _rage_ratio(),
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
	_spawn_pulse_feedback_at(cast_position, nova_radius)
	_status("PULSE" if hits > 0 else "PULSE MISS", cast_position + Vector2.UP * 42.0)
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
	_spawn_laser_feedback_at(origin, direction, laser_range, laser_width)
	_status("BEAM" if hits > 0 else "BEAM MISS", origin + Vector2.UP * 42.0)
	if laser_double_pulse_enabled:
		_schedule_laser_second_pulse(origin, direction)
	_finish_cast(2, "laser_beam", laser_cooldown)


func _try_cast_hero_slam() -> void:
	if not _guard_cast(3):
		return
	var cast_position := player.global_position
	var hits := _damage_enemies_in_radius_at(cast_position, slam_damage, slam_radius)
	_spawn_slam_feedback_at(cast_position, slam_radius)
	_status("SLAM" if hits > 0 else "SLAM MISS", cast_position + Vector2.UP * 42.0)
	if slam_second_wave_enabled:
		_schedule_slam_second_wave(cast_position)
	_shake(7.0, 0.18)
	_finish_cast(3, "hero_slam", slam_cooldown)


func _try_cast_solar_beam_ability() -> void:
	if not _guard_cast(1):
		return
	var damage := _scale_int(solar_beam_damage, get_solar_damage_multiplier())
	var direction := _get_player_aim_direction()
	var origin := player.global_position
	var hits := _damage_enemies_in_laser(origin, direction, damage, solar_beam_range, solar_beam_width)
	_spawn_laser_feedback_at(origin, direction, solar_beam_range, solar_beam_width)
	_status("SOLAR BEAM" if hits > 0 else "BEAM MISS", origin + Vector2.UP * 42.0)
	_shake(5.0, 0.14)
	_finish_cast(1, "solar_beam", solar_beam_cooldown)


func _try_cast_frost_breath() -> void:
	if not _guard_cast(2):
		return
	var damage := _scale_int(frost_breath_damage, get_solar_damage_multiplier())
	var direction := _get_player_aim_direction()
	var origin := player.global_position
	var half_angle := frost_breath_cone_degrees * 0.5
	var hits := _damage_enemies_in_cone(origin, direction, damage, frost_breath_range, half_angle)
	_apply_slow_in_cone(origin, direction, frost_breath_range, half_angle, frost_breath_slow_multiplier, frost_breath_slow_duration)
	var approx_width := minf(frost_breath_range * sin(deg_to_rad(half_angle)) * 1.4, 220.0)
	_spawn_laser_feedback_at(origin, direction, frost_breath_range, approx_width)
	_status("FROST BREATH" if hits > 0 else "FROST MISS", origin + Vector2.UP * 42.0)
	_finish_cast(2, "frost_breath", frost_breath_cooldown)


func _try_cast_death_dash() -> void:
	if not _guard_cast(3):
		return
	var direction := _get_player_aim_direction()
	var start_position := player.global_position
	var damage := _scale_int(death_dash_damage, get_solar_damage_multiplier())
	var path_hits := _damage_enemies_in_laser(start_position, direction, damage, death_dash_distance, death_dash_path_width)
	_grant_brief_invulnerability(death_dash_invulnerability)
	_move_player_safely(direction, death_dash_distance)
	var trail_length := start_position.distance_to(player.global_position)
	_spawn_laser_feedback_at(start_position, direction, trail_length, death_dash_path_width)
	_status("DEATH DASH" if path_hits > 0 else "DASH", start_position + Vector2.UP * 42.0)
	_shake(6.0, 0.16)
	_finish_cast(3, "death_dash", death_dash_cooldown)


func _try_cast_smoke_screen() -> void:
	if not _guard_cast(1):
		return
	var cast_position := player.global_position
	var smoke_visual := _spawn_smoke_visual(cast_position, smoke_screen_radius)
	_active_smoke_screens.append({
		"position": cast_position,
		"radius": smoke_screen_radius,
		"remaining": smoke_screen_duration,
		"slow_multiplier": smoke_screen_slow_multiplier,
		"slow_duration": smoke_screen_slow_duration,
		"visual": smoke_visual,
		"mark_tick": 0.5,
	})
	_status("SMOKE SCREEN", cast_position + Vector2.UP * 42.0)
	_shake(4.0, 0.10)
	_finish_cast(1, "smoke_screen", smoke_screen_cooldown)


func _try_cast_explosive_trap() -> void:
	if not _guard_cast(2):
		return
	var aim_dir := _get_player_aim_direction()
	var trap_position := player.global_position + aim_dir * 60.0
	var trap_visual := _spawn_trap_visual(trap_position)
	_active_explosive_traps.append({
		"position": trap_position,
		"trigger_radius": explosive_trap_trigger_radius,
		"explosion_radius": explosive_trap_explosion_radius,
		"damage": explosive_trap_damage,
		"remaining": explosive_trap_duration,
		"visual": trap_visual,
	})
	_status("TRAP SET", trap_position + Vector2.UP * 42.0)
	_finish_cast(2, "explosive_trap", explosive_trap_cooldown)


func _try_cast_grappling_hook() -> void:
	if not _guard_cast(3):
		return
	var hook_target := _find_nearest_enemy_in_range(grappling_hook_range)
	if hook_target == null:
		_status("NO TARGET", player.global_position + Vector2.UP * 42.0)
		_finish_cast(3, "grappling_hook", grappling_hook_cooldown * 0.5)
		return
	var origin := player.global_position
	_spawn_hook_visual(origin, hook_target.global_position)
	apply_tactical_mark(hook_target)
	hook_target.take_damage(grappling_hook_damage)
	_grant_brief_invulnerability(grappling_hook_invulnerability)
	var direction := (hook_target.global_position - origin).normalized()
	var raw_dist := origin.distance_to(hook_target.global_position)
	var dash_dist := maxf(raw_dist - 40.0, 0.0)
	_move_player_safely(direction, dash_dist)
	_status("HOOK", origin + Vector2.UP * 42.0)
	_shake(5.0, 0.14)
	_finish_cast(3, "grappling_hook", grappling_hook_cooldown)


func _try_cast_rage_wave() -> void:
	if not _guard_cast(1):
		return
	var multiplier := _get_rage_damage_multiplier()
	var damage := _scale_int(rage_wave_damage, multiplier)
	var radius := rage_wave_radius * (1.0 + (0.18 + rage_wave_radius_rage_bonus) * _rage_ratio())
	var cast_position := player.global_position
	var hits := _damage_enemies_in_radius_at(cast_position, damage, radius)
	_apply_enemy_modifier_in_radius(cast_position, radius, "rage_wave_slow",
		{"speed_multiplier": rage_wave_slow_multiplier}, rage_wave_slow_duration)
	_add_rage_from_ability_damage(hits, damage)
	_spawn_rage_wave_visual(cast_position, radius)
	if rage >= rage_max:
		_status("MAX RAGE WAVE", cast_position + Vector2.UP * 42.0)
	else:
		_status("RAGE WAVE" if hits > 0 else "WAVE MISS", cast_position + Vector2.UP * 42.0)
	_shake(6.0, 0.16)
	_finish_cast(1, "rage_wave", rage_wave_cooldown)


func _try_cast_mighty_clap() -> void:
	if not _guard_cast(2):
		return
	var multiplier := _get_rage_damage_multiplier()
	var damage := _scale_int(mighty_clap_damage, multiplier)
	var direction := _get_player_aim_direction()
	var origin := player.global_position
	var half_angle := mighty_clap_cone_degrees * 0.5
	var hits := _damage_enemies_in_cone(origin, direction, damage, mighty_clap_range, half_angle)
	if mighty_clap_knockback_force > 0.0:
		_apply_knockback_in_cone(origin, direction, mighty_clap_range, half_angle, mighty_clap_knockback_force)
	_add_rage_from_ability_damage(hits, damage)
	_spawn_mighty_clap_visual(origin, direction, mighty_clap_cone_degrees, mighty_clap_range)
	if rage >= rage_max:
		_status("MAX RAGE CLAP", origin + Vector2.UP * 42.0)
	else:
		_status("MIGHTY CLAP" if hits > 0 else "CLAP MISS", origin + Vector2.UP * 42.0)
	_shake(7.0, 0.18)
	_finish_cast(2, "mighty_clap", mighty_clap_cooldown)


func _try_cast_rage_leap() -> void:
	if not _guard_cast(3):
		return
	var direction := _get_player_aim_direction()
	var origin := player.global_position
	var multiplier := _get_rage_damage_multiplier()
	var damage := _scale_int(rage_leap_damage, multiplier)
	_grant_brief_invulnerability(rage_leap_invulnerability)
	_move_player_safely(direction, rage_leap_distance)
	var landing_position := player.global_position
	var hits := _damage_enemies_in_radius_at(landing_position, damage, rage_leap_radius)
	_apply_enemy_modifier_in_radius(landing_position, rage_leap_radius, "rage_leap_slow",
		{"speed_multiplier": rage_leap_slow_multiplier}, rage_leap_slow_duration)
	_add_rage_from_ability_damage(hits, damage)
	_spawn_slam_feedback_at(landing_position, rage_leap_radius)
	_spawn_rage_leap_trail_visual(origin, direction, origin.distance_to(landing_position))
	if rage >= rage_max:
		_status("MAX RAGE LEAP", origin + Vector2.UP * 42.0)
	else:
		_status("RAGE LEAP" if hits > 0 else "LEAP MISS", origin + Vector2.UP * 42.0)
	_shake(8.0, 0.20)
	_finish_cast(3, "rage_leap", rage_leap_cooldown)


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


func _damage_enemies_in_radius_at(world_position: Vector2, damage: int, radius: float, bonus_target = null, bonus_multiplier: float = 1.0) -> int:
	if enemy_container == null or not is_instance_valid(enemy_container):
		push_warning("AbilityManager is missing EnemyContainer reference.")
		return 0
	var hit_count := 0
	for enemy in enemy_container.get_children():
		if _is_valid_enemy(enemy) and world_position.distance_to((enemy as Node2D).global_position) <= radius:
			enemy.take_damage(_get_damage_for_target(enemy, damage, bonus_target, bonus_multiplier))
			hit_count += 1
	return hit_count


func _damage_enemies_in_laser(origin: Vector2, direction: Vector2, damage: int, beam_range: float, beam_width: float, bonus_target = null, bonus_multiplier: float = 1.0) -> int:
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


func _get_damage_for_target(enemy: Node, base_damage: int, bonus_target, bonus_multiplier: float) -> int:
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


func _schedule_titan_shockwave(world_position: Vector2, radius: float, damage: int) -> void:
	var timer := get_tree().create_timer(slam_second_wave_delay)
	timer.timeout.connect(func() -> void:
		if not is_inside_tree():
			return
		var hits := _damage_enemies_in_radius_at(world_position, damage, radius)
		_add_rage_from_ability_damage(hits, damage)
		_spawn_slam_feedback_at(world_position, radius)
		_status("SHOCKWAVE" if hits > 0 else "SHOCKWAVE MISS", world_position + Vector2.UP * 42.0)
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


func _spawn_rage_wave_visual(world_position: Vector2, radius: float) -> void:
	_spawn_pulse_feedback_at(world_position, radius)


func _spawn_mighty_clap_visual(origin: Vector2, direction: Vector2, cone_degrees: float, range_: float) -> void:
	var approx_width := minf(range_ * sin(deg_to_rad(cone_degrees * 0.5)) * 1.6, 260.0)
	_spawn_laser_feedback_at(origin, direction, range_, approx_width)


func _spawn_rage_leap_trail_visual(origin: Vector2, direction: Vector2, distance: float) -> void:
	_spawn_laser_feedback_at(origin, direction, distance, 40.0)


func _apply_knockback_in_cone(origin: Vector2, direction: Vector2, range_: float,
		half_angle_deg: float, force: float) -> void:
	if enemy_container == null or not is_instance_valid(enemy_container):
		return
	var half_angle_rad := deg_to_rad(half_angle_deg)
	for enemy in enemy_container.get_children():
		if not _is_valid_enemy(enemy):
			continue
		var enemy_node := enemy as Node2D
		var offset := enemy_node.global_position - origin
		if offset.length() > range_:
			continue
		if offset.length() == 0.0:
			continue
		var angle := direction.angle_to(offset.normalized())
		if absf(angle) > half_angle_rad:
			continue
		if enemy.has_method("apply_knockback"):
			enemy.apply_knockback(offset.normalized(), force)


func _get_feedback_parent() -> Node:
	if player != null and player.get_parent() != null:
		return player.get_parent()
	if get_parent() != null:
		return get_parent()
	return get_tree().current_scene


func _is_valid_enemy(node) -> bool:
	return (
		node is Node2D
		and is_instance_valid(node)
		and not node.is_queued_for_deletion()
		and node.has_method("take_damage")
	)


# ── Smoke Screen tick ─────────────────────────────────────────────────────────

func _tick_smoke_screens(delta: float) -> void:
	if _active_smoke_screens.is_empty():
		return
	var remaining_screens: Array[Dictionary] = []
	var player_in_smoke := false
	for screen in _active_smoke_screens:
		var pos: Vector2 = screen["position"]
		var radius: float = screen["radius"]
		var rem: float = maxf(float(screen["remaining"]) - delta, 0.0)
		screen["remaining"] = rem
		if player != null and is_instance_valid(player):
			if player.global_position.distance_to(pos) <= radius:
				player_in_smoke = true
		var mark_tick: float = float(screen["mark_tick"]) + delta
		if mark_tick >= 0.5:
			mark_tick -= 0.5
			_apply_smoke_effects(pos, radius, screen["slow_multiplier"], screen["slow_duration"])
		screen["mark_tick"] = mark_tick
		if rem > 0.0:
			remaining_screens.append(screen)
		else:
			var visual = screen.get("visual")
			if visual != null and is_instance_valid(visual):
				visual.queue_free()
	_active_smoke_screens = remaining_screens
	if player != null and player.get("damage_reduction") != null:
		player.set("damage_reduction", smoke_screen_damage_reduction if player_in_smoke else 0.0)


func _apply_smoke_effects(world_position: Vector2, radius: float, slow_mult: float, slow_dur: float) -> void:
	if enemy_container == null or not is_instance_valid(enemy_container):
		return
	for enemy in enemy_container.get_children():
		if not _is_valid_enemy(enemy):
			continue
		if world_position.distance_to((enemy as Node2D).global_position) <= radius:
			if enemy.has_method("apply_temporary_modifier"):
				enemy.apply_temporary_modifier("smoke_slow", {"speed_multiplier": slow_mult}, slow_dur)
			apply_tactical_mark(enemy)


func _spawn_smoke_visual(world_position: Vector2, radius: float) -> Node2D:
	var container := Node2D.new()
	_get_feedback_parent().add_child(container)
	container.global_position = world_position
	var rect := ColorRect.new()
	rect.color = Color(0.44, 0.55, 0.66, 0.38)
	rect.size = Vector2(radius * 2.0, radius * 2.0)
	rect.position = Vector2(-radius, -radius)
	container.add_child(rect)
	return container


# ── Explosive Trap tick ───────────────────────────────────────────────────────

func _tick_explosive_traps(delta: float) -> void:
	if _active_explosive_traps.is_empty():
		return
	var remaining_traps: Array[Dictionary] = []
	for trap in _active_explosive_traps:
		var pos: Vector2 = trap["position"]
		var trigger_r: float = trap["trigger_radius"]
		var rem: float = maxf(float(trap["remaining"]) - delta, 0.0)
		trap["remaining"] = rem
		var should_trigger := rem <= 0.0 or _has_enemy_in_radius(pos, trigger_r)
		if should_trigger:
			_trigger_explosive_trap(trap)
		else:
			remaining_traps.append(trap)
	_active_explosive_traps = remaining_traps


func _trigger_explosive_trap(trap: Dictionary) -> void:
	var pos: Vector2 = trap["position"]
	var explosion_r: float = trap["explosion_radius"]
	var damage: int = trap["damage"]
	var visual = trap.get("visual")
	if visual != null and is_instance_valid(visual):
		visual.queue_free()
	var hits := 0
	if enemy_container != null and is_instance_valid(enemy_container):
		for enemy in enemy_container.get_children():
			if _is_valid_enemy(enemy) and pos.distance_to((enemy as Node2D).global_position) <= explosion_r:
				enemy.take_damage(damage)
				apply_tactical_mark(enemy)
				hits += 1
	_spawn_slam_feedback_at(pos, explosion_r)
	_status("TRAP BOOM" if hits > 0 else "TRAP MISS", pos + Vector2.UP * 42.0)
	_shake(5.0, 0.14)


func _spawn_trap_visual(world_position: Vector2) -> Node2D:
	var container := Node2D.new()
	_get_feedback_parent().add_child(container)
	container.global_position = world_position
	var rect := ColorRect.new()
	rect.color = Color(1.0, 0.55, 0.1, 0.90)
	rect.size = Vector2(22.0, 22.0)
	rect.position = Vector2(-11.0, -11.0)
	container.add_child(rect)
	return container


func _spawn_hook_visual(origin: Vector2, target_pos: Vector2) -> void:
	var line := Line2D.new()
	line.add_point(origin)
	line.add_point(target_pos)
	line.width = 3.0
	line.default_color = Color(0.60, 0.85, 1.0, 0.90)
	_get_feedback_parent().add_child(line)
	var timer := get_tree().create_timer(0.28)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(line):
			line.queue_free()
	)


func _has_enemy_in_radius(world_position: Vector2, radius: float) -> bool:
	if enemy_container == null or not is_instance_valid(enemy_container):
		return false
	for enemy in enemy_container.get_children():
		if _is_valid_enemy(enemy) and world_position.distance_to((enemy as Node2D).global_position) <= radius:
			return true
	return false


# ── Tactical Mark (multi-enemy) ───────────────────────────────────────────────

func apply_tactical_mark(enemy: Node) -> void:
	if not _is_valid_enemy(enemy):
		return
	_tactical_marks[enemy] = tactical_mark_duration
	_status("MARKED", (enemy as Node2D).global_position + Vector2.UP * 30.0)


func is_tactically_marked(enemy: Node) -> bool:
	return _tactical_marks.has(enemy) and is_instance_valid(enemy) and not enemy.is_queued_for_deletion()


func get_tactical_mark_multiplier(enemy: Node) -> float:
	return tactical_mark_autoattack_damage_multiplier if is_tactically_marked(enemy) else 1.0


func get_marked_enemy_count() -> int:
	var count := 0
	for enemy in _tactical_marks.keys():
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
			count += 1
	return count


func _tick_tactical_marks(delta: float) -> void:
	if _tactical_marks.is_empty():
		return
	var expired: Array[Node] = []
	for enemy in _tactical_marks.keys():
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			expired.append(enemy)
			continue
		var remaining: float = maxf(float(_tactical_marks[enemy]) - delta, 0.0)
		_tactical_marks[enemy] = remaining
		if remaining <= 0.0:
			expired.append(enemy)
	for enemy in expired:
		_tactical_marks.erase(enemy)


func _find_nearest_enemy_in_range(range_dist: float) -> Node2D:
	if enemy_container == null or not is_instance_valid(enemy_container) or player == null:
		return null
	var nearest: Node2D = null
	var nearest_dist := INF
	for enemy in enemy_container.get_children():
		if not _is_valid_enemy(enemy):
			continue
		var dist: float = player.global_position.distance_to((enemy as Node2D).global_position)
		if dist <= range_dist and dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy as Node2D
	return nearest


func _tick_solar_energy(delta: float) -> void:
	if _solar_empowered:
		_solar_empowered_time_left = maxf(_solar_empowered_time_left - delta, 0.0)
		if _solar_empowered_time_left <= 0.0:
			_solar_empowered = false
	solar_energy = minf(solar_energy + solar_energy_per_second * delta, solar_energy_max)
	if solar_energy >= solar_energy_max and not _solar_empowered:
		_activate_solar_empower()


func _activate_solar_empower() -> void:
	solar_energy = 0.0
	_solar_empowered = true
	_solar_empowered_time_left = solar_empowered_duration
	if player != null:
		_status("SOLAR EMPOWERED", player.global_position + Vector2.UP * 48.0)
	_shake(5.0, 0.14)


func get_solar_damage_multiplier() -> float:
	if current_kit_id == KIT_SOLAR and _solar_empowered:
		return solar_empowered_damage_multiplier
	return 1.0


func _damage_enemies_in_cone(origin: Vector2, direction: Vector2, damage: int, cone_range: float, half_angle_deg: float) -> int:
	if enemy_container == null or not is_instance_valid(enemy_container):
		push_warning("AbilityManager is missing EnemyContainer reference.")
		return 0
	var half_angle_rad := deg_to_rad(half_angle_deg)
	var hit_count := 0
	for enemy in enemy_container.get_children():
		if not _is_valid_enemy(enemy):
			continue
		var to_enemy: Vector2 = (enemy as Node2D).global_position - origin
		var dist := to_enemy.length()
		if dist > cone_range:
			continue
		var angle := 0.0
		if not to_enemy.is_zero_approx():
			angle = absf(direction.angle_to(to_enemy.normalized()))
		if angle <= half_angle_rad:
			enemy.take_damage(damage)
			hit_count += 1
	return hit_count


func _apply_slow_in_cone(origin: Vector2, direction: Vector2, cone_range: float, half_angle_deg: float, slow_multiplier: float, slow_duration: float) -> void:
	if enemy_container == null or not is_instance_valid(enemy_container):
		return
	var half_angle_rad := deg_to_rad(half_angle_deg)
	for enemy in enemy_container.get_children():
		if not _is_valid_enemy(enemy):
			continue
		if not enemy.has_method("apply_temporary_modifier"):
			continue
		var to_enemy: Vector2 = (enemy as Node2D).global_position - origin
		var dist := to_enemy.length()
		if dist > cone_range:
			continue
		var angle := 0.0
		if not to_enemy.is_zero_approx():
			angle = absf(direction.angle_to(to_enemy.normalized()))
		if angle <= half_angle_rad:
			enemy.apply_temporary_modifier("frost_slow", {"speed_multiplier": slow_multiplier}, slow_duration)


func _add_rage(amount: float) -> void:
	var was_high := rage >= rage_max * 0.6
	rage = clampf(rage + amount, 0.0, rage_max)
	if not was_high and rage >= rage_max * 0.6 and player != null:
		_status("RAGE", player.global_position + Vector2.UP * 48.0)


func _add_rage_from_ability_damage(hit_count: int, damage: int) -> void:
	if hit_count <= 0 or damage <= 0:
		return
	_add_rage(float(hit_count * damage) * rage_per_damage_dealt + float(hit_count) * rage_per_hit)


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


func _move_player_safely(direction: Vector2, distance: float) -> void:
	if player == null or not is_instance_valid(player) or direction.is_zero_approx() or distance <= 0.0:
		return
	player.global_position += direction.normalized() * distance
	if player.has_method("_clamp_to_playable_rect"):
		player.call("_clamp_to_playable_rect")


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
	if current_kit_id == KIT_SOLAR:
		match slot:
			1: return solar_beam_cooldown
			2: return frost_breath_cooldown
			3: return death_dash_cooldown
	if current_kit_id == KIT_TACTICIAN:
		match slot:
			1: return smoke_screen_cooldown
			2: return explosive_trap_cooldown
			3: return grappling_hook_cooldown
	if current_kit_id == KIT_VANGUARD:
		match slot:
			1: return rage_wave_cooldown
			2: return mighty_clap_cooldown
			3: return rage_leap_cooldown
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
			return {1: "solar_beam", 2: "frost_breath", 3: "death_dash"}
		KIT_TACTICIAN:
			return {1: "smoke_screen", 2: "explosive_trap", 3: "grappling_hook"}
		KIT_VANGUARD:
			return {1: "rage_wave", 2: "mighty_clap", 3: "rage_leap"}
	return {1: "nova_pulse", 2: "laser_beam", 3: "hero_slam"}


func _get_default_passive_name() -> String:
	match current_kit_id:
		KIT_SOLAR:
			return "Solar Energy"
		KIT_TACTICIAN:
			return "Tactical Mark"
		KIT_VANGUARD:
			return "Rage"
	return "None"
