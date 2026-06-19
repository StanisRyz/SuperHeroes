extends CanvasLayer

signal start_requested
signal quit_requested

@onready var start_button: Button = get_node_or_null("Root/Panel/VBoxContainer/StartButton")
@onready var quit_button: Button = get_node_or_null("Root/Panel/VBoxContainer/QuitButton")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false

	if start_button == null:
		push_warning("MainMenu could not find StartButton.")
	elif not start_button.pressed.is_connected(_on_start_button_pressed):
		start_button.pressed.connect(_on_start_button_pressed)

	if quit_button != null and not quit_button.pressed.is_connected(_on_quit_button_pressed):
		quit_button.pressed.connect(_on_quit_button_pressed)


func _on_start_button_pressed() -> void:
	start_requested.emit()


func _on_quit_button_pressed() -> void:
	quit_requested.emit()
