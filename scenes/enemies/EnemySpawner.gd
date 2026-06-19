extends Node

signal miniboss_spawned(enemy: Node)
signal miniboss_phase_changed(phase: int)
signal miniboss_defeated

const NO_SPAWN_POSITION := Vector2(1.0e20, 1.0e20)

@export var enemy_scene: PackedScene
@export var experience_gem_scene: PackedScene
@export var death_burst_scene: PackedScene
@export var powerup_pickup_scene: PackedScene
@export var spawn_interval: float = 1.5
@export var max_alive_enemies: int = 12
@export var min_spawn_distance_from_player: float = 320.0
@export var max_spawn_distance_from_player: float = 900.0
@export var max_alive_enemies_cap: int = 60
@export var max_spawn_attempts: int = 12
@export var base_powerup_drop_chance: float = 0.06
@export var powerup_debug_logging: bool = false
@export var spawn_debug_logging: bool = false

var player: Node2D
var playable_rect: Rect2
var enemy_container: Node
var pickup_container: Node
var projectile_container: Node
var run_manager: Node
var spawn_director: Node
var floating_text_spawner: Node
var audio_manager: Node
var powerup_manager: Node

const POWERUP_WEIGHTS: Dictionary = {
	"heal": 30,
	"shield": 20,
	"bomb": 15,
	"magnet_burst": 15,
	"move_speed_boost": 10,
	"attack_speed_boost": 10,
}

@onready var spawn_timer: Timer = $SpawnTimer

func _ready() -> void:
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false


func setup(new_player: Node2D, new_playable_rect: Rect2, new_enemy_container: Node, new_pickup_container: Node = null, new_run_manager: Node = null, new_spawn_director: Node = null, new_floating_text_spawner: Node = null, new_audio_manager: Node = null, new_powerup_manager: Node = null, new_projectile_container: Node = null) -> void:
	player = new_player
	playable_rect = new_playable_rect
	enemy_container = new_enemy_container
	pickup_container = new_pickup_container
	projectile_container = new_projectile_container
	run_manager = new_run_manager
	spawn_director = new_spawn_director
	floating_text_spawner = new_floating_text_spawner
	audio_manager = new_audio_manager
	powerup_manager = new_powerup_manager

	if powerup_debug_logging:
		print("POWERUP_WIRING: pickup_scene=%s manager=%s drop_chance=%s" % [
			powerup_pickup_scene != null,
			powerup_manager != null,
			base_powerup_drop_chance
		])

	spawn_timer.wait_time = _get_current_spawn_interval()
	if _can_spawn():
		spawn_timer.start()


func _on_spawn_timer_timeout() -> void:
	if not _can_spawn():
		return

	spawn_timer.wait_time = _get_current_spawn_interval()
	if enemy_container.get_child_count() >= _get_current_max_alive_enemies():
		return

	var spawn_position: Vector2 = _find_spawn_position()
	if spawn_position == NO_SPAWN_POSITION:
		return

	var variant := _get_enemy_variant()
	_spawn_enemy_with_variant(variant, spawn_position)
	if spawn_debug_logging:
		print("SPAWN: variant=%s alive=%d/%d interval=%.2f" % [
			str(variant.get("id", "default")),
			enemy_container.get_child_count(),
			_get_current_max_alive_enemies(),
			_get_current_spawn_interval(),
		])


