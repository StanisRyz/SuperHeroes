class_name KnightMeleeAutoAttack3D
extends Node

signal attack_impact_resolved(hit_count: int, total_damage: int)

const EARTHSPLITTER_EVOLUTION_ID := "rage_wave_earthsplitter"
const CRUSHING_STORM_EVOLUTION_ID := "rage_wave_crushing_storm"
const SEISMIC_FAN_EVOLUTION_ID := "mighty_clap_seismic_fan"
const EARTHSPLITTER_EFFECT := preload("res://scenes3d/effects/EarthsplitterEffect3D.tscn")
const CRUSHING_STORM_EFFECT := preload("res://scenes3d/effects/CrushingStormEffect3D.tscn")
const SEISMIC_FAN_EFFECT := preload("res://scenes3d/effects/SeismicFanEffect3D.tscn")
const GROUND_SHOCKWAVE_EFFECT := preload("res://scenes3d/effects/GroundShockwaveEffect3D.tscn")
const FURY_STRIKE_IMPACT_EFFECT := preload("res://scenes3d/effects/FuryStrikeImpactEffect3D.tscn")
const EARTHSPLITTER_RANGE := 6.5
const EARTHSPLITTER_WIDTH := 1.3325
const EARTHSPLITTER_DAMAGE_MULTIPLIER := 0.75
const GROUND_SHOCKWAVE_DELAY := 0.18
const GROUND_SHOCKWAVE_RADIUS_MULTIPLIER := 1.5
const GROUND_SHOCKWAVE_DAMAGE_MULTIPLIER := 0.5
const SEISMIC_FAN_RANGE_BONUS := 4.375
const SEISMIC_FAN_ANGLE := 68.0
const SEISMIC_FAN_DAMAGE_MULTIPLIER := 0.85

@export var attack_damage: int = 14
@export var attack_interval: float = 0.8
@export var targeting_range: float = 3.2
@export var attack_radius: float = 2.0
@export_range(1.0, 360.0, 1.0) var attack_arc: float = 110.0
@export var knockback_force: float = 5.0
@export var knockback_duration: float = 0.16

var _player: Player3D
var _enemy_container: Node3D
var _knight_visual: KnightVisual
var _effect_container: Node3D
var _cooldown_remaining: float = 0.0
var _attack_active: bool = false
var _attack_direction: Vector3 = Vector3.FORWARD
var _damaged_enemies: Array[Enemy3D] = []
var _damage_multiplier: float = 1.0
var _rage_ratio := 0.0
var _suspended: bool = false
var _attack_speed_modifiers: Dictionary = {}
var _fury_combo_enabled := false
var _fury_combo_bonus_per_stack := 0.0
var _fury_combo_stacks := 0
var _fury_combo_decay_remaining := 0.0
var _blood_frenzy_enabled := false
var _blood_frenzy_healing_per_enemy := 0
var _finishing_blow_enabled := false
var _finishing_blow_threshold := 0.0
var _selected_attack_evolutions: Array[String] = []
var _ground_shockwave_enabled := false
var _ground_shockwave_damage_multiplier := 0.0
var _ground_shockwave_radius_multiplier := 0.0
var _ground_shockwave_delay := 0.0
var _pending_impacts: Array[Dictionary] = []
var _next_pending_impact_sequence := 0

const FURY_COMBO_MAX_STACKS := 5
const FURY_COMBO_DECAY_DURATION := 3.0
const FINISHING_BLOW_THRESHOLD_CAP := 0.60
const FINISHING_BLOW_DAMAGE_MULTIPLIER := 1.45


func set_suspended(value: bool) -> void:
	_suspended = value


func is_suspended() -> bool:
	return _suspended


func cancel_current_attack() -> void:
	_attack_active = false
	_damaged_enemies.clear()
	if _player != null:
		_player.release_combat_facing()

func interrupt_attack() -> void:
	if _knight_visual != null:
		_knight_visual.cancel_attack()
	cancel_current_attack()

