extends Node

const ATTACK_INTERVAL_MIN := 0.2
const NOVA_COOLDOWN_MIN := 2.0
const LASER_COOLDOWN_MIN := 3.0
const SLAM_COOLDOWN_MIN := 3.5
const DASH_COOLDOWN_MIN := 0.45
const DASH_INVULNERABILITY_MAX := 0.6
const PROJECTILE_COUNT_MAX := 7
const PROJECTILE_SIZE_MAX := 2.0
const PROJECTILE_EXPLOSION_RADIUS_MAX := 180.0

var player: Node
var auto_attack: Node
var ability_manager: Node
var upgrade_levels: Dictionary = {}

var _upgrade_definitions: Array[Dictionary] = [
	{
		"id": "attack_damage_up",
		"title": "Power Bolt",
		"rarity": "common",
		"weight": 1.0,
		"max_level": 5,
		"description_template": "Increase autoattack damage by %s.",
		"effect_value": 2
	},
	{
		"id": "attack_speed_up",
		"title": "Quick Charge",
		"rarity": "rare",
		"weight": 0.75,
		"max_level": 5,
		"description_template": "Reduce autoattack interval by %ss.",
		"effect_value": 0.08
	},
	{
		"id": "attack_range_up",
		"title": "Long Reach",
		"rarity": "rare",
		"weight": 0.75,
		"max_level": 4,
		"description_template": "Increase autoattack targeting range by %s.",
		"effect_value": 45.0
	},
	{
		"id": "move_speed_up",
		"title": "Hero Sprint",
		"rarity": "common",
		"weight": 1.0,
		"max_level": 5,
		"description_template": "Increase movement speed by %s.",
		"effect_value": 25.0
	},
	{
		"id": "max_health_up",
		"title": "Iron Resolve",
		"rarity": "common",
		"weight": 1.0,
		"max_level": 5,
		"description_template": "Increase maximum HP and heal by %s.",
		"effect_value": 20
	},
	{
		"id": "projectile_speed_up",
		"title": "Faster Bolts",
		"rarity": "rare",
		"weight": 0.75,
		"max_level": 4,
		"description_template": "Increase speed of newly fired projectiles by %s.",
		"effect_value": 80.0
	},
	{
		"id": "nova_damage_up",
		"title": "Nova Surge",
		"rarity": "epic",
		"weight": 0.45,
		"max_level": 4,
		"description_template": "Increase Nova Pulse damage by %s.",
		"effect_value": 5
	},
	{
		"id": "nova_cooldown_down",
		"title": "Pulse Rhythm",
		"rarity": "epic",
		"weight": 0.45,
		"max_level": 4,
		"description_template": "Reduce Nova Pulse cooldown by %ss.",
		"effect_value": 0.5
	},
	{
		"id": "dash_cooldown_down",
		"title": "Quick Escape",
		"rarity": "rare",
		"weight": 0.7,
		"max_level": 4,
		"description_template": "Reduce dash cooldown by %ss.",
		"effect_value": 0.15
	},
	{
		"id": "dash_invulnerability_up",
		"title": "Hero Reflex",
		"rarity": "epic",
		"weight": 0.45,
		"max_level": 3,
		"description_template": "Increase dash invulnerability by %ss.",
		"effect_value": 0.08
	},
	{
		"id": "projectile_pierce_up",
		"title": "Piercing Bolts",
		"rarity": "rare",
		"weight": 0.65,
		"max_level": 4,
		"description_template": "Increase projectile pierce by %s.",
		"effect_value": 1
	},
	{
		"id": "multishot_up",
		"title": "Hero Barrage",
		"rarity": "epic",
		"weight": 0.35,
		"max_level": 3,
		"description_template": "Fire +%s projectile per attack.",
		"effect_value": 1
	},
	{
		"id": "spread_up",
		"title": "Wide Angle",
		"rarity": "rare",
		"weight": 0.65,
		"max_level": 4,
		"description_template": "Increase projectile spread angle by %s degrees.",
		"effect_value": 8.0
	},
	{
		"id": "projectile_size_up",
		"title": "Heavy Bolts",
		"rarity": "common",
		"weight": 0.8,
		"max_level": 4,
		"description_template": "Increase projectile size by %s.",
		"effect_value": 0.15
	},
	{
		"id": "explosive_projectiles",
		"title": "Impact Burst",
		"rarity": "epic",
		"weight": 0.35,
		"max_level": 3,
		"description_template": "Increase projectile explosion radius by %s.",
		"effect_value": 45.0
	},
	{
		"id": "laser_damage_up",
		"title": "Laser Focus",
		"rarity": "epic",
		"weight": 0.45,
		"max_level": 4,
		"description_template": "Increase Laser Beam damage by %s.",
		"effect_value": 8
	},
	{
		"id": "laser_cooldown_down",
		"title": "Laser Capacitor",
		"rarity": "epic",
		"weight": 0.4,
		"max_level": 4,
		"description_template": "Reduce Laser Beam cooldown by %ss.",
		"effect_value": 0.5
	},
	{
		"id": "laser_width_up",
		"title": "Wide Beam",
		"rarity": "rare",
		"weight": 0.65,
		"max_level": 4,
		"description_template": "Increase Laser Beam width by %s.",
		"effect_value": 20.0
	},
	{
		"id": "slam_damage_up",
		"title": "Impact Force",
		"rarity": "epic",
		"weight": 0.45,
		"max_level": 4,
		"description_template": "Increase Hero Slam damage by %s.",
		"effect_value": 10
	},
	{
		"id": "slam_radius_up",
		"title": "Shockwave",
		"rarity": "rare",
		"weight": 0.65,
		"max_level": 4,
		"description_template": "Increase Hero Slam radius by %s.",
		"effect_value": 25.0
	},
	{
		"id": "slam_cooldown_down",
		"title": "Slam Ready",
		"rarity": "epic",
		"weight": 0.4,
		"max_level": 4,
		"description_template": "Reduce Hero Slam cooldown by %ss.",
		"effect_value": 0.6
	}
]

