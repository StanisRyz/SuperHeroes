extends Node

@export_group("Debug Logging")
@export var enable_debug_input_logs: bool = false
@export var enable_powerup_logs: bool = false
@export var enable_spawn_logs: bool = false

@export_group("Run")
@export var target_run_time: float = 600.0
@export var final_phase_start_time: float = 540.0

@export_group("Spawning")
@export var min_spawn_distance_from_player: float = 320.0
@export var max_spawn_distance_from_player: float = 900.0
@export var max_alive_enemies_cap: int = 60

@export_group("Powerups")
@export var base_powerup_drop_chance: float = 0.06

@export_group("Abilities")
@export var nova_damage: int = 18
@export var nova_cooldown: float = 6.0
@export var laser_damage: int = 35
@export var laser_cooldown: float = 7.0
@export var slam_damage: int = 45
@export var slam_cooldown: float = 9.0

@export_group("Player")
@export var default_speed: float = 260.0
@export var default_max_health: int = 100


func apply_to(arena: Node) -> void:
	if arena == null:
		return

	_set_if_present(arena, "debug_input_logging", enable_debug_input_logs)

	var player := _get_child(arena, "Player")
	_set_if_present(player, "speed", default_speed)
	_set_if_present(player, "max_health", default_max_health)
	if player != null and player.get("current_health") != null:
		player.set("current_health", mini(int(player.get("current_health")), default_max_health))
		if player.has_signal("health_changed"):
			player.health_changed.emit(int(player.get("current_health")), default_max_health)
	_set_if_present(player, "debug_player_logging", enable_debug_input_logs)

	var run_manager := _get_child(arena, "RunManager")
	if run_manager != null and run_manager.has_method("apply_run_tuning"):
		run_manager.apply_run_tuning(target_run_time, final_phase_start_time)
	else:
		_set_if_present(run_manager, "target_run_time", target_run_time)
		_set_if_present(run_manager, "final_phase_start_time", final_phase_start_time)

	var enemy_spawner := _get_child(arena, "EnemySpawner")
	_set_if_present(enemy_spawner, "min_spawn_distance_from_player", min_spawn_distance_from_player)
	_set_if_present(enemy_spawner, "max_spawn_distance_from_player", max_spawn_distance_from_player)
	_set_if_present(enemy_spawner, "max_alive_enemies_cap", max_alive_enemies_cap)
	_set_if_present(enemy_spawner, "base_powerup_drop_chance", base_powerup_drop_chance)
	_set_if_present(enemy_spawner, "powerup_debug_logging", enable_powerup_logs)
	_set_if_present(enemy_spawner, "spawn_debug_logging", enable_spawn_logs)

	var debug_manager := _get_child(arena, "DebugManager")
	_set_if_present(debug_manager, "debug_input_logging", enable_debug_input_logs)

	var ability_manager := player.get_node_or_null("AbilityManager") if player != null else null
	_set_if_present(ability_manager, "nova_damage", nova_damage)
	_set_if_present(ability_manager, "nova_cooldown", nova_cooldown)
	_set_if_present(ability_manager, "laser_damage", laser_damage)
	_set_if_present(ability_manager, "laser_cooldown", laser_cooldown)
	_set_if_present(ability_manager, "slam_damage", slam_damage)
	_set_if_present(ability_manager, "slam_cooldown", slam_cooldown)

	var powerup_manager := _get_child(arena, "PowerupManager")
	_set_if_present(powerup_manager, "base_powerup_drop_chance", base_powerup_drop_chance)


func _get_child(parent: Node, child_name: String) -> Node:
	return parent.get_node_or_null(child_name) if parent != null else null


func _set_if_present(target: Node, property_name: String, value) -> void:
	if target == null:
		return
	if target.get(property_name) == null:
		return
	target.set(property_name, value)
