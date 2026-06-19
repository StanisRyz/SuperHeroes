extends SceneTree

class FakeEnemy:
	extends Node2D

	var damage_received := 0

	func take_damage(amount: int) -> void:
		damage_received += amount

	func die() -> void:
		pass

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

	var enemy := FakeEnemy.new()
	var projectile_script = load("res://scenes/projectiles/PlayerProjectile.gd")
	var first_projectile = projectile_script.new()
	var second_projectile = projectile_script.new()
	first_projectile.setup(Vector2.ZERO, enemy, 5, {"attack_id": 7, "projectile_index": 0})
	second_projectile.setup(Vector2.ZERO, enemy, 5, {"attack_id": 7, "projectile_index": 1})

	if not first_projectile._try_hit_enemy(enemy):
		push_error("Expected first projectile instance to damage the enemy.")
		quit(1)
		return
	if first_projectile._try_hit_enemy(enemy):
		push_error("Expected one projectile instance to reject duplicate same-enemy damage.")
		quit(1)
		return
	if not second_projectile._try_hit_enemy(enemy):
		push_error("Expected separate projectile instance to damage the same enemy.")
		quit(1)
		return
	if enemy.damage_received != 10:
		push_error("Expected two separate projectile hits to apply damage independently.")
		quit(1)
		return

	auto_attack.free()
	enemy.free()
	first_projectile.free()
	second_projectile.free()
	quit(0)
