extends CanvasLayer

signal resume_requested
signal restart_requested
signal quit_to_menu_requested
signal settings_requested
signal help_requested

var audio_manager: Node

@onready var resume_button: Button = get_node_or_null("Root/Panel/VBoxContainer/ResumeButton")
@onready var settings_button: Button = get_node_or_null("Root/Panel/VBoxContainer/SettingsButton")
@onready var help_button: Button = get_node_or_null("Root/Panel/VBoxContainer/HelpButton")
@onready var restart_button: Button = get_node_or_null("Root/Panel/VBoxContainer/RestartButton")
@onready var quit_button: Button = get_node_or_null("Root/Panel/VBoxContainer/QuitButton")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	hide()

	if resume_button == null:
		push_warning("PauseMenu could not find ResumeButton.")
	elif not resume_button.pressed.is_connected(_on_resume_button_pressed):
		resume_button.pressed.connect(_on_resume_button_pressed)

	if settings_button == null:
		push_warning("PauseMenu could not find SettingsButton.")
	elif not settings_button.pressed.is_connected(_on_settings_button_pressed):
		settings_button.pressed.connect(_on_settings_button_pressed)

	if help_button == null:
		push_warning("PauseMenu could not find HelpButton.")
	elif not help_button.pressed.is_connected(_on_help_button_pressed):
		help_button.pressed.connect(_on_help_button_pressed)

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
	set_buttons_disabled(false)
	if resume_button != null:
		resume_button.grab_focus()


func close() -> void:
	hide()
	set_buttons_disabled(false)


func set_buttons_disabled(disabled: bool) -> void:
	for button in [resume_button, settings_button, help_button, restart_button, quit_button]:
		if button != null:
			button.disabled = disabled


func is_open() -> bool:
	return visible


func setup_audio_manager(new_audio_manager: Node = null) -> void:
	audio_manager = new_audio_manager


func _on_resume_button_pressed() -> void:
	_play_ui_click()
	resume_requested.emit()


func _on_settings_button_pressed() -> void:
	_play_ui_click()
	settings_requested.emit()


func _on_help_button_pressed() -> void:
	_play_ui_click()
	help_requested.emit()


func _on_restart_button_pressed() -> void:
	_play_ui_click()
	restart_requested.emit()


func _on_quit_button_pressed() -> void:
	_play_ui_click()
	quit_to_menu_requested.emit()


func _play_ui_click() -> void:
	if audio_manager != null and audio_manager.has_method("play_ui_click"):
		audio_manager.play_ui_click()
