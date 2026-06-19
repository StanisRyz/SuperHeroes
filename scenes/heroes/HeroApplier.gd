extends Node


static func apply_hero(hero: Dictionary, player: Node, auto_attack: Node, ability_manager: Node) -> void:
	if hero.is_empty():
		return

	var stats: Dictionary = hero.get("stats", {})
	if player != null:
		if stats.has("max_health") and player.get("max_health") != null:
			var max_health := int(stats["max_health"])
			player.set("max_health", max_health)
			player.set("current_health", max_health)
			if player.has_signal("health_changed"):
				player.health_changed.emit(max_health, max_health)
		if stats.has("speed") and player.get("speed") != null:
			player.set("speed", float(stats["speed"]))
		if hero.has("color") and player.has_method("apply_hero_visual_color"):
			player.apply_hero_visual_color(hero["color"])

	if auto_attack != null:
		if stats.has("attack_damage_bonus") and auto_attack.get("attack_damage") != null:
			auto_attack.set("attack_damage", int(auto_attack.get("attack_damage")) + int(stats["attack_damage_bonus"]))
		if stats.has("projectile_count_bonus") and auto_attack.get("projectile_count") != null:
			var max_count := int(auto_attack.get("max_projectile_count")) if auto_attack.get("max_projectile_count") != null else 7
			auto_attack.set("projectile_count", mini(int(auto_attack.get("projectile_count")) + int(stats["projectile_count_bonus"]), max_count))
		if stats.has("attack_interval_multiplier") and auto_attack.get("attack_interval") != null:
			auto_attack.set("attack_interval", maxf(float(auto_attack.get("attack_interval")) * float(stats["attack_interval_multiplier"]), 0.05))

	if ability_manager != null:
		var cooldown_multiplier := float(stats.get("ability_cooldown_multiplier", 1.0))
		if not is_equal_approx(cooldown_multiplier, 1.0):
			_apply_cooldown_multiplier(ability_manager, "nova_cooldown", cooldown_multiplier)
			_apply_cooldown_multiplier(ability_manager, "laser_cooldown", cooldown_multiplier)
			_apply_cooldown_multiplier(ability_manager, "slam_cooldown", cooldown_multiplier)
		_add_number(ability_manager, "nova_damage", stats.get("nova_damage_bonus", 0))
		_add_number(ability_manager, "laser_damage", stats.get("laser_damage_bonus", 0))
		_add_number(ability_manager, "slam_damage", stats.get("slam_damage_bonus", 0))


static func _apply_cooldown_multiplier(target: Node, property_name: String, multiplier: float) -> void:
	if target.get(property_name) == null:
		return
	target.set(property_name, maxf(float(target.get(property_name)) * multiplier, 0.5))


static func _add_number(target: Node, property_name: String, amount) -> void:
	if int(amount) == 0 or target.get(property_name) == null:
		return
	target.set(property_name, int(target.get(property_name)) + int(amount))
