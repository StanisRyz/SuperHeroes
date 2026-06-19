extends CanvasLayer

signal restart_requested

var audio_manager: Node

@onready var time_label: Label = get_node_or_null("Root/Panel/VBoxContainer/TimeLabel")
@onready var kills_label: Label = get_node_or_null("Root/Panel/VBoxContainer/KillsLabel")
@onready var level_label: Label = get_node_or_null("Root/Panel/VBoxContainer/LevelLabel")
@onready var restart_button: Button = get_node_or_null("Root/Panel/VBoxContainer/RestartButton")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	hide()

	if restart_button == null:
		push_warning("GameOverScreen could not find RestartButton.")
	elif not restart_button.pressed.is_connected(_on_restart_button_pressed):
		restart_button.pressed.connect(_on_restart_button_pressed)


func show_stats(stats: Dictionary) -> void:
	var run_time := float(stats.get("run_time", 0.0))
	var kill_count := int(stats.get("kill_count", 0))
	var level := int(stats.get("level", 1))

	if time_label != null:
		time_label.text = "Time: %s" % _format_time(run_time)
	if kills_label != null:
		kills_label.text = "Enemies defeated: %d" % kill_count
	if level_label != null:
		level_label.text = "Level reached: %d" % level

	show()
	if restart_button != null:
		restart_button.grab_focus()


func setup_audio_manager(new_audio_manager: Node) -> void:
	audio_manager = new_audio_manager


func _format_time(seconds: float) -> String:
	var total_seconds := int(floor(seconds))
	var minutes := int(total_seconds / 60.0)
	var remaining_seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, remaining_seconds]


func _on_restart_button_pressed() -> void:
	if audio_manager != null and audio_manager.has_method("play_ui_click"):
		audio_manager.play_ui_click()
	restart_requested.emit()