func _spawn_enemy_with_variant(variant: Dictionary, spawn_position: Vector2) -> Node2D:
	if enemy_scene == null:
		push_warning("EnemySpawner enemy_scene is not set.")
		return null

	var enemy_node := enemy_scene.instantiate()
	if not enemy_node is Node2D:
		push_warning("EnemySpawner enemy_scene root must be Node2D.")
		enemy_node.queue_free()
		return null

	var enemy := enemy_node as Node2D
	enemy_container.add_child(enemy)
	enemy.global_position = spawn_position
	enemy.add_to_group("enemies")

	if not variant.is_empty() and enemy.has_method("apply_variant"):
		enemy.apply_variant(variant)

	if enemy.has_method("set_target"):
		enemy.set_target(player)
	else:
		push_warning("Spawned enemy does not implement set_target(new_target).")

	if enemy.has_signal("died"):
		if not enemy.died.is_connected(_on_enemy_died):
			enemy.died.connect(_on_enemy_died)

	if enemy.has_signal("damage_taken") and floating_text_spawner != null and floating_text_spawner.has_method("show_damage"):
		if not enemy.damage_taken.is_connected(floating_text_spawner.show_damage):
			enemy.damage_taken.connect(floating_text_spawner.show_damage)

	return enemy


func spawn_elite_enemy(_event_data: Dictionary = {}) -> void:
	var variant := _get_enemy_variant()
	var pos := _find_spawn_position()
	if pos == NO_SPAWN_POSITION:
		return
	var enemy := _spawn_enemy_with_variant(variant, pos)
	if enemy and enemy.has_method("apply_special_modifier"):
		enemy.apply_special_modifier({
			"is_elite": true,
			"display_name": "Elite " + variant.get("display_name", "Enemy"),
			"health_multiplier": 3.0,
			"speed_multiplier": 1.0,
			"damage_multiplier": 1.2,
			"scale_multiplier": 1.1,
			"xp_multiplier": 3.0,
			"guaranteed_powerup": true,
			"color_override": Color(1.0, 0.4, 0.0)
		})


func spawn_miniboss_enemy(_event_data: Dictionary = {}) -> void:
	var variant := _get_enemy_variant()
	var pos := _find_spawn_position()
	if pos == NO_SPAWN_POSITION:
		return
	var enemy := _spawn_enemy_with_variant(variant, pos)
	if enemy and enemy.has_method("apply_special_modifier"):
		enemy.apply_special_modifier({
			"is_miniboss": true,
			"display_name": "Miniboss",
			"health_multiplier": 12.0,
			"speed_multiplier": 0.8,
			"damage_multiplier": 2.0,
			"scale_multiplier": 2.0,
			"xp_multiplier": 10.0,
			"guaranteed_powerup": true,
			"color_override": Color(0.6, 0.0, 1.0)
		})
	if enemy:
		emit_signal("miniboss_spawned", enemy)
		_attach_miniboss_controller(enemy)


func _attach_miniboss_controller(enemy: Node) -> void:
	var controller_scene: PackedScene = load("res://scenes/enemies/MinibossAttackController.tscn")
	if controller_scene == null:
		push_warning("EnemySpawner: MinibossAttackController.tscn not found.")
		return

	var controller := controller_scene.instantiate()
	if not controller.has_method("setup"):
		push_warning("EnemySpawner: MinibossAttackController missing setup().")
		controller.queue_free()
		return

	var proj_parent: Node = projectile_container if projectile_container != null and is_instance_valid(projectile_container) else enemy_container
	controller.setup(enemy as Node2D, player, proj_parent)

	if controller.has_signal("phase_changed"):
		controller.phase_changed.connect(func(p: int): emit_signal("miniboss_phase_changed", p))

	enemy.add_child(controller)


func _on_enemy_died(enemy: Node) -> void:
	if audio_manager != null and audio_manager.has_method("play_enemy_death"):
		audio_manager.play_enemy_death()

	if run_manager != null and run_manager.has_method("register_enemy_kill"):
		run_manager.register_enemy_kill()

	if enemy != null and enemy.get("is_elite") == true:
		if run_manager != null and run_manager.has_method("register_elite_kill"):
			run_manager.register_elite_kill()

	if enemy != null and enemy.get("is_miniboss") == true:
		if run_manager != null and run_manager.has_method("register_miniboss_kill"):
			run_manager.register_miniboss_kill()
		emit_signal("miniboss_defeated")

	var dropped_experience := 1
	if enemy != null and enemy.has_method("get_experience_value"):
		dropped_experience = int(enemy.get_experience_value())

	var enemy_node := enemy as Node2D
	if enemy_node == null:
		return

	var guaranteed: bool = enemy.get("guaranteed_powerup") == true or enemy.get("is_elite") == true or enemy.get("is_miniboss") == true
	var powerup_id := _roll_powerup_id(guaranteed)
	if guaranteed and powerup_id == "":
		powerup_id = "heal"
	if powerup_debug_logging:
		print("POWERUP_ROLL: guaranteed=%s dropped=%s" % [guaranteed, powerup_id if powerup_id != "" else "(none)"])
	call_deferred("_spawn_death_feedback_and_drop", enemy_node.global_position, dropped_experience, powerup_id)


