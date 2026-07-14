class_name SolarRayAutoAttack3D
extends Node

signal attack_impact_resolved(hit_count: int, total_damage: int)
const BOLT_EFFECT := preload("res://scenes3d/effects/CrossbowBoltEffect3D.tscn")

@export var attack_damage := 7
@export var attack_interval := 0.6
@export var targeting_range := 6.5
@export var corridor_width := 1.0
var _player: Player3D
var _enemy_container: Node3D
var _visual: Node
var _energy: SolarEnergy3D
var _effect_container: Node3D
var _cooldown := 0.0
var _active := false
var _direction := Vector3.FORWARD
var _attack_speed_modifiers: Dictionary = {}
var _action_token := 0

func setup(player: Player3D, enemy_container: Node3D, visual: Node, effect_container: Node3D = null, energy: SolarEnergy3D = null) -> void:
	_player = player; _enemy_container = enemy_container; _visual = visual; _effect_container = effect_container; _energy = energy

func _process(delta: float) -> void:
	for modifier_id: String in _attack_speed_modifiers.keys():
		var modifier: Dictionary = _attack_speed_modifiers[modifier_id]
		modifier["remaining"] = float(modifier["remaining"]) - delta
		if float(modifier["remaining"]) <= 0.0: _attack_speed_modifiers.erase(modifier_id)
		else: _attack_speed_modifiers[modifier_id] = modifier
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _active or _cooldown > 0.0 or _player == null or _player.is_dead() or get_tree().paused or not _player.action_controller.is_idle() or _player.is_dashing:
		return
	var target: Enemy3D = CombatQuery3D.nearest_living_enemy(_enemy_container, _player.global_position, targeting_range)
	if target == null: return
	_direction = target.global_position - _player.global_position; _direction.y = 0.0
	if _direction.is_zero_approx(): return
	_direction = _direction.normalized()
	_action_token = int(_player.action_controller.try_begin_autoattack())
	if _action_token == 0: return
	_active = true; _player.lock_combat_facing(_direction)
	if _visual != null and _visual.has_method("play_attack"): _visual.play_attack()
	_spawn_bolt()
	_resolve_attack()

func _resolve_attack() -> void:
	var hits := 0; var damage_total := 0
	var multiplier := _energy.get_damage_multiplier() if _energy != null else 1.0
	for enemy: Enemy3D in CombatQuery3D.enemies_in_line(_enemy_container, _player.global_position, _direction, targeting_range, corridor_width):
		var damage := maxi(roundi(float(attack_damage) * multiplier), 1)
		enemy.take_damage(damage); hits += 1; damage_total += damage
	attack_impact_resolved.emit(hits, damage_total)
	_active = false; _cooldown = _effective_interval(); _player.release_combat_facing()
	if _action_token != 0: _player.action_controller.finish_action(_action_token)
	_action_token = 0

func stop_attacking() -> void:
	_active = false; _cooldown = 0.0
	if _player != null: _player.release_combat_facing()
	if _player != null and _action_token != 0: _player.action_controller.cancel_action(_action_token, "stop")
	_action_token = 0

func get_primary_attack_display_name() -> String: return "Solar Ray"
func get_selected_attack_evolution_ids() -> Array[String]: return []
func set_temporary_attack_speed_modifier(modifier_id: String, multiplier: float, duration: float) -> void: _attack_speed_modifiers[modifier_id] = {"multiplier": maxf(multiplier, 0.01), "remaining": maxf(duration, 0.0)}
func clear_temporary_attack_speed_modifier(modifier_id: String) -> void: _attack_speed_modifiers.erase(modifier_id)
func _effective_interval() -> float:
	var multiplier := 1.0
	for modifier: Dictionary in _attack_speed_modifiers.values(): multiplier *= float(modifier.get("multiplier", 1.0))
	return attack_interval / maxf(multiplier, 0.01)

func _spawn_bolt() -> void:
	if _effect_container == null: return
	var bolt := BOLT_EFFECT.instantiate()
	_effect_container.add_child(bolt)
	var muzzle := _visual.get_node_or_null("Muzzle") as Marker3D if _visual != null else null
	bolt.setup(muzzle.global_position if muzzle != null else _player.global_position + Vector3.UP, _direction)
