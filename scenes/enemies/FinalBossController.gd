extends Node

signal phase_changed(phase: int)

@export var attack_cooldown: float = 2.5
@export var phase_two_health_ratio: float = 0.5
@export var phase_three_health_ratio: float = 0.25
@export var nova_radius: float = 340.0
@export var nova_damage: int = 26
@export var projectile_barrage_count: int = 12
@export var max_projectile_barrage_count: int = 20
@export var projectile_damage: int = 14
@export var projectile_speed: float = 400.0
@export var charge_damage_multiplier: float = 2.0
@export var telegraph_scene: PackedScene
@export var enemy_projectile_scene: PackedScene

var enemy: Node2D = null
var player: Node2D = null
var projectile_parent: Node = null
var boss_id: String = ""

var _cooldown_remaining: float = 0.0
var _current_phase: int = 1
var _encounter_state: String = "intro"
var _current_attack: String = ""
var _is_attacking: bool = false
var _stopped: bool = false
var _intro_timer: float = 0.0

const INTRO_DELAY := 1.8


func setup(new_enemy: Node2D, new_player: Node2D, new_projectile_parent: Node = null, new_boss_id: String = "") -> void:
	enemy = new_enemy
	player = new_player
	projectile_parent = new_projectile_parent
	boss_id = new_boss_id

	_apply_boss_variant_stats()

	if telegraph_scene == null:
		telegraph_scene = load("res://scenes/effects/AttackTelegraph.tscn")

	if enemy_projectile_scene == null and is_instance_valid(enemy):
		var ep = enemy.get("enemy_projectile_scene")
		if ep is PackedScene:
			enemy_projectile_scene = ep

	if enemy_projectile_scene == null:
		enemy_projectile_scene = load("res://scenes/projectiles/EnemyProjectile.tscn")

	if is_instance_valid(enemy) and enemy.has_signal("died"):
		if not enemy.died.is_connected(_on_enemy_died):
			enemy.died.connect(_on_enemy_died)


func _apply_boss_variant_stats() -> void:
	match boss_id:
		"titan_guardian":
			nova_radius = 340.0
			nova_damage = 28
			projectile_barrage_count = 10
			max_projectile_barrage_count = 16
			charge_damage_multiplier = 2.8
			attack_cooldown = 2.8
		"prism_overlord":
			projectile_barrage_count = 16
			max_projectile_barrage_count = 24
			projectile_damage = 12
			nova_radius = 280.0
			nova_damage = 20
			attack_cooldown = 2.0
		"molten_colossus":
			nova_radius = 390.0
			nova_damage = 34
			projectile_barrage_count = 8
			max_projectile_barrage_count = 14
			charge_damage_multiplier = 3.0
			attack_cooldown = 3.2


func _process(delta: float) -> void:
	if _stopped or not _is_valid():
		return
	if enemy.is_dead():
		_stopped = true
		_encounter_state = "defeated"
		return

	if _encounter_state == "intro":
		_intro_timer += delta
		if _intro_timer >= INTRO_DELAY:
			_encounter_state = "phase_1"
			_cooldown_remaining = 0.5
		return

	_check_phase()

	if _is_attacking:
		return

	_cooldown_remaining -= delta
	if _cooldown_remaining <= 0.0:
		_is_attacking = true
		_run_attack_sequence()


func _check_phase() -> void:
	if _current_phase >= 3:
		return
	if not is_instance_valid(enemy):
		return
	var max_hp: int = int(enemy.get("max_health") if enemy.get("max_health") != null else 1)
	var cur_hp: int = int(enemy.get("current_health") if enemy.get("current_health") != null else max_hp)
	if max_hp <= 0:
		return
	var ratio := float(cur_hp) / float(max_hp)
	if _current_phase == 1 and ratio <= phase_two_health_ratio:
		_current_phase = 2
		_encounter_state = "phase_2"
		phase_changed.emit(2)
	elif _current_phase == 2 and ratio <= phase_three_health_ratio:
		_current_phase = 3
		_encounter_state = "phase_3"
		phase_changed.emit(3)