func _spawn_death_feedback_and_drop(world_position: Vector2, dropped_experience: int, powerup_id: String = "") -> void:
	_spawn_death_burst(world_position)

	if experience_gem_scene == null or not is_instance_valid(pickup_container):
		return

	var gem_node := experience_gem_scene.instantiate()
	if not gem_node is Node2D:
		push_warning("EnemySpawner experience_gem_scene root must be Node2D.")
		gem_node.queue_free()
		return

	var gem := gem_node as Node2D
	if "experience_value" in gem:
		gem.experience_value = dropped_experience
	if gem.has_method("setup_audio_manager"):
		gem.setup_audio_manager(audio_manager)

	pickup_container.add_child(gem)
	gem.global_position = world_position

	if powerup_id != "":
		_spawn_powerup_pickup(world_position, powerup_id)


func _spawn_powerup_pickup(world_position: Vector2, powerup_id: String) -> void:
	if powerup_pickup_scene == null:
		if powerup_debug_logging:
			push_warning("POWERUP_SPAWN: powerup_pickup_scene is null — assign it in EnemySpawner.tscn.")
		return
	if powerup_manager == null:
		if powerup_debug_logging:
			push_warning("POWERUP_SPAWN: powerup_manager is null — not passed in setup().")
		return
	if not is_instance_valid(pickup_container):
		if powerup_debug_logging:
			push_warning("POWERUP_SPAWN: pickup_container is invalid.")
		return

	var pickup_node := powerup_pickup_scene.instantiate()
	if not pickup_node is Node2D:
		push_warning("POWERUP_SPAWN: powerup_pickup_scene root must be Node2D.")
		pickup_node.queue_free()
		return

	var pickup := pickup_node as Node2D
	pickup_container.add_child(pickup)
	var offset := Vector2(randf_range(-28.0, 28.0), randf_range(-28.0, 28.0))
	pickup.global_position = world_position + offset
	if pickup.has_method("setup"):
		pickup.setup(powerup_id, powerup_manager)
	if powerup_debug_logging:
		print("POWERUP_SPAWNED: id=%s position=%s" % [powerup_id, pickup.global_position])


func debug_spawn_powerup(powerup_id: String = "heal") -> void:
	if powerup_debug_logging:
		print("POWERUP_DEBUG: debug_spawn_powerup called id=%s" % powerup_id)
	if not is_instance_valid(player):
		push_warning("POWERUP_DEBUG: player not valid, cannot spawn.")
		return
	var spawn_pos := player.global_position + Vector2(60.0, 0.0)
	_spawn_powerup_pickup(spawn_pos, powerup_id)


func debug_spawn_enemy_variant(variant_id: String) -> void:
	if not _can_spawn():
		push_warning("EnemySpawner: cannot debug spawn enemy variant right now.")
		return

	var variant := {}
	if spawn_director != null and spawn_director.has_method("get_enemy_variant_by_id"):
		variant = spawn_director.get_enemy_variant_by_id(variant_id)
	if not variant is Dictionary or variant.is_empty():
		push_warning("EnemySpawner: unknown debug enemy variant: %s" % variant_id)
		return

	var pos := _find_spawn_position()
	if pos == NO_SPAWN_POSITION:
		return

	_spawn_enemy_with_variant(variant, pos)