func set_damage_multiplier(multiplier: float) -> void:
	_damage_multiplier = maxf(multiplier, 0.0)


func set_rage_ratio(value: float) -> void:
	_rage_ratio = clampf(value, 0.0, 1.0)


func set_temporary_attack_speed_modifier(modifier_id: String, multiplier: float, duration: float) -> void:
	if modifier_id.is_empty():
		return
	_attack_speed_modifiers[modifier_id] = {"multiplier": maxf(multiplier, 0.01), "remaining": maxf(duration, 0.0)}


func clear_temporary_attack_speed_modifier(modifier_id: String) -> void:
	_attack_speed_modifiers.erase(modifier_id)


func upgrade_fury_combo(bonus_per_level: float) -> bool:
	if bonus_per_level <= 0.0:
		return false
	_fury_combo_enabled = true
	_fury_combo_bonus_per_stack += bonus_per_level
	return true


func upgrade_fury_strike_damage(damage_bonus: int) -> bool:
	if damage_bonus <= 0:
		return false
	attack_damage += damage_bonus
	return true


func upgrade_fury_tempo(interval_reduction: float, minimum_interval: float) -> bool:
	if interval_reduction <= 0.0 or minimum_interval <= 0.0:
		return false
	attack_interval = maxf(attack_interval - interval_reduction, minimum_interval)
	return true


func upgrade_fury_strike_impact(force_bonus: float) -> bool:
	if force_bonus <= 0.0:
		return false
	knockback_force += force_bonus
	return true


func upgrade_blood_frenzy(heal_per_enemy: float) -> bool:
	if heal_per_enemy <= 0.0:
		return false
	_blood_frenzy_enabled = true
	_blood_frenzy_healing_per_enemy += roundi(heal_per_enemy)
	return true


func upgrade_finishing_blow(threshold_bonus: float) -> bool:
	if threshold_bonus <= 0.0:
		return false
	_finishing_blow_enabled = true
	_finishing_blow_threshold = minf(_finishing_blow_threshold + threshold_bonus, FINISHING_BLOW_THRESHOLD_CAP)
	return true


func get_debug_state() -> Dictionary:
	return {"suspended": _suspended, "attack_active": _attack_active, "cooldown_remaining": _cooldown_remaining, "attack_direction": _attack_direction, "damage_multiplier": _damage_multiplier, "damaged_enemy_count": _damaged_enemies.size()}


func setup(player: Player3D, enemy_container: Node3D, knight_visual: KnightVisual, effect_container: Node3D = null) -> void:
	_player = player
	_enemy_container = enemy_container
	_knight_visual = knight_visual
	_effect_container = effect_container
	_reset_fury_combo(true)
	reset_attack_evolution_state()
	if _knight_visual != null and not _knight_visual.attack_impact.is_connected(_on_attack_impact):
		_knight_visual.attack_impact.connect(_on_attack_impact)
	if _knight_visual != null and not _knight_visual.attack_finished.is_connected(_on_attack_finished):
		_knight_visual.attack_finished.connect(_on_attack_finished)


func stop_attacking() -> void:
	_attack_active = false
	_damaged_enemies.clear()
	if _player != null:
		_player.release_combat_facing()
		_reset_fury_combo(true)
	_clear_pending_impacts()


func _process(delta: float) -> void:
	_process_attack_speed_modifiers(delta)
	_process_fury_combo(delta)
	_process_pending_impacts(delta)
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)
	if _suspended or _attack_active or _cooldown_remaining > 0.0 or _player == null or _player.is_dead() or get_tree().paused or not _player.action_controller.is_idle():
		return
	var target: Enemy3D = _find_nearest_target()
	if target == null:
		return
	_attack_direction = target.global_position - _player.global_position
	_attack_direction.y = 0.0
	if _attack_direction.is_zero_approx():
		return
	_attack_direction = _attack_direction.normalized()
	if _knight_visual != null and _knight_visual.play_attack():
		_attack_active = true
		_cooldown_remaining = _get_effective_attack_interval()
		_damaged_enemies.clear()
		_player.lock_combat_facing(_attack_direction)


