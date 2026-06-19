extends Node

@export var arena_scene: PackedScene
@export var main_menu_scene: PackedScene

var current_run: Node
var main_menu: Node
var settings_manager: Node
var audio_manager: Node

@onready var settings_menu: Node = get_node_or_null("SettingsMenu")


func _ready() -> void:
	get_tree().paused = false
	settings_manager = get_node_or_null("SettingsManager")
	audio_manager = get_node_or_null("AudioManager")

	if settings_manager != null and settings_manager.has_method("load_settings"):
		settings_manager.load_settings()

	if audio_manager != null and audio_manager.has_method("setup"):
		audio_manager.setup(settings_manager)

	if settings_menu != null and settings_menu.has_method("setup"):
		settings_menu.setup(settings_manager, audio_manager)

	_show_main_menu()


func _show_main_menu() -> void:
	_clear_current_run()
	_clear_main_menu()

	if main_menu_scene == null:
		push_warning("Main is missing main_menu_scene.")
		return

	main_menu = main_menu_scene.instantiate()
	add_child(main_menu)

	if main_menu.has_method("setup"):
		main_menu.setup(settings_manager, audio_manager)

	if main_menu.has_signal("start_requested") and not main_menu.start_requested.is_connected(_start_run):
		main_menu.start_requested.connect(_start_run)
	if main_menu.has_signal("quit_requested") and not main_menu.quit_requested.is_connected(_on_quit_requested):
		main_menu.quit_requested.connect(_on_quit_requested)
	if main_menu.has_signal("settings_requested") and not main_menu.settings_requested.is_connected(_open_settings_menu):
		main_menu.settings_requested.connect(_open_settings_menu)


func _start_run() -> void:
	get_tree().paused = false
	_clear_main_menu()
	_clear_current_run()

	if arena_scene == null:
		push_warning("Main is missing arena_scene.")
		return

	current_run = arena_scene.instantiate()
	if current_run.has_method("setup"):
		current_run.setup(settings_manager, audio_manager)
	add_child(current_run)

	if current_run.has_signal("restart_run_requested") and not current_run.restart_run_requested.is_connected(_restart_run):
		current_run.restart_run_requested.connect(_restart_run)
	if current_run.has_signal("quit_to_menu_requested") and not current_run.quit_to_menu_requested.is_connected(_quit_to_menu):
		current_run.quit_to_menu_requested.connect(_quit_to_menu)


func _clear_current_run() -> void:
	if current_run == null:
		return

	if current_run.get_parent() == self:
		remove_child(current_run)
	current_run.queue_free()
	current_run = null


func _clear_main_menu() -> void:
	if main_menu == null:
		return

	if main_menu.get_parent() == self:
		remove_child(main_menu)
	main_menu.queue_free()
	main_menu = null


func _restart_run() -> void:
	get_tree().paused = false
	_clear_current_run()
	_start_run()


func _quit_to_menu() -> void:
	get_tree().paused = false
	_clear_current_run()
	_show_main_menu()


func _on_quit_requested() -> void:
	get_tree().quit()


func _open_settings_menu() -> void:
	if settings_menu == null:
		push_warning("Main could not find SettingsMenu node.")
		return

	if settings_menu.has_method("open"):
		settings_menu.open()
