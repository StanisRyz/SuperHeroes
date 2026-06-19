extends CanvasLayer

signal start_requested
signal quit_requested
signal settings_requested
signal meta_shop_requested

var settings_manager: Node
var audio_manager: Node

@onready var start_button: Button = get_node_or_null("Root/Panel/VBoxContainer/StartButton")
@onready var settings_button: Button = get_node_or_null("Root/Panel/VBoxContainer/SettingsButton")
@onready var training_button: Button = get_node_or_null("Root/Panel/VBoxContainer/TrainingButton")
@onready var quit_button: Button = get_node_or_null("Root/Panel/VBoxContainer/QuitButton")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false

	if start_button == null:
		push_warning("MainMenu could not find StartButton.")
	elif not start_button.pressed.is_connected(_on_start_button_pressed):
		start_button.pressed.connect(_on_start_button_pressed)

	if settings_button == null:
		push_warning("MainMenu could not find SettingsButton.")
	elif not settings_button.pressed.is_connected(_on_settings_button_pressed):
		settings_button.pressed.connect(_on_settings_button_pressed)

	if training_button != null and not training_button.pressed.is_connected(_on_training_button_pressed):
		training_button.pressed.connect(_on_training_button_pressed)

	if quit_button != null and not quit_button.pressed.is_connected(_on_quit_button_pressed):
		quit_button.pressed.connect(_on_quit_button_pressed)


func setup(new_settings_manager: Node = null, new_audio_manager: Node = null) -> void:
	settings_manager = new_settings_manager
	audio_manager = new_audio_manager


func _on_start_button_pressed() -> void:
	_play_ui_click()
	start_requested.emit()


func _on_settings_button_pressed() -> void:
	_play_ui_click()
	settings_requested.emit()


func _on_training_button_pressed() -> void:
	_play_ui_click()
	meta_shop_requested.emit()


func _on_quit_button_pressed() -> void:
	_play_ui_click()
	quit_requested.emit()


func _play_ui_click() -> void:
	if audio_manager != null and audio_manager.has_method("play_ui_click"):
		audio_manager.play_ui_click()