func _find_nearest_target() -> Enemy3D:
	return CombatQuery3D.nearest_living_enemy(_enemy_container, _player.global_position, targeting_range)


func _on_attack_impact() -> void:
	if not _attack_active or _player == null or _enemy_container == null:
		return
	var hit_count := 0
	var total_damage := 0
	var effective_rage_multiplier := _damage_multiplier + (_rage_ratio * 1.35 if is_attack_evolution_active(CRUSHING_STORM_EVOLUTION_ID) else 0.0)
	var base_swing_damage := maxi(roundi(attack_damage * effective_rage_multiplier * _get_fury_combo_multiplier()), 1)
	for enemy: Enemy3D in CombatQuery3D.enemies_in_cone(_enemy_container, _player.global_position, _attack_direction, attack_radius, attack_arc):
		if enemy in _damaged_enemies:
			continue
		var offset := enemy.global_position - _player.global_position
		offset.y = 0.0
		_damaged_enemies.append(enemy)
		var damage := base_swing_damage
		var health_ratio := float(enemy.current_health) / maxf(float(enemy.max_health), 1.0)
		if _finishing_blow_enabled and health_ratio <= _finishing_blow_threshold:
			damage = maxi(roundi(float(damage) * FINISHING_BLOW_DAMAGE_MULTIPLIER), 1)
		enemy.take_damage(damage)
		enemy.apply_knockback(offset, knockback_force, knockback_duration)
		hit_count += 1
		total_damage += damage
	if hit_count > 0:
		_spawn_fury_strike_feedback(hit_count)
		_add_fury_combo_stack()
		if _blood_frenzy_enabled and _player != null:
			_player.heal(_blood_frenzy_healing_per_enemy * hit_count)
		if _ground_shockwave_enabled:
			_queue_ground_shockwave(_player.global_position)
		if is_attack_evolution_active(EARTHSPLITTER_EVOLUTION_ID):
			_apply_earthsplitter(_player.global_position, _attack_direction, base_swing_damage)
		if is_attack_evolution_active(CRUSHING_STORM_EVOLUTION_ID):
			_apply_crushing_storm(_player.global_position, base_swing_damage)
		if is_attack_evolution_active(SEISMIC_FAN_EVOLUTION_ID):
			_apply_seismic_fan(_player.global_position, _attack_direction, base_swing_damage)
	attack_impact_resolved.emit(hit_count, total_damage)


func _spawn_fury_strike_feedback(hit_count: int) -> void:
	if _effect_container == null or _player == null:
		return
	var effect := FURY_STRIKE_IMPACT_EFFECT.instantiate()
	_effect_container.add_child(effect)
	effect.setup(_player.global_position, _attack_direction, 0.38 + 0.05 * mini(hit_count, 4), hit_count > 1)


func can_apply_attack_evolution(evolution_id: String, target_attack_id: String) -> bool:
	if target_attack_id != "splash_melee" or is_attack_evolution_active(evolution_id):
		return false
	match evolution_id:
		EARTHSPLITTER_EVOLUTION_ID, CRUSHING_STORM_EVOLUTION_ID, SEISMIC_FAN_EVOLUTION_ID:
			return true
		_:
			return false


func apply_attack_evolution(evolution_id: String, target_attack_id: String) -> bool:
	if not can_apply_attack_evolution(evolution_id, target_attack_id):
		return false
	_selected_attack_evolutions.append(evolution_id)
	return true


func is_attack_evolution_active(evolution_id: String) -> bool:
	return evolution_id in _selected_attack_evolutions


func get_selected_attack_evolution_ids() -> Array[String]:
	return _selected_attack_evolutions.duplicate()