func debug_get_powerup_wiring_state() -> Dictionary:
	return {
		"pickup_scene_assigned": powerup_pickup_scene != null,
		"powerup_manager_assigned": powerup_manager != null,
		"pickup_container_valid": is_instance_valid(pickup_container),
		"drop_chance": base_powerup_drop_chance,
	}


func debug_get_spawn_state() -> Dictionary:
	return {
		"enemy_count": enemy_container.get_child_count() if is_instance_valid(enemy_container) else 0,
		"max_alive_enemies": _get_current_max_alive_enemies(),
		"spawn_interval": _get_current_spawn_interval(),
		"min_spawn_distance": min_spawn_distance_from_player,
		"max_spawn_distance": max_spawn_distance_from_player,
	}


func _roll_powerup_id(guaranteed: bool = false) -> String:
	if not guaranteed and randf() > base_powerup_drop_chance:
		return ""

	var total_weight := 0
	for weight in POWERUP_WEIGHTS.values():
		total_weight += weight

	var roll := randi() % total_weight
	var accumulated := 0
	for pid in POWERUP_WEIGHTS:
		accumulated += POWERUP_WEIGHTS[pid]
		if roll < accumulated:
			return pid

	return ""


func _spawn_death_burst(world_position: Vector2) -> void:
	if death_burst_scene == null:
		return

	var burst_node := death_burst_scene.instantiate()
	if not burst_node is Node2D:
		push_warning("DeathBurst scene root must be Node2D.")
		burst_node.queue_free()
		return

	var burst := burst_node as Node2D
	var effect_parent := enemy_container.get_parent() if enemy_container != null else null
	if effect_parent == null:
		burst.queue_free()
		return

	effect_parent.add_child(burst)
	if burst.has_method("play"):
		burst.play(world_position, Color(1.0, 0.35, 0.28, 1.0))
	else:
		burst.global_position = world_position


func _can_spawn() -> bool:
	if run_manager != null and run_manager.get("is_run_active") == false:
		return false

	return enemy_scene != null and is_instance_valid(player) and is_instance_valid(enemy_container)


func _find_spawn_position() -> Vector2:
	if is_instance_valid(player):
		for attempt in range(max_spawn_attempts):
			var angle := randf_range(0.0, TAU)
			var distance := randf_range(min_spawn_distance_from_player, max_spawn_distance_from_player)
			var point := player.global_position + Vector2.RIGHT.rotated(angle) * distance
			point = _clamp_point_to_playable_rect(point)
			if point.distance_to(player.global_position) >= min_spawn_distance_from_player:
				return point

	for attempt in range(max_spawn_attempts):
		var point := Vector2(
			randf_range(playable_rect.position.x, playable_rect.end.x),
			randf_range(playable_rect.position.y, playable_rect.end.y)
		)

		if point.distance_to(player.global_position) >= min_spawn_distance_from_player:
			return point

	return NO_SPAWN_POSITION


func _clamp_point_to_playable_rect(point: Vector2) -> Vector2:
	return Vector2(
		clampf(point.x, playable_rect.position.x, playable_rect.end.x),
		clampf(point.y, playable_rect.position.y, playable_rect.end.y)
	)


func _get_current_spawn_interval() -> float:
	if spawn_director != null and spawn_director.has_method("get_spawn_interval"):
		return maxf(float(spawn_director.get_spawn_interval()), 0.05)

	return spawn_interval


func _get_current_max_alive_enemies() -> int:
	var cap := maxi(max_alive_enemies_cap, 0)
	if spawn_director != null and spawn_director.has_method("get_max_alive_enemies"):
		return mini(maxi(int(spawn_director.get_max_alive_enemies()), 0), cap)

	return mini(max_alive_enemies, cap)


func _get_enemy_variant() -> Dictionary:
	if spawn_director != null and spawn_director.has_method("get_enemy_variant"):
		var variant = spawn_director.get_enemy_variant()
		if variant is Dictionary:
			return variant

	return {}
