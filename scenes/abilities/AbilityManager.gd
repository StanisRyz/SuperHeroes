extends Node

signal ability_cooldown_changed(slot: int, cooldown_remaining: float, cooldown_total: float)
signal ability_cast(slot: int, ability_id: String)

# Slot 1: Nova Pulse
@export var nova_damage: int = 18
@export var nova_radius: float = 220.0
@export var nova_cooldown: float = 6.0
@export var pulse_feedback_scene: PackedScene
@export var nova_aftershock_feedback_scene: PackedScene
@export var nova_aftershock_enabled: bool = false
@export var nova_aftershock_damage: int = 8
@export var nova_aftershock_radius: float = 180.0
@export var nova_aftershock_delay: float = 0.45

# Slot 2: Laser Beam
@export var laser_damage: int = 35
@export var laser_range: float = 520.0
@export var laser_width: float = 80.0
@export var laser_cooldown: float = 7.0
@export var laser_feedback_scene: PackedScene
@export var laser_double_pulse_enabled: bool = false
@export var laser_second_pulse_delay: float = 0.22
@export var laser_second_pulse_damage_multiplier: float = 0.55

# Slot 3: Hero Slam
@export var slam_damage: int = 45
@export var slam_radius: float = 180.0
@export var slam_cooldown: float = 9.0
@export var slam_feedback_scene: PackedScene
@export var slam_second_wave_enabled: bool = false
@export var slam_second_wave_delay: float = 0.35
@export var slam_second_wave_damage_multiplier: float = 0.55
@export var slam_second_wave_radius_multiplier: float = 1.25

var player: Node2D
var enemy_container: Node

var _cooldowns := {1: 0.0, 2: 0.0, 3: 0.0}
var _last_emitted := {1: -1.0, 2: -1.0, 3: -1.0}


func setup(new_player: Node2D, new_enemy_container: Node) -> void:
	player = new_player
	enemy_container = new_enemy_container
	_emit_cooldown_changed(1, true)
	_emit_cooldown_changed(2, true)
	_emit_cooldown_changed(3, true)