func get_primary_attack_display_name() -> String:
	if _selected_attack_evolutions.is_empty():
		return "Fury Strike"
	match _selected_attack_evolutions.back():
		EARTHSPLITTER_EVOLUTION_ID: return "Earthsplitter"
		CRUSHING_STORM_EVOLUTION_ID: return "Crushing Storm"
		SEISMIC_FAN_EVOLUTION_ID: return "Seismic Fan"
		_: return "Fury Strike"


func reset_attack_evolution_state() -> void:
	_selected_attack_evolutions.clear()
	_clear_pending_impacts()


func upgrade_legacy_ground_shockwave() -> bool:
	return upgrade_ground_shockwave(GROUND_SHOCKWAVE_DAMAGE_MULTIPLIER, GROUND_SHOCKWAVE_RADIUS_MULTIPLIER, GROUND_SHOCKWAVE_DELAY)


func upgrade_ground_shockwave(damage_multiplier: float, radius_multiplier: float, delay: float) -> bool:
	if damage_multiplier <= 0.0 or radius_multiplier <= 0.0 or delay <= 0.0:
		return false
	_ground_shockwave_enabled = true
	_ground_shockwave_damage_multiplier = damage_multiplier
	_ground_shockwave_radius_multiplier = radius_multiplier
	_ground_shockwave_delay = delay
	return true


func upgrade_legacy_wide_fury(radius_bonus: float) -> bool:
	if radius_bonus <= 0.0:
		return false
	attack_radius += radius_bonus
	return true


func _apply_earthsplitter(origin: Vector3, direction: Vector3, base_swing_damage: int) -> void:
	var damage := maxi(roundi(float(base_swing_damage) * EARTHSPLITTER_DAMAGE_MULTIPLIER), 1)
	for enemy: Enemy3D in CombatQuery3D.enemies_in_line(_enemy_container, origin, direction, EARTHSPLITTER_RANGE, EARTHSPLITTER_WIDTH):
		enemy.take_damage(damage)
	if _effect_container == null:
		return
	var effect := EARTHSPLITTER_EFFECT.instantiate()
	_effect_container.add_child(effect)
	effect.setup(origin, direction, EARTHSPLITTER_RANGE, EARTHSPLITTER_WIDTH, 0.22)


func _apply_crushing_storm(origin: Vector3, base_swing_damage: int) -> void:
	var radius := attack_radius * lerpf(1.55, 2.45, _rage_ratio)
	var damage := maxi(roundi(float(base_swing_damage) * lerpf(0.55, 1.15, _rage_ratio)), 1)
	var slow_multiplier := lerpf(0.62, 0.28, _rage_ratio)
	var slow_duration := 1.25 + _rage_ratio
	for enemy: Enemy3D in CombatQuery3D.enemies_in_radius(_enemy_container, origin, radius):
		enemy.take_damage(damage)
		enemy.apply_temporary_modifier("crushing_storm_pressure", {"movement_speed_multiplier": slow_multiplier}, slow_duration)
	if _effect_container == null:
		return
	var effect := CRUSHING_STORM_EFFECT.instantiate()
	_effect_container.add_child(effect)
	effect.setup(origin, radius, 0.24, _rage_ratio)


func _apply_seismic_fan(origin: Vector3, direction: Vector3, base_swing_damage: int) -> void:
	var maximum_range := attack_radius + SEISMIC_FAN_RANGE_BONUS
	var damage := maxi(roundi(float(base_swing_damage) * SEISMIC_FAN_DAMAGE_MULTIPLIER), 1)
	for enemy: Enemy3D in CombatQuery3D.enemies_in_cone(_enemy_container, origin, direction, maximum_range, SEISMIC_FAN_ANGLE):
		enemy.take_damage(damage)
	if _effect_container == null:
		return
	var effect := SEISMIC_FAN_EFFECT.instantiate()
	_effect_container.add_child(effect)
	effect.setup(origin, direction, maximum_range, 0.20)


