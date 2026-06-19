extends Node

@export var arena_scene: PackedScene
@export var main_menu_scene: PackedScene

var current_run: Node
var main_menu: Node
var settings_manager: Node
var audio_manager: Node
var hero_data_provider: Node
var character_select: Node
var meta_progression_manager: Node
var post_run_rewards_screen: Node
var meta_upgrade_shop: Node
var selected_hero_id: String = ""

var _last_reward_data: Dictionary = {}
var _rewards_shown: bool = true
var _pending_action: String = ""

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

	_init_meta_progression_manager()
	_init_post_run_rewards_screen()
	_init_meta_upgrade_shop()

	if character_select != null:
		if character_select.has_method("setup"):
			character_select.setup(hero_data_provider, meta_progression_manager)
		if character_select.has_signal("hero_confirmed") and not character_select.hero_confirmed.is_connected(_on_hero_confirmed):
			character_select.hero_confirmed.connect(_on_hero_confirmed)
		if character_select.has_signal("back_requested") and not character_select.back_requested.is_connected(_on_character_select_back_requested):
			character_select.back_requested.connect(_on_character_select_back_requested)

	_show_main_menu()


func _init_meta_progression_manager() -> void:
	var scene: PackedScene = load("res://scenes/meta/MetaProgressionManager.tscn")
	if scene == null:
		push_warning("Main: MetaProgressionManager.tscn not found.")
		return
	meta_progression_manager = scene.instantiate()
	add_child(meta_progression_manager)


func _init_post_run_rewards_screen() -> void:
	var scene: PackedScene = load("res://scenes/ui/PostRunRewardsScreen.tscn")
	if scene == null:
		push_warning("Main: PostRunRewardsScreen.tscn not found.")
		return
	post_run_rewards_screen = scene.instantiate()
	add_child(post_run_rewards_screen)
	if post_run_rewards_screen.has_signal("continue_requested") and not post_run_rewards_screen.continue_requested.is_connected(_on_post_run_continue):
		post_run_rewards_screen.continue_requested.connect(_on_post_run_continue)


func _init_meta_upgrade_shop() -> void:
	var scene: PackedScene = load("res://scenes/ui/MetaUpgradeShop.tscn")
	if scene == null:
		push_warning("Main: MetaUpgradeShop.tscn not found.")
		return
	meta_upgrade_shop = scene.instantiate()
	add_child(meta_upgrade_shop)
	if meta_upgrade_shop.has_method("setup"):
		meta_upgrade_shop.setup(meta_progression_manager)
	if meta_upgrade_shop.has_signal("back_requested") and not meta_upgrade_shop.back_requested.is_connected(_close_meta_shop):
		meta_upgrade_shop.back_requested.connect(_close_meta_shop)
	if meta_upgrade_shop.has_signal("buy_requested") and not meta_upgrade_shop.buy_requested.is_connected(_on_meta_buy_requested):
		meta_upgrade_shop.buy_requested.connect(_on_meta_buy_requested)


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
	if main_menu.has_signal("meta_shop_requested") and not main_menu.meta_shop_requested.is_connected(_open_meta_shop):
		main_menu.meta_shop_requested.connect(_open_meta_shop)


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

	_last_reward_data = {}
	_rewards_shown = true

	if arena_scene == null:
		push_warning("Main is missing arena_scene.")
		return

	var selected_hero := _get_hero_data(hero_id)
	selected_hero_id = str(selected_hero.get("id", hero_id))
	current_run = arena_scene.instantiate()
	if current_run.has_method("setup"):
		current_run.setup(settings_manager, audio_manager, selected_hero, meta_progression_manager)
	add_child(current_run)

	if current_run.has_signal("run_result_ready") and not current_run.run_result_ready.is_connected(_on_run_result_ready):
		current_run.run_result_ready.connect(_on_run_result_ready)
	if current_run.has_signal("restart_run_requested") and not current_run.restart_run_requested.is_connected(_restart_run):
		current_run.restart_run_requested.connect(_restart_run)
	if current_run.has_signal("quit_to_menu_requested") and not current_run.quit_to_menu_requested.is_connected(_quit_to_menu):
		current_run.quit_to_menu_requested.connect(_quit_to_menu)


func _on_run_result_ready(summary: Dictionary) -> void:
	if meta_progression_manager == null or not meta_progression_manager.has_method("apply_run_result"):
		return
	var rewards: Dictionary = meta_progression_manager.apply_run_result(summary)
	rewards["result"] = str(summary.get("result", "defeat"))
	_last_reward_data = rewards
	_rewards_shown = false


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
	if not _check_and_show_rewards("restart"):
		_do_restart_run()


func _quit_to_menu() -> void:
	if not _check_and_show_rewards("quit_to_menu"):
		_do_quit_to_menu()


func _check_and_show_rewards(pending_action: String) -> bool:
	if _rewards_shown or _last_reward_data.is_empty():
		return false
	if post_run_rewards_screen == null or not post_run_rewards_screen.has_method("show_rewards"):
		return false
	_rewards_shown = true
	_pending_action = pending_action
	get_tree().paused = true
	var progress_summary := {}
	if meta_progression_manager != null and meta_progression_manager.has_method("get_progress_summary"):
		progress_summary = meta_progression_manager.get_progress_summary()
	post_run_rewards_screen.show_rewards(_last_reward_data, progress_summary)
	return true


func _on_post_run_continue() -> void:
	if post_run_rewards_screen != null and post_run_rewards_screen.has_method("hide_screen"):
		post_run_rewards_screen.hide_screen()
	get_tree().paused = false
	match _pending_action:
		"restart":
			_do_restart_run()
		_:
			_do_quit_to_menu()
	_pending_action = ""


func _do_restart_run() -> void:
	get_tree().paused = false
	_close_settings_menu_if_open()
	_clear_current_run()
	_start_run_with_hero(selected_hero_id)


func _do_quit_to_menu() -> void:
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


func _open_meta_shop() -> void:
	if meta_upgrade_shop == null:
		push_warning("Main: MetaUpgradeShop not initialized.")
		return
	if main_menu != null:
		main_menu.hide()
	if meta_upgrade_shop.has_method("open"):
		meta_upgrade_shop.open()


func _close_meta_shop() -> void:
	if meta_upgrade_shop != null and meta_upgrade_shop.has_method("close"):
		meta_upgrade_shop.close()
	if main_menu != null:
		main_menu.show()


func _on_meta_buy_requested(upgrade_id: String) -> void:
	if meta_progression_manager != null and meta_progression_manager.has_method("buy_meta_upgrade"):
		meta_progression_manager.buy_meta_upgrade(upgrade_id)


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
