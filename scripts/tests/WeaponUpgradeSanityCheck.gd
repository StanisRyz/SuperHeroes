extends SceneTree

func _init() -> void:
	var auto_attack = load("res://scenes/player/PlayerAutoAttack.gd").new()
	auto_attack.projectile_count = 3
	auto_attack.projectile_spread_degrees = 0.0

	var effective_spread: float = auto_attack._get_effective_spread_degrees(auto_attack.projectile_count)
	if effective_spread <= 0.0:
		push_error("Expected multishot effective spread to be non-zero.")
		quit(1)
		return

	var directions: Array[Vector2] = auto_attack._get_projectile_directions(Vector2.RIGHT, auto_attack.projectile_count, effective_spread)
	if directions.size() != auto_attack.projectile_count:
		push_error("Expected direction count to match projectile_count.")
		quit(1)
		return

	if directions[0].is_equal_approx(directions[1]) or directions[1].is_equal_approx(directions[2]):
		push_error("Expected multishot directions to be distinct.")
		quit(1)
		return

	var stats: Dictionary = auto_attack.get_weapon_stats()
	if int(stats.get("projectile_count", 0)) != auto_attack.projectile_count:
		push_error("Expected get_weapon_stats() to expose projectile_count.")
		quit(1)
		return

	auto_attack.free()
	quit(0)
