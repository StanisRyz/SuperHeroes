extends Node

const ATTACK_INTERVAL_MIN := 0.2
const NOVA_COOLDOWN_MIN := 2.0

var player: Node
var auto_attack: Node
var ability_manager: Node

var _upgrade_definitions: Array[Dictionary] = [
	{
		"id": "attack_damage_up",
		"title": "Power Bolt",
		"description": "Increase autoattack damage."
	},
	{
		"id": "attack_speed_up",
		"title": "Quick Charge",
		"description": "Fire autoattacks more often."
	},
	{
		"id": "attack_range_up",
		"title": "Long Reach",
		"description": "Increase autoattack targeting range."
	},
	{
		"id": "move_speed_up",
		"title": "Hero Sprint",
		"description": "Increase movement speed."
	},
	{
		"id": "max_health_up",
		"title": "Iron Resolve",
		"description": "Increase maximum HP and heal."
	},
	{
		"id": "projectile_speed_up",
		"title": "Faster Bolts",
		"description": "Increase speed of newly fired projectiles."
	},
	{
		"id": "nova_damage_up",
		"title": "Nova Surge",
		"description": "Increase Nova Pulse damage."
	},
	{
		"id": "nova_cooldown_down",
		"title": "Pulse Rhythm",
		"description": "Reduce Nova Pulse cooldown."
	}
]

func setup(new_player: Node, new_auto_attack: Node, new_ability_manager: Node = null) -> void:
	player = new_player
	auto_attack = new_auto_attack
	ability_manager = new_ability_manager


func get_upgrade_options(count: int = 3) -> Array[Dictionary]:
	var options := _upgrade_definitions.duplicate()
	options.shuffle()
	return options.slice(0, mini(count, options.size()))


func apply_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		"attack_damage_up":
			_apply_auto_attack_number("attack_damage", 2.0)
		"attack_speed_up":
			_apply_attack_speed_upgrade()
		"attack_range_up":
			_apply_auto_attack_number("attack_range", 45.0)
			if auto_attack != null and auto_attack.has_method("refresh_attack_range"):
				auto_attack.refresh_attack_range()
		"move_speed_up":
			_apply_player_number("speed", 25.0)
		"max_health_up":
			_apply_max_health_upgrade()
		"projectile_speed_up":
			_apply_auto_attack_number("projectile_speed", 80.0)
		"nova_damage_up":
			_apply_ability_number("nova_damage", 5.0)
		"nova_cooldown_down":
			_apply_nova_cooldown_upgrade()
		_:
			push_warning("Unknown upgrade id: %s" % upgrade_id)


func _apply_auto_attack_number(property_name: String, amount: float) -> void:
	if auto_attack == null:
		push_warning("UpgradeManager is missing AutoAttack reference.")
		return

	var value = auto_attack.get(property_name)
	if value == null:
		push_warning("AutoAttack is missing property: %s" % property_name)
		return

	auto_attack.set(property_name, value + amount)


func _apply_player_number(property_name: String, amount: float) -> void:
	if player == null:
		push_warning("UpgradeManager is missing Player reference.")
		return

	var value = player.get(property_name)
	if value == null:
		push_warning("Player is missing property: %s" % property_name)
		return

	player.set(property_name, value + amount)


func _apply_ability_number(property_name: String, amount: float) -> void:
	if ability_manager == null:
		push_warning("UpgradeManager is missing AbilityManager reference.")
		return

	var value = ability_manager.get(property_name)
	if value == null:
		push_warning("AbilityManager is missing property: %s" % property_name)
		return

	ability_manager.set(property_name, value + amount)


func _apply_attack_speed_upgrade() -> void:
	if auto_attack == null:
		push_warning("UpgradeManager is missing AutoAttack reference.")
		return

	var value = auto_attack.get("attack_interval")
	if value == null:
		push_warning("AutoAttack is missing attack_interval.")
		return

	auto_attack.set("attack_interval", maxf(ATTACK_INTERVAL_MIN, value - 0.08))


func _apply_nova_cooldown_upgrade() -> void:
	if ability_manager == null:
		push_warning("UpgradeManager is missing AbilityManager reference.")
		return

	var value = ability_manager.get("nova_cooldown")
	if value == null:
		push_warning("AbilityManager is missing nova_cooldown.")
		return

	ability_manager.set("nova_cooldown", maxf(NOVA_COOLDOWN_MIN, value - 0.5))


func _apply_max_health_upgrade() -> void:
	if player == null:
		push_warning("UpgradeManager is missing Player reference.")
		return

	var max_health = player.get("max_health")
	var current_health = player.get("current_health")
	if max_health == null or current_health == null:
		push_warning("Player is missing health properties.")
		return

	var health_increase := 20
	player.set("max_health", max_health + health_increase)
	player.set("current_health", min(current_health + health_increase, player.get("max_health")))

	if player.has_signal("health_changed"):
		player.health_changed.emit(player.get("current_health"), player.get("max_health"))