func _process(delta: float) -> void:
	for slot: int in _cooldowns.keys():
		if _cooldowns[slot] > 0.0:
			_cooldowns[slot] = maxf(_cooldowns[slot] - delta, 0.0)
			_emit_cooldown_changed(slot, false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ability_1"):
		cast_ability_1()
	elif event.is_action_pressed("ability_2"):
		cast_ability_2()
	elif event.is_action_pressed("ability_3"):
		cast_ability_3()


func cast_ability_1() -> void:
	_try_cast_nova_pulse()


func cast_ability_2() -> void:
	_try_cast_laser_beam()


func cast_ability_3() -> void:
	_try_cast_hero_slam()


func get_ability_state(slot: int) -> Dictionary:
	match slot:
		1:
			return {
				"id": "nova_pulse",
				"display_name": "Nova Pulse",
				"input_action": "ability_1",
				"cooldown_remaining": _cooldowns[1],
				"cooldown_total": nova_cooldown
			}
		2:
			return {
				"id": "laser_beam",
				"display_name": "Laser Beam",
				"input_action": "ability_2",
				"cooldown_remaining": _cooldowns[2],
				"cooldown_total": laser_cooldown
			}
		3:
			return {
				"id": "hero_slam",
				"display_name": "Hero Slam",
				"input_action": "ability_3",
				"cooldown_remaining": _cooldowns[3],
				"cooldown_total": slam_cooldown
			}
	return {}


func get_all_ability_states() -> Dictionary:
	return {1: get_ability_state(1), 2: get_ability_state(2), 3: get_ability_state(3)}


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
	if not _damage_enemies_in_radius_at(cast_position, nova_damage, nova_radius):
		return
	_spawn_pulse_feedback()
	if nova_aftershock_enabled:
		_schedule_nova_aftershock(cast_position)
	if player.has_method("shake_camera"):
		player.shake_camera(5.0, 0.14)
	_cooldowns[1] = maxf(nova_cooldown, 0.0)
	ability_cast.emit(1, "nova_pulse")
	_emit_cooldown_changed(1, true)


func _try_cast_laser_beam() -> void:
	if not _guard_cast(2):
		return
	var direction := _get_player_aim_direction()
	var origin := player.global_position
	if not _damage_enemies_in_laser(origin, direction, laser_damage, laser_range, laser_width):
		return
	_spawn_laser_feedback(direction)
	if laser_double_pulse_enabled:
		_schedule_laser_second_pulse(origin, direction)
	_cooldowns[2] = maxf(laser_cooldown, 0.0)
	ability_cast.emit(2, "laser_beam")
	_emit_cooldown_changed(2, true)


func _try_cast_hero_slam() -> void:
	if not _guard_cast(3):
		return
	var cast_position := player.global_position
	if not _damage_enemies_in_radius_at(cast_position, slam_damage, slam_radius):
		return
	_spawn_slam_feedback()
	if slam_second_wave_enabled:
		_schedule_slam_second_wave(cast_position)
	if player.has_method("shake_camera"):
		player.shake_camera(7.0, 0.18)
	_cooldowns[3] = maxf(slam_cooldown, 0.0)
	ability_cast.emit(3, "hero_slam")
	_emit_cooldown_changed(3, true)


func _damage_enemies_in_radius(damage: int, radius: float) -> bool:
	if player == null or not is_instance_valid(player):
		return false
	return _damage_enemies_in_radius_at(player.global_position, damage, radius)


func _damage_enemies_in_radius_at(world_position: Vector2, damage: int, radius: float) -> bool:
	if enemy_container == null or not is_instance_valid(enemy_container):
		push_warning("AbilityManager is missing EnemyContainer reference.")
		return false
	for enemy in enemy_container.get_children():
		if _is_valid_enemy(enemy) and world_position.distance_to(enemy.global_position) <= radius:
			enemy.take_damage(damage)
	return true


func _damage_enemies_in_laser(origin: Vector2, direction: Vector2, damage: int, beam_range: float, beam_width: float) -> bool:
	if enemy_container == null or not is_instance_valid(enemy_container):
		push_warning("AbilityManager is missing EnemyContainer reference.")
		return false
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
			enemy.take_damage(damage)
	return true


func _get_player_aim_direction() -> Vector2:
	if player != null and player.has_method("get_aim_direction"):
		return player.get_aim_direction()
	return Vector2.RIGHT


func _spawn_pulse_feedback() -> void:
	if pulse_feedback_scene == null:
		return
	var feedback_node := pulse_feedback_scene.instantiate()
	if not feedback_node is Node2D:
		push_warning("Nova Pulse feedback scene root must be Node2D.")
		feedback_node.queue_free()
		return
	var feedback := feedback_node as Node2D
	player.get_parent().add_child(feedback)
	feedback.global_position = player.global_position
	if feedback.has_method("play"):
		feedback.play(nova_radius)


func _spawn_laser_feedback(direction: Vector2) -> void:
	if laser_feedback_scene == null:
		return
	var feedback_node := laser_feedback_scene.instantiate()
	if not feedback_node is Node2D:
		push_warning("LaserBeam feedback scene root must be Node2D.")
		feedback_node.queue_free()
		return
	var feedback := feedback_node as Node2D
	player.get_parent().add_child(feedback)
	if feedback.has_method("play"):
		feedback.play(player.global_position, direction, laser_range, laser_width)


func _spawn_slam_feedback() -> void:
	if slam_feedback_scene == null:
		return
	var feedback_node := slam_feedback_scene.instantiate()
	if not feedback_node is Node2D:
		push_warning("HeroSlam feedback scene root must be Node2D.")
		feedback_node.queue_free()
		return
	var feedback := feedback_node as Node2D
	player.get_parent().add_child(feedback)
	if feedback.has_method("play"):
		feedback.play(player.global_position, slam_radius)


func _spawn_aftershock_feedback(world_position: Vector2, radius: float) -> void:
	if nova_aftershock_feedback_scene == null or player == null:
		return
	var feedback_node := nova_aftershock_feedback_scene.instantiate()
	if not feedback_node is Node2D:
		push_warning("Nova Aftershock feedback scene root must be Node2D.")
		feedback_node.queue_free()
		return
	var feedback := feedback_node as Node2D
	player.get_parent().add_child(feedback)
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
	if laser_feedback_scene == null or player == null:
		return
	var feedback_node := laser_feedback_scene.instantiate()
	if not feedback_node is Node2D:
		feedback_node.queue_free()
		return
	var feedback := feedback_node as Node2D
	player.get_parent().add_child(feedback)
	if feedback.has_method("play"):
		feedback.play(origin, direction, beam_range, beam_width)


func _spawn_slam_feedback_at(world_position: Vector2, radius: float) -> void:
	if slam_feedback_scene == null or player == null:
		return
	var feedback_node := slam_feedback_scene.instantiate()
	if not feedback_node is Node2D:
		feedback_node.queue_free()
		return
	var feedback := feedback_node as Node2D
	player.get_parent().add_child(feedback)
	if feedback.has_method("play"):
		feedback.play(world_position, radius)


func _is_valid_enemy(node: Node) -> bool:
	return (
		node is Node2D
		and is_instance_valid(node)
		and not node.is_queued_for_deletion()
		and node.has_method("take_damage")
	)


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
