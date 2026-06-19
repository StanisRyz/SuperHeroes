extends Node

# Apply order: GameplayTuning -> HeroApplier -> MetaApplier.
# Meta bonuses stack on top of hero starting stats.


static func apply_meta_progression(meta_manager: Node, player: Node, auto_attack: Node, _ability_manager: Node, hero_id: String = "") -> void:
	if meta_manager == null:
		return
	var resolved_hero_id := hero_id
	if resolved_hero_id.is_empty():
		resolved_hero_id = "guardian"
		push_warning("MetaApplier: missing hero_id, falling back to guardian training.")
	if meta_manager.has_method("ensure_training_data_for_hero"):
		meta_manager.ensure_training_data_for_hero(resolved_hero_id)

	if player != null and is_instance_valid(player):
		var hp_level: int = _get_training_level(meta_manager, resolved_hero_id, "meta_max_health")
		if hp_level > 0:
			var bonus_hp: int = hp_level * 5
			var new_max: int = int(player.get("max_health") or 100) + bonus_hp
			player.set("max_health", new_max)
			player.set("current_health", new_max)
			if player.has_signal("health_changed"):
				player.health_changed.emit(new_max, new_max)

		var speed_level: int = _get_training_level(meta_manager, resolved_hero_id, "meta_move_speed")
		if speed_level > 0:
			var new_speed := float(player.get("speed") or 260.0) + float(speed_level) * 3.0
			player.set("speed", new_speed)

		var radius_level: int = _get_training_level(meta_manager, resolved_hero_id, "meta_pickup_radius")
		if radius_level > 0 and player.get("pickup_radius_bonus") != null:
			var current_bonus := float(player.get("pickup_radius_bonus") or 0.0)
			player.set("pickup_radius_bonus", current_bonus + float(radius_level) * 8.0)

	if auto_attack != null and is_instance_valid(auto_attack):
		var damage_level: int = _get_training_level(meta_manager, resolved_hero_id, "meta_attack_damage")
		if damage_level > 0:
			var new_dmg: int = int(auto_attack.get("attack_damage") or 10) + damage_level
			auto_attack.set("attack_damage", new_dmg)


static func _get_training_level(meta_manager: Node, hero_id: String, upgrade_id: String) -> int:
	if meta_manager.has_method("get_training_level"):
		return int(meta_manager.get_training_level(hero_id, upgrade_id))
	if meta_manager.has_method("get_meta_upgrade_level"):
		return int(meta_manager.get_meta_upgrade_level(upgrade_id))
	return 0
