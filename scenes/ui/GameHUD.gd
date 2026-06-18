extends CanvasLayer

var player: Node

@onready var health_bar: ProgressBar = get_node_or_null("Root/HealthPanel/PlayerHealthBar")
@onready var health_label: Label = get_node_or_null("Root/HealthPanel/PlayerHealthLabel")

func setup(new_player: Node) -> void:
	player = new_player

	if player == null:
		push_warning("GameHUD setup called without a player.")
		return

	var current_health = player.get("current_health")
	var max_health = player.get("max_health")
	if current_health == null or max_health == null:
		push_warning("GameHUD player is missing current_health or max_health.")
		return

	_update_player_health(int(current_health), int(max_health))

	if player.has_signal("health_changed") and not player.health_changed.is_connected(_update_player_health):
		player.health_changed.connect(_update_player_health)


func _update_player_health(current_health: int, max_health: int) -> void:
	if health_bar != null:
		health_bar.max_value = max_health
		health_bar.value = current_health

	if health_label != null:
		health_label.text = "%d / %d" % [current_health, max_health]
