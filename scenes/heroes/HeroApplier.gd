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
		if hero.has("ability_names") and ability_manager.has_method("set_ability_display_names"):
			ability_manager.set_ability_display_names(hero.get("ability_names", {}))
		if ability_manager.has_method("set_hero_kit"):
			ability_manager.set_hero_kit(str(hero.get("id", "")), str(hero.get("kit_id", "")), hero.get("ability_kit", {}))
		var cooldown_multiplier := float(stats.get("ability_cooldown_multiplier", 1.0))
		if not is_equal_approx(cooldown_multiplier, 1.0):
			_apply_cooldown_multiplier(ability_manager, "nova_cooldown", cooldown_multiplier)
			_apply_cooldown_multiplier(ability_manager, "laser_cooldown", cooldown_multiplier)
			_apply_cooldown_multiplier(ability_manager, "slam_cooldown", cooldown_multiplier)
		_add_number(ability_manager, "nova_damage", stats.get("nova_damage_bonus", 0))
		_add_number(ability_manager, "nova_radius", stats.get("nova_radius_bonus", 0.0))
		_add_number(ability_manager, "laser_damage", stats.get("laser_damage_bonus", 0))
		_add_number(ability_manager, "laser_width", stats.get("laser_width_bonus", 0.0))
		_add_number(ability_manager, "slam_damage", stats.get("slam_damage_bonus", 0))
		_add_number(ability_manager, "slam_radius", stats.get("slam_radius_bonus", 0.0))

	if auto_attack != null:
		var weapon_data: Dictionary = hero.get("primary_weapon", {})
		if not weapon_data.is_empty() and auto_attack.has_method("set_primary_weapon"):
			var hero_id_str := str(hero.get("id", ""))
			var weapon_id_str := str(weapon_data.get("weapon_id", ""))
			auto_attack.set_primary_weapon(hero_id_str, weapon_id_str, weapon_data)
		if ability_manager != null and auto_attack.has_method("set_ability_manager_ref"):
			auto_attack.set_ability_manager_ref(ability_manager)


static func _apply_cooldown_multiplier(target: Node, property_name: String, multiplier: float) -> void:
	if target.get(property_name) == null:
		return
	target.set(property_name, maxf(float(target.get(property_name)) * multiplier, 0.5))


static func _add_number(target: Node, property_name: String, amount) -> void:
	if is_zero_approx(float(amount)) or target.get(property_name) == null:
		return
	var current = target.get(property_name)
	if current is int:
		target.set(property_name, int(current) + int(amount))
	else:
		target.set(property_name, float(current) + float(amount))