func setup(new_player: Node, new_auto_attack: Node, new_ability_manager: Node = null) -> void:
	player = new_player
	auto_attack = new_auto_attack
	ability_manager = new_ability_manager


func get_upgrade_options(count: int = 3) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for definition in _upgrade_definitions:
		if is_upgrade_available(str(definition.get("id", ""))):
			candidates.append(definition)

	var options: Array[Dictionary] = []
	while not candidates.is_empty() and options.size() < count:
		var selected := _pick_weighted_definition(candidates)
		if selected.is_empty():
			break

		options.append(_build_option(selected))
		candidates.erase(selected)

	return options


func apply_upgrade(upgrade_id: String) -> void:
	if not is_upgrade_available(upgrade_id):
		push_warning("Upgrade is unavailable or maxed: %s" % upgrade_id)
		return

	var definition := _get_upgrade_definition(upgrade_id)
	if definition.is_empty():
		push_warning("Unknown upgrade id: %s" % upgrade_id)
		return

	var effect_value = definition.get("effect_value", 0.0)
	var applied := false
	match upgrade_id:
		"attack_damage_up":
			applied = _apply_auto_attack_number("attack_damage", effect_value)
		"attack_speed_up":
			applied = _apply_attack_speed_upgrade(effect_value)
		"attack_range_up":
			applied = _apply_auto_attack_number("attack_range", effect_value)
			if applied and auto_attack != null and auto_attack.has_method("refresh_attack_range"):
				auto_attack.refresh_attack_range()
		"move_speed_up":
			applied = _apply_player_number("speed", effect_value)
		"max_health_up":
			applied = _apply_max_health_upgrade(effect_value)
		"projectile_speed_up":
			applied = _apply_auto_attack_number("projectile_speed", effect_value)
		"nova_damage_up":
			applied = _apply_ability_number("nova_damage", effect_value)
		"nova_cooldown_down":
			applied = _apply_nova_cooldown_upgrade(effect_value)
		"dash_cooldown_down":
			applied = _apply_dash_cooldown_upgrade(effect_value)
		"dash_invulnerability_up":
			applied = _apply_dash_invulnerability_upgrade(effect_value)
		"projectile_pierce_up":
			applied = _apply_auto_attack_number("projectile_pierce", effect_value)
		"multishot_up":
			applied = _apply_projectile_count_upgrade(effect_value)
		"spread_up":
			applied = _apply_auto_attack_number("projectile_spread_degrees", effect_value)
		"projectile_size_up":
			applied = _apply_projectile_size_upgrade(effect_value)
		"explosive_projectiles":
			applied = _apply_explosive_projectiles_upgrade(effect_value)
		"laser_damage_up":
			applied = _apply_ability_number("laser_damage", effect_value)
		"laser_cooldown_down":
			applied = _apply_laser_cooldown_upgrade(effect_value)
		"laser_width_up":
			applied = _apply_ability_number("laser_width", effect_value)
		"slam_damage_up":
			applied = _apply_ability_number("slam_damage", effect_value)
		"slam_radius_up":
			applied = _apply_ability_number("slam_radius", effect_value)
		"slam_cooldown_down":
			applied = _apply_slam_cooldown_upgrade(effect_value)
		_:
			push_warning("Unknown upgrade id: %s" % upgrade_id)

	if applied:
		_increment_upgrade_level(upgrade_id)


