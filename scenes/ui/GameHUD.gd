extends CanvasLayer

var player: Node

@onready var health_bar: ProgressBar = get_node_or_null("Root/HealthPanel/PlayerHealthBar")
@onready var health_label: Label = get_node_or_null("Root/HealthPanel/PlayerHealthLabel")
@onready var experience_bar: ProgressBar = get_node_or_null("Root/ExperiencePanel/ExperienceBar")
@onready var experience_title: Label = get_node_or_null("Root/ExperiencePanel/ExperienceTitle")
@onready var experience_label: Label = get_node_or_null("Root/ExperiencePanel/ExperienceLabel")
@onready var run_time_label: Label = get_node_or_null("Root/RunPanel/RunTimeLabel")
@onready var kill_count_label: Label = get_node_or_null("Root/RunPanel/KillCountLabel")

func setup(new_player: Node, run_manager: Node = null) -> void:
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

	var current_xp = player.get("current_xp")
	var xp_to_next_level = player.get("xp_to_next_level")
	var level = player.get("level")
	if current_xp != null and xp_to_next_level != null and level != null:
		_update_player_experience(int(current_xp), int(xp_to_next_level), int(level))
	elif experience_bar != null:
		push_warning("GameHUD player is missing current_xp, xp_to_next_level, or level.")

	if player.has_signal("experience_changed") and not player.experience_changed.is_connected(_update_player_experience):
		player.experience_changed.connect(_update_player_experience)

	_setup_run_manager(run_manager)


func _update_player_health(current_health: int, max_health: int) -> void:
	if health_bar != null:
		health_bar.max_value = max_health
		health_bar.value = current_health

	if health_label != null:
		health_label.text = "%d / %d" % [current_health, max_health]


func _update_player_experience(current_xp: int, xp_to_next_level: int, level: int) -> void:
	if experience_bar != null:
		experience_bar.max_value = xp_to_next_level
		experience_bar.value = current_xp

	if experience_title != null:
		experience_title.text = "Level %d" % level

	if experience_label != null:
		experience_label.text = "XP %d / %d" % [current_xp, xp_to_next_level]


func _setup_run_manager(run_manager: Node) -> void:
	if run_manager == null:
		_update_run_time(0.0)
		_update_kill_count(0)
		return

	var run_time = run_manager.get("run_time")
	var kill_count = run_manager.get("kill_count")
	_update_run_time(float(run_time) if run_time != null else 0.0)
	_update_kill_count(int(kill_count) if kill_count != null else 0)

	if run_manager.has_signal("run_time_changed") and not run_manager.run_time_changed.is_connected(_update_run_time):
		run_manager.run_time_changed.connect(_update_run_time)
	if run_manager.has_signal("kill_count_changed") and not run_manager.kill_count_changed.is_connected(_update_kill_count):
		run_manager.kill_count_changed.connect(_update_kill_count)


func _update_run_time(seconds: float) -> void:
	if run_time_label != null:
		run_time_label.text = "Time %s" % _format_time(seconds)


func _update_kill_count(kills: int) -> void:
	if kill_count_label != null:
		kill_count_label.text = "Enemies defeated %d" % kills


func _format_time(seconds: float) -> String:
	var total_seconds := int(floor(seconds))
	var minutes := total_seconds / 60
	var remaining_seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, remaining_seconds]