func _get_attack_pool() -> Array[String]:
	match boss_id:
		"titan_guardian":
			match _current_phase:
				1: return ["nova", "charge", "nova"]
				2: return ["pulse_nova", "charge", "barrage"]
				3: return ["pulse_nova", "double_charge", "pulse_nova"]
		"prism_overlord":
			match _current_phase:
				1: return ["barrage", "aimed_barrage", "barrage"]
				2: return ["aimed_barrage", "barrage", "ring_barrage"]
				3: return ["aimed_barrage", "ring_barrage", "aimed_barrage"]
		"molten_colossus":
			match _current_phase:
				1: return ["nova", "charge", "nova"]
				2: return ["pulse_nova", "charge", "nova"]
				3: return ["pulse_nova", "double_charge", "nova"]
	return ["nova", "barrage", "charge"]


func _run_attack_sequence() -> void:
	var pool := _get_attack_pool()
	var chosen: String = pool[randi() % pool.size()]
	_current_attack = chosen

	match chosen:
		"nova":
			await _attack_nova()
		"barrage":
			await _attack_barrage()
		"charge":
			await _attack_charge()
		"aimed_barrage":
			await _attack_aimed_barrage()
		"ring_barrage":
			await _attack_ring_barrage()
		"double_charge":
			await _attack_double_charge()
		"pulse_nova":
			await _attack_pulse_nova()

	_current_attack = ""
	if not _stopped and _is_valid() and not enemy.is_dead():
		_cooldown_remaining = attack_cooldown * _get_cooldown_mult()
	_is_attacking = false


func _get_cooldown_mult() -> float:
	match _current_phase:
		3: return 0.5
		2: return 0.65
		_: return 1.0


func _attack_nova() -> void:
	if not _is_valid():
		return

	var windup := 0.85
	var r := nova_radius if _current_phase == 1 else nova_radius * 1.3
	_spawn_telegraph_circle(enemy.global_position, r, windup)

	await get_tree().create_timer(windup).timeout
	if _stopped or not _is_valid() or enemy.is_dead():
		return

	if enemy.global_position.distance_to(player.global_position) <= r:
		player.take_damage(nova_damage)

	_spawn_telegraph_circle(enemy.global_position, r * 0.85, 0.2)
	await get_tree().create_timer(0.25).timeout


func _attack_barrage() -> void:
	if not _is_valid():
		return

	var count := projectile_barrage_count
	if _current_phase == 2:
		count = int(count * 1.4)
	elif _current_phase == 3:
		count = int(count * 1.6)
	count = clampi(count, 1, max_projectile_barrage_count)

	var aim_offset := 0.0
	if is_instance_valid(player):
		aim_offset = (player.global_position - enemy.global_position).normalized().angle()

	var spd := projectile_speed
	if _current_phase == 2:
		spd = projectile_speed * 1.2
	elif _current_phase == 3:
		spd = projectile_speed * 1.35

	var angle_step := TAU / float(count)
	for i in range(count):
		if _stopped or not _is_valid() or enemy.is_dead():
			break
		var angle := aim_offset + angle_step * float(i)
		_fire_projectile(enemy.global_position, Vector2(cos(angle), sin(angle)), spd)

	await get_tree().create_timer(0.15).timeout


func _attack_charge() -> void:
	if not _is_valid():
		return

	var dir := _get_dir_to_player()
	var from_pos := enemy.global_position
	var to_pos := from_pos + dir * 600.0
	var windup := 0.55

	_spawn_telegraph_line(from_pos, to_pos, 36.0, windup)

	await get_tree().create_timer(windup).timeout
	if _stopped or not _is_valid() or enemy.is_dead():
		return

	var base_damage: int = int(enemy.get("contact_damage") if enemy.get("contact_damage") != null else 10)
	var boosted := int(base_damage * charge_damage_multiplier)
	var charge_speed := 850.0 if _current_phase == 1 else 1050.0

	if enemy.has_method("set_velocity_override"):
		enemy.set_velocity_override(dir * charge_speed)
	enemy.set("contact_damage", boosted)

	await get_tree().create_timer(0.38).timeout

	if not _stopped and _is_valid() and not enemy.is_dead():
		if enemy.has_method("clear_velocity_override"):
			enemy.clear_velocity_override()
		enemy.set("contact_damage", base_damage)

	await get_tree().create_timer(0.1).timeout


