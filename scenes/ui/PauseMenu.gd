extends CanvasLayer

signal resume_requested
signal restart_requested
signal quit_to_menu_requested

@onready var resume_button: Button = get_node_or_null("Root/Panel/VBoxContainer/ResumeButton")
@onready var restart_button: Button = get_node_or_null("Root/Panel/VBoxContainer/RestartButton")
@onready var quit_button: Button = get_node_or_null("Root/Panel/VBoxContainer/QuitButton")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	hide()

	if resume_button == null:
		push_warning("PauseMenu could not find ResumeButton.")
	elif not resume_button.pressed.is_connected(_on_resume_button_pressed):
		resume_button.pressed.connect(_on_resume_button_pressed)

	if restart_button == null:
		push_warning("PauseMenu could not find RestartButton.")
	elif not restart_button.pressed.is_connected(_on_restart_button_pressed):
		restart_button.pressed.connect(_on_restart_button_pressed)

	if quit_button == null:
		push_warning("PauseMenu could not find QuitButton.")
	elif not quit_button.pressed.is_connected(_on_quit_button_pressed):
		quit_button.pressed.connect(_on_quit_button_pressed)


func open() -> void:
	show()
	if resume_button != null:
		resume_button.grab_focus()


func close() -> void:
	hide()


func _on_resume_button_pressed() -> void:
	resume_requested.emit()


func _on_restart_button_pressed() -> void:
	restart_requested.emit()


func _on_quit_button_pressed() -> void:
	quit_to_menu_requested.emit()