func get_upgrade_level(upgrade_id: String) -> int:
	return int(upgrade_levels.get(upgrade_id, 0))


func is_upgrade_available(upgrade_id: String) -> bool:
	var definition := _get_upgrade_definition(upgrade_id)
	if definition.is_empty():
		return false

	return get_upgrade_level(upgrade_id) < int(definition.get("max_level", 1))


func _increment_upgrade_level(upgrade_id: String) -> void:
	upgrade_levels[upgrade_id] = get_upgrade_level(upgrade_id) + 1


func _build_option(definition: Dictionary) -> Dictionary:
	var upgrade_id := str(definition.get("id", ""))
	var current_level := get_upgrade_level(upgrade_id)
	var next_level := current_level + 1
	var max_level := int(definition.get("max_level", 1))
	var effect_text := _format_effect_value(definition.get("effect_value", 0.0))
	var description := str(definition.get("description_template", "Upgrade by %s.")) % effect_text
	description = "%s Level %d / %d." % [description, next_level, max_level]

	return {
		"id": upgrade_id,
		"title": definition.get("title", "Upgrade"),
		"rarity": definition.get("rarity", "common"),
		"level": current_level,
		"max_level": max_level,
		"description": description
	}


func _pick_weighted_definition(candidates: Array[Dictionary]) -> Dictionary:
	var total_weight := 0.0
	for definition in candidates:
		total_weight += maxf(float(definition.get("weight", 1.0)), 0.0)

	if total_weight <= 0.0:
		return candidates.pick_random() if not candidates.is_empty() else {}

	var roll := randf() * total_weight
	var cursor := 0.0
	for definition in candidates:
		cursor += maxf(float(definition.get("weight", 1.0)), 0.0)
		if roll <= cursor:
			return definition

	return candidates.back() if not candidates.is_empty() else {}


func _get_upgrade_definition(upgrade_id: String) -> Dictionary:
	for definition in _upgrade_definitions:
		if str(definition.get("id", "")) == upgrade_id:
			return definition

	return {}


func _format_effect_value(value) -> String:
	if value is int:
		return str(value)

	var number := float(value)
	if is_equal_approx(number, roundf(number)):
		return str(int(roundf(number)))

	return "%.2f" % number if number < 0.1 else "%.1f" % number


func _apply_auto_attack_number(property_name: String, amount) -> bool:
	if auto_attack == null:
		push_warning("UpgradeManager is missing AutoAttack reference.")
		return false

	var value = auto_attack.get(property_name)
	if value == null:
		push_warning("AutoAttack is missing property: %s" % property_name)
		return false

	auto_attack.set(property_name, value + amount)
	return true


func _apply_player_number(property_name: String, amount) -> bool:
	if player == null:
		push_warning("UpgradeManager is missing Player reference.")
		return false

	var value = player.get(property_name)
	if value == null:
		push_warning("Player is missing property: %s" % property_name)
		return false

	player.set(property_name, value + amount)
	return true


func _apply_ability_number(property_name: String, amount) -> bool:
	if ability_manager == null:
		push_warning("UpgradeManager is missing AbilityManager reference.")
		return false

	var value = ability_manager.get(property_name)
	if value == null:
		push_warning("AbilityManager is missing property: %s" % property_name)
		return false

	ability_manager.set(property_name, value + amount)
	return true


func _apply_attack_speed_upgrade(amount) -> bool:
	if auto_attack == null:
		push_warning("UpgradeManager is missing AutoAttack reference.")
		return false

	var value = auto_attack.get("attack_interval")
	if value == null:
		push_warning("AutoAttack is missing attack_interval.")
		return false

	auto_attack.set("attack_interval", maxf(ATTACK_INTERVAL_MIN, value - float(amount)))
	return true


