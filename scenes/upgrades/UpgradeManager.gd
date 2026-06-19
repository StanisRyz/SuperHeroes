extends Node

const ATTACK_INTERVAL_MIN := 0.2
const NOVA_COOLDOWN_MIN := 2.0
const DASH_COOLDOWN_MIN := 0.45
const DASH_INVULNERABILITY_MAX := 0.6

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