func _attack_aimed_barrage() -> void:
	if not _is_valid():
		return

	var dir := _get_dir_to_player()
	var windup := 0.75
	_spawn_telegraph_line(enemy.global_position, enemy.global_position + dir * 700.0, 28.0, windup)

	await get_tree().create_timer(windup).timeout
	if _stopped or not _is_valid() or enemy.is_dead():
		return

	var wave_count := 3
	var projs_per_wave := 7 if boss_id == "prism_overlord" else 5
	var spread := deg_to_rad(22.0)
	var spd := projectile_speed * 1.1

	for wave in range(wave_count):
		if _stopped or not _is_valid() or enemy.is_dead():
			break
		var base_angle := _get_dir_to_player().angle()
		for i in range(projs_per_wave):
			var angle := base_angle + spread * (float(i) / float(projs_per_wave - 1) - 0.5)
			_fire_projectile(enemy.global_position, Vector2(cos(angle), sin(angle)), spd)
		if wave < wave_count - 1:
			await get_tree().create_timer(0.3).timeout
			if _stopped or not _is_valid() or enemy.is_dead():
				break

	await get_tree().create_timer(0.1).timeout


func _attack_ring_barrage() -> void:
	if not _is_valid():
		return

	var windup := 0.9
	_spawn_telegraph_circle(enemy.global_position, 360.0, windup)

	await get_tree().create_timer(windup).timeout
	if _stopped or not _is_valid() or enemy.is_dead():
		return

	var total_slots := 20
	var offset_angle := randf_range(0.0, TAU)
	var spd := projectile_speed * 0.85

	for i in range(total_slots):
		if i % 2 == 1:
			continue
		var angle := offset_angle + (TAU / float(total_slots)) * float(i)
		_fire_projectile(enemy.global_position, Vector2(cos(angle), sin(angle)), spd)

	await get_tree().create_timer(0.2).timeout


func _attack_double_charge() -> void:
	if not _is_valid():
		return

	var base_damage: int = int(enemy.get("contact_damage") if enemy.get("contact_damage") != null else 10)
	var boosted := int(base_damage * charge_damage_multiplier)

	for charge_idx in range(2):
		if _stopped or not _is_valid() or enemy.is_dead():
			break

		var dir := _get_dir_to_player()
		var from_pos := enemy.global_position
		var to_pos := from_pos + dir * 600.0
		var windup := 0.5 if charge_idx == 0 else 0.45

		_spawn_telegraph_line(from_pos, to_pos, 32.0, windup)

		await get_tree().create_timer(windup).timeout
		if _stopped or not _is_valid() or enemy.is_dead():
			break

		if enemy.has_method("set_velocity_override"):
			enemy.set_velocity_override(dir * 880.0)
		enemy.set("contact_damage", boosted)

		await get_tree().create_timer(0.32).timeout

		if not _stopped and _is_valid() and not enemy.is_dead():
			if enemy.has_method("clear_velocity_override"):
				enemy.clear_velocity_override()
			enemy.set("contact_damage", base_damage)

		if charge_idx == 0:
			await get_tree().create_timer(0.4).timeout

	await get_tree().create_timer(0.1).timeout


