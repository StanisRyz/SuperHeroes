extends Node

@export var arena_scene: PackedScene
@export var main_menu_scene: PackedScene

var current_run: Node
var main_menu: Node
var settings_manager: Node
var audio_manager: Node
var hero_data_provider: Node
var character_select: Node
var selected_hero_id: String = ""

@onready var settings_menu: Node = get_node_or_null("SettingsMenu")


func _ready() -> void:
	get_tree().paused = false
	settings_manager = get_node_or_null("SettingsManager")
	audio_manager = get_node_or_null("AudioManager")
	hero_data_provider = get_node_or_null("HeroDataProvider")
	character_select = get_node_or_null("CharacterSelect")

	if settings_manager != null and settings_manager.has_method("load_settings"):
		settings_manager.load_settings()

	if audio_manager != null and audio_manager.has_method("setup"):
		audio_manager.setup(settings_manager)

	if settings_menu != null and settings_menu.has_method("setup"):
		settings_menu.setup(settings_manager, audio_manager)

	if character_select != null:
		if character_select.has_method("setup"):
			character_select.setup(hero_data_provider)
		if character_select.has_signal("hero_confirmed") and not character_select.hero_confirmed.is_connected(_on_hero_confirmed):
			character_select.hero_confirmed.connect(_on_hero_confirmed)
		if character_select.has_signal("back_requested") and not character_select.back_requested.is_connected(_on_character_select_back_requested):
			character_select.back_requested.connect(_on_character_select_back_requested)

	_show_main_menu()


func _show_main_menu() -> void:
	_clear_current_run()
	_clear_main_menu()
	if character_select != null and character_select.has_method("close"):
		character_select.close()

	if main_menu_scene == null:
		push_warning("Main is missing main_menu_scene.")
		return

	main_menu = main_menu_scene.instantiate()
	add_child(main_menu)

	if main_menu.has_method("setup"):
		main_menu.setup(settings_manager, audio_manager)

	if main_menu.has_signal("start_requested") and not main_menu.start_requested.is_connected(_show_character_select):
		main_menu.start_requested.connect(_show_character_select)
	if main_menu.has_signal("quit_requested") and not main_menu.quit_requested.is_connected(_on_quit_requested):
		main_menu.quit_requested.connect(_on_quit_requested)
	if main_menu.has_signal("settings_requested") and not main_menu.settings_requested.is_connected(_open_settings_menu):
		main_menu.settings_requested.connect(_open_settings_menu)


func _show_character_select() -> void:
	_close_settings_menu_if_open()
	if main_menu != null:
		main_menu.hide()
	if character_select != null and character_select.has_method("open"):
		character_select.open()
	else:
		_start_run_with_hero(selected_hero_id)


func _on_character_select_back_requested() -> void:
	if character_select != null and character_select.has_method("close"):
		character_select.close()
	if main_menu != null:
		main_menu.show()


func _on_hero_confirmed(hero_id: String) -> void:
	selected_hero_id = hero_id
	if character_select != null and character_select.has_method("close"):
		character_select.close()
	_start_run_with_hero(hero_id)


func _start_run_with_hero(hero_id: String) -> void:
	get_tree().paused = false
	_close_settings_menu_if_open()
	_clear_main_menu()
	_clear_current_run()

	if arena_scene == null:
		push_warning("Main is missing arena_scene.")
		return

	var selected_hero := _get_hero_data(hero_id)
	selected_hero_id = str(selected_hero.get("id", hero_id))
	current_run = arena_scene.instantiate()
	if current_run.has_method("setup"):
		current_run.setup(settings_manager, audio_manager, selected_hero)
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
	_close_settings_menu_if_open()
	_clear_current_run()
	_start_run_with_hero(selected_hero_id)


func _quit_to_menu() -> void:
	get_tree().paused = false
	_close_settings_menu_if_open()
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


func _close_settings_menu_if_open() -> void:
	if settings_menu == null or not settings_menu.visible:
		return

	if settings_menu.has_method("close"):
		settings_menu.close()
	else:
		settings_menu.hide()


func _get_hero_data(hero_id: String) -> Dictionary:
	if hero_data_provider == null:
		return {}
	if hero_id.is_empty() and hero_data_provider.has_method("get_default_hero"):
		return hero_data_provider.get_default_hero()
	if hero_data_provider.has_method("is_valid_hero") and hero_data_provider.is_valid_hero(hero_id):
		if hero_data_provider.has_method("get_hero"):
			return hero_data_provider.get_hero(hero_id)
	if hero_data_provider.has_method("get_default_hero"):
		return hero_data_provider.get_default_hero()
	return {}