func _queue_ground_shockwave(origin: Vector3) -> void:
	_next_pending_impact_sequence += 1
	_pending_impacts.append({
		"kind": "ground_shockwave",
		"remaining_delay": _ground_shockwave_delay,
		"sequence": _next_pending_impact_sequence,
		"origin": origin,
		"radius": attack_radius * _ground_shockwave_radius_multiplier,
		"damage": maxi(roundi(float(attack_damage) * _ground_shockwave_damage_multiplier), 1),
	})


func _process_pending_impacts(delta: float) -> void:
	var ready_impacts: Array[Dictionary] = []
	for index in range(_pending_impacts.size() - 1, -1, -1):
		var impact: Dictionary = _pending_impacts[index]
		impact["remaining_delay"] = float(impact["remaining_delay"]) - delta
		if float(impact["remaining_delay"]) <= 0.0:
			ready_impacts.append(impact)
			_pending_impacts.remove_at(index)
		else:
			_pending_impacts[index] = impact
	ready_impacts.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return int(left["sequence"]) < int(right["sequence"]))
	for impact: Dictionary in ready_impacts:
		if str(impact["kind"]) == "ground_shockwave":
			_resolve_ground_shockwave(impact)


func _resolve_ground_shockwave(impact: Dictionary) -> void:
	var origin: Vector3 = impact["origin"]
	var radius := float(impact["radius"])
	var damage := int(impact["damage"])
	for enemy: Enemy3D in CombatQuery3D.enemies_in_radius(_enemy_container, origin, radius):
		enemy.take_damage(damage)
	if _effect_container == null:
		return
	var effect := GROUND_SHOCKWAVE_EFFECT.instantiate()
	_effect_container.add_child(effect)
	effect.setup(origin, radius, 0.20)


func _clear_pending_impacts() -> void:
	_pending_impacts.clear()
	_next_pending_impact_sequence = 0


func _on_attack_finished() -> void:
	if not _attack_active:
		return
	_attack_active = false
	_damaged_enemies.clear()
	if _player != null:
		_player.release_combat_facing()


func _process_attack_speed_modifiers(delta: float) -> void:
	for modifier_id: String in _attack_speed_modifiers.keys():
		var modifier: Dictionary = _attack_speed_modifiers[modifier_id]
		modifier["remaining"] = float(modifier["remaining"]) - delta
		if float(modifier["remaining"]) <= 0.0:
			_attack_speed_modifiers.erase(modifier_id)
		else:
			_attack_speed_modifiers[modifier_id] = modifier


func _get_effective_attack_interval() -> float:
	var multiplier := 1.0
	for modifier: Dictionary in _attack_speed_modifiers.values():
		multiplier *= float(modifier.get("multiplier", 1.0))
	return attack_interval / maxf(multiplier, 0.01)


func _process_fury_combo(delta: float) -> void:
	if _fury_combo_stacks <= 0:
		return
	_fury_combo_decay_remaining = maxf(_fury_combo_decay_remaining - delta, 0.0)
	if _fury_combo_decay_remaining <= 0.0:
		_fury_combo_stacks = 0


func _add_fury_combo_stack() -> void:
	if not _fury_combo_enabled:
		return
	_fury_combo_stacks = mini(_fury_combo_stacks + 1, FURY_COMBO_MAX_STACKS)
	_fury_combo_decay_remaining = FURY_COMBO_DECAY_DURATION


func _get_fury_combo_multiplier() -> float:
	return 1.0 + float(_fury_combo_stacks) * _fury_combo_bonus_per_stack


func _reset_fury_combo(clear_upgrade: bool = false) -> void:
	_fury_combo_stacks = 0
	_fury_combo_decay_remaining = 0.0
	if clear_upgrade:
		_fury_combo_enabled = false
		_fury_combo_bonus_per_stack = 0.0
		_blood_frenzy_enabled = false
		_blood_frenzy_healing_per_enemy = 0
		_finishing_blow_enabled = false
		_finishing_blow_threshold = 0.0


func _exit_tree() -> void:
	_reset_fury_combo(true)
	reset_attack_evolution_state()