func _attack_pulse_nova() -> void:
	if not _is_valid():
		return

	var small_r := nova_radius * 0.55
	var large_r := nova_radius * 1.45
	var windup1 := 0.65

	_spawn_telegraph_circle(enemy.global_position, small_r, windup1)

	await get_tree().create_timer(windup1).timeout
	if _stopped or not _is_valid() or enemy.is_dead():
		return

	if enemy.global_position.distance_to(player.global_position) <= small_r:
		player.take_damage(int(nova_damage * 0.65))

	_spawn_telegraph_circle(enemy.global_position, small_r * 0.85, 0.2)

	await get_tree().create_timer(0.6).timeout
	if _stopped or not _is_valid() or enemy.is_dead():
		return

	_spawn_telegraph_circle(enemy.global_position, large_r, 0.75)

	await get_tree().create_timer(0.75).timeout
	if _stopped or not _is_valid() or enemy.is_dead():
		return

	if enemy.global_position.distance_to(player.global_position) <= large_r:
		player.take_damage(nova_damage)

	_spawn_telegraph_circle(enemy.global_position, large_r * 0.85, 0.2)
	await get_tree().create_timer(0.25).timeout


func _get_dir_to_player() -> Vector2:
	if is_instance_valid(player):
		var offset := player.global_position - enemy.global_position
		if not offset.is_zero_approx():
			return offset.normalized()
	return Vector2.RIGHT


func _spawn_telegraph_circle(world_pos: Vector2, radius: float, duration: float) -> void:
	if telegraph_scene == null:
		return
	var parent := _get_effect_parent()
	if parent == null:
		return
	var t := telegraph_scene.instantiate() as Node2D
	if t == null:
		push_warning("FinalBossController: AttackTelegraph root must be Node2D.")
		return
	parent.add_child(t)
	if t.has_method("play_circle"):
		t.play_circle(world_pos, radius, duration)
	else:
		t.queue_free()


func _spawn_telegraph_line(from_pos: Vector2, to_pos: Vector2, width: float, duration: float) -> void:
	if telegraph_scene == null:
		return
	var parent := _get_effect_parent()
	if parent == null:
		return
	var t := telegraph_scene.instantiate() as Node2D
	if t == null:
		push_warning("FinalBossController: AttackTelegraph root must be Node2D.")
		return
	parent.add_child(t)
	if t.has_method("play_line"):
		t.play_line(from_pos, to_pos, width, duration)
	else:
		t.queue_free()


func _fire_projectile(origin: Vector2, direction: Vector2, spd: float) -> void:
	if enemy_projectile_scene == null:
		return
	var parent := _get_effect_parent()
	if parent == null:
		return
	var p := enemy_projectile_scene.instantiate() as Node2D
	if p == null:
		push_warning("FinalBossController: EnemyProjectile root must be Node2D.")
		return
	parent.add_child(p)
	var target_pos := origin + direction * 900.0
	if p.has_method("setup"):
		p.setup(origin, target_pos, projectile_damage, spd)
	else:
		p.global_position = origin


func _get_effect_parent() -> Node:
	if projectile_parent != null and is_instance_valid(projectile_parent):
		return projectile_parent
	if is_instance_valid(enemy):
		var ep := enemy.get_parent()
		if ep != null:
			var grandparent := ep.get_parent()
			return grandparent if grandparent != null else ep
	return null


func _is_valid() -> bool:
	return is_instance_valid(enemy) and is_instance_valid(player)


func _get_hp_ratio() -> float:
	if not is_instance_valid(enemy):
		return 0.0
	var max_hp: int = int(enemy.get("max_health") if enemy.get("max_health") != null else 1)
	var cur_hp: int = int(enemy.get("current_health") if enemy.get("current_health") != null else max_hp)
	if max_hp <= 0:
		return 0.0
	return float(cur_hp) / float(max_hp)


func stop() -> void:
	_stopped = true
	_encounter_state = "defeated"


func debug_get_boss_state() -> Dictionary:
	return {
		"boss_id": boss_id,
		"encounter_state": _encounter_state,
		"phase": _current_phase,
		"current_attack": _current_attack,
		"cooldown_remaining": _cooldown_remaining,
		"is_attacking": _is_attacking,
		"stopped": _stopped,
		"hp_ratio": _get_hp_ratio(),
	}


func _on_enemy_died(_e: Node) -> void:
	_stopped = true
	_encounter_state = "defeated"
