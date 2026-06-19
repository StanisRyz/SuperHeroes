extends Node

signal phase_changed(phase: int)

@export var attack_cooldown: float = 3.0
@export var phase_two_health_ratio: float = 0.5
@export var nova_radius: float = 280.0
@export var nova_damage: int = 18
@export var projectile_barrage_count: int = 8
@export var max_projectile_barrage_count: int = 14
@export var projectile_damage: int = 10
@export var projectile_speed: float = 360.0
@export var charge_damage_multiplier: float = 1.5
@export var telegraph_scene: PackedScene
@export var enemy_projectile_scene: PackedScene

var enemy: Node2D = null
var player: Node2D = null
var projectile_parent: Node = null

var _cooldown_remaining: float = 2.0
var _current_phase: int = 1
var _is_attacking: bool = false
var _stopped: bool = false


func setup(new_enemy: Node2D, new_player: Node2D, new_projectile_parent: Node = null) -> void:
	enemy = new_enemy
	player = new_player
	projectile_parent = new_projectile_parent

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


func _process(delta: float) -> void:
	if _stopped or not _is_valid():
		return
	if enemy.is_dead():
		_stopped = true
		return

	_check_phase()

	if _is_attacking:
		return

	_cooldown_remaining -= delta
	if _cooldown_remaining <= 0.0:
		_is_attacking = true
		_run_attack_sequence()


func _check_phase() -> void:
	if _current_phase == 2:
		return
	if not is_instance_valid(enemy):
		return
	var max_hp_var = enemy.get("max_health")
	var cur_hp_var = enemy.get("current_health")
	var max_hp: int = max_hp_var if max_hp_var != null else 1
	var cur_hp: int = cur_hp_var if cur_hp_var != null else max_hp
	if max_hp > 0 and float(cur_hp) / float(max_hp) <= phase_two_health_ratio:
		_current_phase = 2
		phase_changed.emit(2)


func _run_attack_sequence() -> void:
	var attacks := ["nova", "barrage", "charge"]
	var chosen: String = attacks[randi() % attacks.size()]
	match chosen:
		"nova":
			await _attack_nova()
		"barrage":
			await _attack_barrage()
		"charge":
			await _attack_charge()

	if not _stopped and _is_valid() and not enemy.is_dead():
		var cd_mult := 0.7 if _current_phase == 2 else 1.0
		_cooldown_remaining = attack_cooldown * cd_mult
	_is_attacking = false


func _attack_nova() -> void:
	if not _is_valid():
		return

	var windup := 0.9
	var r := nova_radius if _current_phase == 1 else nova_radius * 1.25
	_spawn_telegraph_circle(enemy.global_position, r, windup)

	await get_tree().create_timer(windup).timeout
	if _stopped or not _is_valid() or enemy.is_dead():
		return

	var dist := enemy.global_position.distance_to(player.global_position)
	if dist <= r:
		player.take_damage(nova_damage)

	_spawn_telegraph_circle(enemy.global_position, r * 0.9, 0.25)
	await get_tree().create_timer(0.3).timeout


func _attack_barrage() -> void:
	if not _is_valid():
		return

	var count := projectile_barrage_count
	if _current_phase == 2:
		count = int(count * 1.5)
	count = clampi(count, 1, max_projectile_barrage_count)

	var angle_step := TAU / float(count)
	var aim_offset := 0.0
	if is_instance_valid(player):
		var dir_to_player := (player.global_position - enemy.global_position).normalized()
		aim_offset = dir_to_player.angle()

	var spd := projectile_speed if _current_phase == 1 else projectile_speed * 1.2
	for i in range(count):
		if _stopped or not _is_valid() or enemy.is_dead():
			break
		var angle := aim_offset + angle_step * float(i)
		var dir := Vector2(cos(angle), sin(angle))
		_fire_projectile(enemy.global_position, dir, spd)

	await get_tree().create_timer(0.2).timeout


func _attack_charge() -> void:
	if not _is_valid():
		return

	var dir_to_player := Vector2.RIGHT
	if is_instance_valid(player):
		var offset := player.global_position - enemy.global_position
		if not offset.is_zero_approx():
			dir_to_player = offset.normalized()

	var charge_distance := 500.0
	var from_pos := enemy.global_position
	var to_pos := from_pos + dir_to_player * charge_distance
	var windup := 0.6

	_spawn_telegraph_line(from_pos, to_pos, 28.0, windup)

	await get_tree().create_timer(windup).timeout
	if _stopped or not _is_valid() or enemy.is_dead():
		return

	var base_damage_var = enemy.get("contact_damage")
	var base_damage: int = base_damage_var if base_damage_var != null else 10
	var boosted_damage := int(base_damage * charge_damage_multiplier)
	var charge_speed := 640.0 if _current_phase == 1 else 800.0
	var charge_duration := 0.4

	if enemy.has_method("set_velocity_override"):
		enemy.set_velocity_override(dir_to_player * charge_speed)
	enemy.set("contact_damage", boosted_damage)

	await get_tree().create_timer(charge_duration).timeout

	if not _stopped and _is_valid() and not enemy.is_dead():
		if enemy.has_method("clear_velocity_override"):
			enemy.clear_velocity_override()
		enemy.set("contact_damage", base_damage)

	await get_tree().create_timer(0.1).timeout


func _spawn_telegraph_circle(world_pos: Vector2, radius: float, duration: float) -> void:
	if telegraph_scene == null:
		return
	var parent := _get_effect_parent()
	if parent == null:
		return
	var t := telegraph_scene.instantiate() as Node2D
	if t == null:
		push_warning("MinibossAttackController: AttackTelegraph root must be Node2D.")
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
		push_warning("MinibossAttackController: AttackTelegraph root must be Node2D.")
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
		push_warning("MinibossAttackController: EnemyProjectile root must be Node2D.")
		return
	parent.add_child(p)
	var target_pos := origin + direction * 800.0
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


func _on_enemy_died(_e: Node) -> void:
	_stopped = true