func _apply_nova_cooldown_upgrade(amount) -> bool:
	if ability_manager == null:
		push_warning("UpgradeManager is missing AbilityManager reference.")
		return false

	var value = ability_manager.get("nova_cooldown")
	if value == null:
		push_warning("AbilityManager is missing nova_cooldown.")
		return false

	ability_manager.set("nova_cooldown", maxf(NOVA_COOLDOWN_MIN, value - float(amount)))
	return true


func _apply_laser_cooldown_upgrade(amount) -> bool:
	if ability_manager == null:
		push_warning("UpgradeManager is missing AbilityManager reference.")
		return false

	var value = ability_manager.get("laser_cooldown")
	if value == null:
		push_warning("AbilityManager is missing laser_cooldown.")
		return false

	ability_manager.set("laser_cooldown", maxf(LASER_COOLDOWN_MIN, value - float(amount)))
	return true


func _apply_slam_cooldown_upgrade(amount) -> bool:
	if ability_manager == null:
		push_warning("UpgradeManager is missing AbilityManager reference.")
		return false

	var value = ability_manager.get("slam_cooldown")
	if value == null:
		push_warning("AbilityManager is missing slam_cooldown.")
		return false

	ability_manager.set("slam_cooldown", maxf(SLAM_COOLDOWN_MIN, value - float(amount)))
	return true


func _apply_dash_cooldown_upgrade(amount) -> bool:
	if player == null:
		push_warning("UpgradeManager is missing Player reference.")
		return false

	var value = player.get("dash_cooldown")
	if value == null:
		push_warning("Player is missing dash_cooldown.")
		return false

	player.set("dash_cooldown", maxf(DASH_COOLDOWN_MIN, value - float(amount)))
	return true


func _apply_dash_invulnerability_upgrade(amount) -> bool:
	if player == null:
		push_warning("UpgradeManager is missing Player reference.")
		return false

	var value = player.get("dash_invulnerability_duration")
	if value == null:
		push_warning("Player is missing dash_invulnerability_duration.")
		return false

	player.set("dash_invulnerability_duration", minf(DASH_INVULNERABILITY_MAX, value + float(amount)))
	return true


func _apply_projectile_count_upgrade(amount) -> bool:
	if auto_attack == null:
		push_warning("UpgradeManager is missing AutoAttack reference.")
		return false

	var value = auto_attack.get("projectile_count")
	if value == null:
		push_warning("AutoAttack is missing projectile_count.")
		return false

	auto_attack.set("projectile_count", mini(PROJECTILE_COUNT_MAX, int(value) + int(amount)))
	return true


func _apply_projectile_size_upgrade(amount) -> bool:
	if auto_attack == null:
		push_warning("UpgradeManager is missing AutoAttack reference.")
		return false

	var value = auto_attack.get("projectile_size_multiplier")
	if value == null:
		push_warning("AutoAttack is missing projectile_size_multiplier.")
		return false

	auto_attack.set("projectile_size_multiplier", minf(PROJECTILE_SIZE_MAX, value + float(amount)))
	return true


func _apply_explosive_projectiles_upgrade(amount) -> bool:
	if auto_attack == null:
		push_warning("UpgradeManager is missing AutoAttack reference.")
		return false

	var value = auto_attack.get("projectile_explosion_radius")
	if value == null:
		push_warning("AutoAttack is missing projectile_explosion_radius.")
		return false

	auto_attack.set("projectile_explosion_radius", minf(PROJECTILE_EXPLOSION_RADIUS_MAX, value + float(amount)))
	return true


func _apply_max_health_upgrade(amount) -> bool:
	if player == null:
		push_warning("UpgradeManager is missing Player reference.")
		return false

	var max_health = player.get("max_health")
	var current_health = player.get("current_health")
	if max_health == null or current_health == null:
		push_warning("Player is missing health properties.")
		return false

	var health_increase := int(amount)
	player.set("max_health", max_health + health_increase)
	player.set("current_health", min(current_health + health_increase, player.get("max_health")))

	if player.has_signal("health_changed"):
		player.health_changed.emit(player.get("current_health"), player.get("max_health"))

	return true
