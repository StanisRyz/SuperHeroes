extends Node


func run(arena: Node) -> void:
	if arena == null:
		push_warning("ProjectHealthCheck: Arena is missing.")
		return

	_check(arena, "Player")
	_check(arena, "EnemySpawner")
	_check(arena, "SpawnDirector")
	_check(arena, "RunManager")
	_check(arena, "UpgradeManager")
	_check(arena, "EvolutionManager")
	_check_nested(arena, "Player/AbilityManager", "AbilityManager")
	_check(arena, "PowerupManager")
	_check(arena, "PickupContainer")
	_check(arena, "ProjectileContainer")
	_check(arena, "GameHUD")
	_check(arena, "VictoryScreen")
	_check(arena, "GameOverScreen")
	_check(arena, "EvolutionRewardScreen")
	_check(arena, "DebugManager")
	if arena.get("_debug_stats_overlay") == null:
		push_warning("ProjectHealthCheck: DebugStatsOverlay is missing.")


func _check(arena: Node, path: String) -> void:
	if arena.get_node_or_null(path) == null:
		push_warning("ProjectHealthCheck: %s is missing." % path)


func _check_nested(arena: Node, path: String, display_name: String) -> void:
	if arena.get_node_or_null(path) == null:
		push_warning("ProjectHealthCheck: %s is missing." % display_name)
