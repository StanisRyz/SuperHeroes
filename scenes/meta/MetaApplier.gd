extends Node

# Apply order: GameplayTuning -> HeroApplier -> MetaApplier.
# Meta bonuses stack on top of hero starting stats.


static func apply_meta_progression(meta_manager: Node, player: Node, auto_attack: Node, ability_manager: Node, hero_id: String = "") -> void:
	if meta_manager == null:
		return
	var resolved_hero_id := hero_id
	if resolved_hero_id.is_empty():
		resolved_hero_id = "guardian"
		push_warning("MetaApplier: missing hero_id, falling back to guardian training.")
	if meta_manager.has_method("ensure_training_data_for_hero"):
		meta_manager.ensure_training_data_for_hero(resolved_hero_id)
	if meta_manager.has_method("ensure_equipment_data_for_hero"):
		meta_manager.ensure_equipment_data_for_hero(resolved_hero_id)

	_apply_training_stat_modifiers(meta_manager, resolved_hero_id, player, auto_attack, ability_manager)
	_apply_training_ability_modifiers(meta_manager, resolved_hero_id, ability_manager)

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

	_apply_equipment_modifiers(meta_manager, resolved_hero_id, player, auto_attack, ability_manager)


static func _apply_training_stat_modifiers(meta_manager: Node, hero_id: String, player: Node, auto_attack: Node, ability_manager: Node) -> void:
	if not meta_manager.has_method("get_training_stat_modifiers_for_hero"):
		return
	var modifiers: Dictionary = meta_manager.get_training_stat_modifiers_for_hero(hero_id)
	if modifiers.is_empty():
		return

	if player != null and is_instance_valid(player):
		var health_bonus := int(round(float(modifiers.get("max_health", 0.0))))
		if health_bonus > 0 and player.get("max_health") != null:
			var new_max := int(player.get("max_health") or 100) + health_bonus
			player.set("max_health", new_max)
			player.set("current_health", new_max)
			if player.has_signal("health_changed"):
				player.health_changed.emit(new_max, new_max)

		var damage_reduction := float(modifiers.get("damage_reduction", 0.0))
		if damage_reduction > 0.0 and player.get("damage_reduction") != null:
			var current_reduction := float(player.get("damage_reduction") or 0.0)
			player.set("damage_reduction", clampf(current_reduction + damage_reduction, 0.0, 0.50))

	var base_damage := int(round(float(modifiers.get("base_damage", 0.0))))
	if base_damage <= 0:
		return
	if auto_attack != null and is_instance_valid(auto_attack) and auto_attack.get("attack_damage") != null:
		auto_attack.set("attack_damage", int(auto_attack.get("attack_damage") or 0) + base_damage)
	if ability_manager != null and is_instance_valid(ability_manager):
		_apply_base_damage_bonus(ability_manager, base_damage)


static func _apply_training_ability_modifiers(meta_manager: Node, hero_id: String, ability_manager: Node) -> void:
	if ability_manager == null or not is_instance_valid(ability_manager):
		return
	if not meta_manager.has_method("get_training_ability_modifiers_for_hero"):
		return
	var mods: Dictionary = meta_manager.get_training_ability_modifiers_for_hero(hero_id)
	if mods.is_empty():
		return
	var prop_map := _get_ability_training_property_map(hero_id)
	for target in mods:
		var target_mods: Dictionary = mods.get(target, {})
		for effect_type in target_mods:
			var value := float(target_mods.get(effect_type, 0.0))
			if is_zero_approx(value):
				continue
			var key := "%s|%s" % [target, effect_type]
			if not prop_map.has(key):
				continue
			var prop_entry: Dictionary = prop_map.get(key, {})
			var mode := str(prop_entry.get("mode", "add"))
			for prop_name in prop_entry.get("properties", []):
				var pname := str(prop_name)
				if ability_manager.get(pname) == null:
					continue
				match mode:
					"add":
						_add_number(ability_manager, pname, value)
					"subtract_clamped":
						var current := float(ability_manager.get(pname))
						var min_val := float(prop_entry.get("clamp_min", 0.0))
						ability_manager.set(pname, maxf(current - value, min_val))
					"add_clamped":
						var current := float(ability_manager.get(pname))
						var max_val := float(prop_entry.get("clamp_max", 1.0))
						ability_manager.set(pname, minf(current + value, max_val))
					"multiply_by_factor":
						var current := float(ability_manager.get(pname))
						ability_manager.set(pname, current * (1.0 + value))


static func _get_ability_training_property_map(hero_id: String) -> Dictionary:
	match hero_id:
		"guardian":
			return {
				"ability_1|ability_damage": {"mode": "add", "properties": ["solar_beam_damage"]},
				"ability_2|slow_strength": {"mode": "subtract_clamped", "properties": ["frost_breath_slow_multiplier"], "clamp_min": 0.1},
				"ability_3|ability_damage": {"mode": "add", "properties": ["death_dash_damage"]},
			}
		"blaster":
			return {
				"ability_1|damage_reduction": {"mode": "add_clamped", "properties": ["smoke_screen_damage_reduction"], "clamp_max": 0.75},
				"ability_2|ability_damage": {"mode": "add", "properties": ["explosive_trap_damage"]},
				"ability_3|ability_damage": {"mode": "add", "properties": ["grappling_hook_damage"]},
			}
		"vanguard":
			return {
				"ability_1|ability_damage": {"mode": "add", "properties": ["rage_wave_damage"]},
				"ability_2|knockback_power": {"mode": "multiply_by_factor", "properties": ["mighty_clap_knockback_force"]},
				"ability_3|ability_damage": {"mode": "add", "properties": ["rage_leap_damage"]},
			}
	return {}


static func _get_training_level(meta_manager: Node, hero_id: String, upgrade_id: String) -> int:
	if meta_manager.has_method("get_training_level"):
		return int(meta_manager.get_training_level(hero_id, upgrade_id))
	if meta_manager.has_method("get_meta_upgrade_level"):
		return int(meta_manager.get_meta_upgrade_level(upgrade_id))
	return 0


static func _apply_equipment_modifiers(meta_manager: Node, hero_id: String, player: Node, auto_attack: Node, ability_manager: Node) -> void:
	if not meta_manager.has_method("get_equipment_stat_modifiers_for_hero"):
		return
	var modifiers: Dictionary = meta_manager.get_equipment_stat_modifiers_for_hero(hero_id)
	if modifiers.is_empty():
		return

	if player != null and is_instance_valid(player):
		var health_bonus := int(round(float(modifiers.get("max_health", 0.0))))
		if health_bonus > 0 and player.get("max_health") != null:
			var new_max := int(player.get("max_health") or 100) + health_bonus
			player.set("max_health", new_max)
			player.set("current_health", new_max)
			if player.has_signal("health_changed"):
				player.health_changed.emit(new_max, new_max)

		var speed_bonus := float(modifiers.get("move_speed", 0.0))
		if not is_zero_approx(speed_bonus) and player.get("speed") != null:
			var current_speed := float(player.get("speed") or 260.0)
			var flat_speed_bonus := floorf(speed_bonus) if speed_bonus > 1.0 else 0.0
			var percent_speed_bonus := speed_bonus - flat_speed_bonus
			player.set("speed", (current_speed + flat_speed_bonus) * maxf(1.0 + percent_speed_bonus, 0.0))

		var xp_bonus := float(modifiers.get("xp_gain", 0.0))
		if not is_zero_approx(xp_bonus) and player.get("experience_gain_multiplier") != null:
			player.set("experience_gain_multiplier", maxf(float(player.get("experience_gain_multiplier") or 1.0) + xp_bonus, 0.0))

		var shield_bonus := int(round(float(modifiers.get("shield_capacity", 0.0))))
		if shield_bonus > 0:
			var buff_manager := player.get_node_or_null("PlayerBuffManager")
			if buff_manager != null and buff_manager.has_method("add_shield_charges"):
				buff_manager.add_shield_charges(shield_bonus)

	if auto_attack != null and is_instance_valid(auto_attack):
		var attack_bonus := int(round(float(modifiers.get("attack_damage", 0.0))))
		if attack_bonus > 0 and auto_attack.get("attack_damage") != null:
			auto_attack.set("attack_damage", int(auto_attack.get("attack_damage") or 0) + attack_bonus)

	if ability_manager != null and is_instance_valid(ability_manager):
		var ability_bonus := float(modifiers.get("ability_damage", 0.0))
		if not is_zero_approx(ability_bonus):
			_apply_ability_damage_multiplier(ability_manager, 1.0 + ability_bonus)

		var cooldown_bonus := float(modifiers.get("ability_cooldown", 0.0))
		if not is_zero_approx(cooldown_bonus):
			_apply_all_cooldown_multiplier(ability_manager, maxf(1.0 - cooldown_bonus, 0.5))

		var mark_bonus := float(modifiers.get("mark_damage", 0.0))
		if not is_zero_approx(mark_bonus):
			_add_number(ability_manager, "tactical_mark_autoattack_damage_multiplier", mark_bonus)

		var rage_bonus := float(modifiers.get("rage_gain", 0.0))
		if not is_zero_approx(rage_bonus):
			var rage_multiplier := 1.0 + rage_bonus
			_multiply_number(ability_manager, "rage_per_damage_taken", rage_multiplier)
			_multiply_number(ability_manager, "rage_per_damage_dealt", rage_multiplier)
			_multiply_number(ability_manager, "rage_per_hit", rage_multiplier)


static func _apply_ability_damage_multiplier(ability_manager: Node, multiplier: float) -> void:
	for property_name in [
		"nova_damage", "nova_aftershock_damage", "laser_damage", "slam_damage",
		"solar_beam_damage", "solar_beam_burn_damage", "frost_breath_damage", "death_dash_damage",
		"explosive_trap_damage", "grappling_hook_damage",
		"rage_wave_damage", "mighty_clap_damage", "rage_leap_damage",
	]:
		_multiply_number(ability_manager, property_name, multiplier)


static func _apply_base_damage_bonus(ability_manager: Node, bonus: int) -> void:
	for property_name in [
		"nova_damage", "laser_damage", "slam_damage",
		"solar_beam_damage", "frost_breath_damage", "death_dash_damage",
		"explosive_trap_damage", "grappling_hook_damage",
		"rage_wave_damage", "mighty_clap_damage", "rage_leap_damage",
	]:
		_add_number(ability_manager, property_name, bonus)


static func _apply_all_cooldown_multiplier(ability_manager: Node, multiplier: float) -> void:
	for property_name in [
		"nova_cooldown", "laser_cooldown", "slam_cooldown",
		"solar_beam_cooldown", "frost_breath_cooldown", "death_dash_cooldown",
		"smoke_screen_cooldown", "explosive_trap_cooldown", "grappling_hook_cooldown",
		"rage_wave_cooldown", "mighty_clap_cooldown", "rage_leap_cooldown",
	]:
		_apply_cooldown_multiplier(ability_manager, property_name, multiplier)


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


static func _multiply_number(target: Node, property_name: String, multiplier: float) -> void:
	if target.get(property_name) == null:
		return
	var current = target.get(property_name)
	if current is int:
		target.set(property_name, maxi(roundi(float(current) * multiplier), 0))
	else:
		target.set(property_name, float(current) * multiplier)
