extends Node

@export var arena_scene: PackedScene
@export var main_menu_scene: PackedScene

var current_run: Node
var main_menu: Node
var settings_manager: Node
var audio_manager: Node
var user_preferences_manager: Node
var hero_data_provider: Node
var character_select: Node
var stage_data_provider: Node
var stage_select: Node
var run_briefing_screen: Node
var meta_progression_manager: Node
var post_run_rewards_screen: Node
var meta_upgrade_shop: Node
var hero_collection_screen: Node
var selected_hero_id: String = ""
var selected_stage_id: String = ""

var _last_reward_data: Dictionary = {}
var _rewards_shown: bool = true
var _pending_action: String = ""
var _selection_transition_in_progress: bool = false

@onready var settings_menu: Node = get_node_or_null("SettingsMenu")
@onready var controls_help_overlay: Node = get_node_or_null("ControlsHelpOverlay")


func _ready() -> void:
	get_tree().paused = false
	settings_manager = get_node_or_null("SettingsManager")
	audio_manager = get_node_or_null("AudioManager")
	user_preferences_manager = get_node_or_null("UserPreferencesManager")
	hero_data_provider = get_node_or_null("HeroDataProvider")
	character_select = get_node_or_null("CharacterSelect")
	stage_data_provider = get_node_or_null("StageDataProvider")
	stage_select = get_node_or_null("StageSelect")

	if settings_manager != null and settings_manager.has_method("load_settings"):
		settings_manager.load_settings()

	if user_preferences_manager != null and user_preferences_manager.has_method("load_preferences"):
		user_preferences_manager.load_preferences()
	if user_preferences_manager != null and user_preferences_manager.has_signal("last_choices_changed"):
		if not user_preferences_manager.last_choices_changed.is_connected(_on_last_choices_changed):
			user_preferences_manager.last_choices_changed.connect(_on_last_choices_changed)

	if audio_manager != null and audio_manager.has_method("setup"):
		audio_manager.setup(settings_manager)

	if settings_menu != null and settings_menu.has_method("setup"):
		settings_menu.setup(settings_manager, audio_manager)
	if settings_menu != null and settings_menu.has_signal("closed"):
		if not settings_menu.closed.is_connected(_on_settings_menu_closed):
			settings_menu.closed.connect(_on_settings_menu_closed)

	if controls_help_overlay != null and controls_help_overlay.has_signal("closed"):
		if not controls_help_overlay.closed.is_connected(_on_controls_help_closed):
			controls_help_overlay.closed.connect(_on_controls_help_closed)

	_init_meta_progression_manager()
	_init_run_briefing_screen()
	_init_post_run_rewards_screen()
	_init_meta_upgrade_shop()
	_init_hero_collection_screen()

	if character_select != null:
		if character_select.has_method("setup"):
			character_select.setup(hero_data_provider, meta_progression_manager, user_preferences_manager)
		if character_select.has_signal("hero_confirmed") and not character_select.hero_confirmed.is_connected(_on_hero_confirmed):
			character_select.hero_confirmed.connect(_on_hero_confirmed)
		if character_select.has_signal("back_requested") and not character_select.back_requested.is_connected(_on_character_select_back_requested):
			character_select.back_requested.connect(_on_character_select_back_requested)

	if stage_select != null:
		if stage_select.has_method("setup"):
			stage_select.setup(stage_data_provider, user_preferences_manager)
		if stage_select.has_signal("stage_confirmed") and not stage_select.stage_confirmed.is_connected(_on_stage_confirmed):
			stage_select.stage_confirmed.connect(_on_stage_confirmed)
		if stage_select.has_signal("back_requested") and not stage_select.back_requested.is_connected(_on_stage_select_back_requested):
			stage_select.back_requested.connect(_on_stage_select_back_requested)

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


func _init_run_briefing_screen() -> void:
	var scene: PackedScene = load("res://scenes/ui/RunBriefingScreen.tscn")
	if scene == null:
		push_warning("Main: RunBriefingScreen.tscn not found.")
		return
	run_briefing_screen = scene.instantiate()
	add_child(run_briefing_screen)
	if run_briefing_screen.has_signal("start_requested") and not run_briefing_screen.start_requested.is_connected(_on_run_briefing_start_requested):
		run_briefing_screen.start_requested.connect(_on_run_briefing_start_requested)
	if run_briefing_screen.has_signal("back_requested") and not run_briefing_screen.back_requested.is_connected(_on_run_briefing_back_requested):
		run_briefing_screen.back_requested.connect(_on_run_briefing_back_requested)


func _init_meta_upgrade_shop() -> void:
	var scene: PackedScene = load("res://scenes/ui/MetaUpgradeShop.tscn")
	if scene == null:
		push_warning("Main: MetaUpgradeShop.tscn not found.")
		return
	meta_upgrade_shop = scene.instantiate()
	add_child(meta_upgrade_shop)
	if meta_upgrade_shop.has_method("setup"):
		meta_upgrade_shop.setup(meta_progression_manager, hero_data_provider)
	if meta_upgrade_shop.has_signal("back_requested") and not meta_upgrade_shop.back_requested.is_connected(_close_meta_shop):
		meta_upgrade_shop.back_requested.connect(_close_meta_shop)
	if meta_upgrade_shop.has_signal("buy_requested") and not meta_upgrade_shop.buy_requested.is_connected(_on_meta_buy_requested):
		meta_upgrade_shop.buy_requested.connect(_on_meta_buy_requested)
	if meta_upgrade_shop.has_signal("equipment_buy_requested") and not meta_upgrade_shop.equipment_buy_requested.is_connected(_on_equipment_buy_requested):
		meta_upgrade_shop.equipment_buy_requested.connect(_on_equipment_buy_requested)


func _init_hero_collection_screen() -> void:
	var scene: PackedScene = load("res://scenes/ui/HeroCollectionScreen.tscn")
	if scene == null:
		push_warning("Main: HeroCollectionScreen.tscn not found.")
		return
	hero_collection_screen = scene.instantiate()
	add_child(hero_collection_screen)
	if hero_collection_screen.has_method("setup"):
		hero_collection_screen.setup(meta_progression_manager, hero_data_provider)
	if hero_collection_screen.has_signal("back_requested") and not hero_collection_screen.back_requested.is_connected(_close_hero_collection):
		hero_collection_screen.back_requested.connect(_close_hero_collection)


func _show_main_menu() -> void:
	_selection_transition_in_progress = false
	_clear_current_run()
	_clear_main_menu()
	if character_select != null and character_select.has_method("close"):
		character_select.close()
	if stage_select != null and stage_select.has_method("close"):
		stage_select.close()
	if run_briefing_screen != null and run_briefing_screen.has_method("close"):
		run_briefing_screen.close()

	if main_menu_scene == null:
		push_warning("Main is missing main_menu_scene.")
		return

	main_menu = main_menu_scene.instantiate()
	add_child(main_menu)

	if main_menu.has_method("setup"):
		main_menu.setup(settings_manager, audio_manager)
	if main_menu.has_method("set_last_choice_hint"):
		var hint_names := _get_last_choice_hint_names()
		main_menu.set_last_choice_hint(str(hint_names.get("hero_name", "")), str(hint_names.get("stage_name", "")))

	if main_menu.has_signal("start_requested") and not main_menu.start_requested.is_connected(_show_character_select):
		main_menu.start_requested.connect(_show_character_select)
	if main_menu.has_signal("quit_requested") and not main_menu.quit_requested.is_connected(_on_quit_requested):
		main_menu.quit_requested.connect(_on_quit_requested)
	if main_menu.has_signal("settings_requested") and not main_menu.settings_requested.is_connected(_open_settings_menu):
		main_menu.settings_requested.connect(_open_settings_menu)
	if main_menu.has_signal("meta_shop_requested") and not main_menu.meta_shop_requested.is_connected(_open_meta_shop):
		main_menu.meta_shop_requested.connect(_open_meta_shop)
	if main_menu.has_signal("collection_requested") and not main_menu.collection_requested.is_connected(_open_hero_collection):
		main_menu.collection_requested.connect(_open_hero_collection)
	if main_menu.has_signal("help_requested") and not main_menu.help_requested.is_connected(_open_controls_help):
		main_menu.help_requested.connect(_open_controls_help)


func _input(event: InputEvent) -> void:
	if current_run != null:
		return
	if event is InputEventKey and event.echo:
		return

	if event.is_action_pressed("help_toggle"):
		if _is_settings_open() or _is_meta_shop_open():
			return
		_toggle_controls_help()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		_handle_menu_back_requested()
		get_viewport().set_input_as_handled()


func _show_character_select() -> void:
	if _selection_transition_in_progress:
		return
	_selection_transition_in_progress = true
	_close_settings_menu_if_open()
	_refresh_selection_preferences()
	if main_menu != null:
		main_menu.hide()
	if character_select != null and character_select.has_method("open"):
		character_select.open()
	else:
		_show_stage_select()
	_selection_transition_in_progress = false


func _on_character_select_back_requested() -> void:
	if _selection_transition_in_progress:
		return
	if character_select != null and character_select.has_method("close"):
		character_select.close()
	if main_menu != null:
		main_menu.show()


func _on_hero_confirmed(hero_id: String) -> void:
	if _selection_transition_in_progress:
		return
	_selection_transition_in_progress = true
	selected_hero_id = hero_id
	if user_preferences_manager != null and user_preferences_manager.has_method("set_last_hero_id"):
		user_preferences_manager.set_last_hero_id(hero_id)
	if character_select != null and character_select.has_method("close"):
		character_select.close()
	_show_stage_select()
	_selection_transition_in_progress = false


func _show_stage_select() -> void:
	_refresh_selection_preferences()
	if run_briefing_screen != null and run_briefing_screen.has_method("close"):
		run_briefing_screen.close()
	if stage_select != null and stage_select.has_method("open"):
		stage_select.open()
	else:
		_show_run_briefing_or_start()


func _on_stage_confirmed(stage_id: String) -> void:
	if _selection_transition_in_progress:
		return
	_selection_transition_in_progress = true
	selected_stage_id = stage_id
	if user_preferences_manager != null and user_preferences_manager.has_method("set_last_stage_id"):
		user_preferences_manager.set_last_stage_id(stage_id)
	if stage_select != null and stage_select.has_method("close"):
		stage_select.close()
	_show_run_briefing_or_start()
	_selection_transition_in_progress = false


func _show_run_briefing_or_start() -> void:
	if run_briefing_screen == null or not run_briefing_screen.has_method("setup") or not run_briefing_screen.has_method("open"):
		_start_run_with_hero_and_stage(selected_hero_id, selected_stage_id)
		return
	var selected_hero := _get_hero_data(selected_hero_id)
	selected_hero_id = str(selected_hero.get("id", selected_hero_id))
	var selected_stage := _get_stage_data(selected_stage_id)
	selected_stage_id = str(selected_stage.get("id", selected_stage_id))
	run_briefing_screen.setup(selected_hero, selected_stage, meta_progression_manager)
	run_briefing_screen.open()


func _on_run_briefing_start_requested() -> void:
	if _selection_transition_in_progress:
		return
	_selection_transition_in_progress = true
	if run_briefing_screen != null and run_briefing_screen.has_method("close"):
		run_briefing_screen.close()
	_start_run_with_hero_and_stage(selected_hero_id, selected_stage_id)


func _on_run_briefing_back_requested() -> void:
	if _selection_transition_in_progress:
		return
	if run_briefing_screen != null and run_briefing_screen.has_method("close"):
		run_briefing_screen.close()
	_show_stage_select()


func _on_stage_select_back_requested() -> void:
	if _selection_transition_in_progress:
		return
	if stage_select != null and stage_select.has_method("close"):
		stage_select.close()
	if character_select != null and character_select.has_method("open"):
		character_select.open()
	else:
		if main_menu != null:
			main_menu.show()


func _start_run_with_hero_and_stage(hero_id: String, stage_id: String) -> void:
	get_tree().paused = false
	_close_settings_menu_if_open()
	_clear_main_menu()
	_clear_current_run()

	_last_reward_data = {}
	_rewards_shown = true

	if arena_scene == null:
		push_warning("Main is missing arena_scene.")
		_selection_transition_in_progress = false
		return

	var selected_hero := _get_hero_data(hero_id)
	selected_hero_id = str(selected_hero.get("id", hero_id))

	var selected_stage := _get_stage_data(stage_id)
	selected_stage_id = str(selected_stage.get("id", stage_id))

	current_run = arena_scene.instantiate()
	if current_run.has_method("setup"):
		current_run.setup(settings_manager, audio_manager, selected_hero, meta_progression_manager, selected_stage)
	add_child(current_run)

	if current_run.has_signal("run_result_ready") and not current_run.run_result_ready.is_connected(_on_run_result_ready):
		current_run.run_result_ready.connect(_on_run_result_ready)
	if current_run.has_signal("restart_run_requested") and not current_run.restart_run_requested.is_connected(_restart_run):
		current_run.restart_run_requested.connect(_restart_run)
	if current_run.has_signal("quit_to_menu_requested") and not current_run.quit_to_menu_requested.is_connected(_quit_to_menu):
		current_run.quit_to_menu_requested.connect(_quit_to_menu)
	_selection_transition_in_progress = false


func _on_run_result_ready(summary: Dictionary) -> void:
	if meta_progression_manager == null or not meta_progression_manager.has_method("apply_run_result"):
		return
	var rewards: Dictionary = meta_progression_manager.apply_run_result(summary)
	rewards["result"] = str(summary.get("result", "defeat"))
	rewards["run_summary"] = summary.duplicate(true)
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
	if not _pending_action.is_empty():
		return
	if not _check_and_show_rewards("restart"):
		_do_restart_run()


func _quit_to_menu() -> void:
	if not _pending_action.is_empty():
		return
	if not _check_and_show_rewards("quit_to_menu"):
		_do_quit_to_menu()


func _check_and_show_rewards(pending_action: String) -> bool:
	if not _pending_action.is_empty():
		return true
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
	if _pending_action.is_empty():
		return
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
	_start_run_with_hero_and_stage(selected_hero_id, selected_stage_id)


func _do_quit_to_menu() -> void:
	get_tree().paused = false
	_close_settings_menu_if_open()
	_clear_current_run()
	selected_stage_id = ""
	_show_main_menu()


func _on_quit_requested() -> void:
	get_tree().quit()


func _open_settings_menu() -> void:
	if settings_menu == null:
		push_warning("Main could not find SettingsMenu node.")
		return
	if settings_menu.has_method("open"):
		settings_menu.open()


func _on_settings_menu_closed() -> void:
	if current_run == null and main_menu != null:
		main_menu.show()


func _close_settings_menu_if_open() -> void:
	if settings_menu == null or not settings_menu.visible:
		return
	if settings_menu.has_method("close"):
		settings_menu.close()
	else:
		settings_menu.hide()


func _open_controls_help() -> void:
	if controls_help_overlay != null and controls_help_overlay.has_method("open"):
		controls_help_overlay.open()


func _toggle_controls_help() -> void:
	if controls_help_overlay != null and controls_help_overlay.has_method("toggle"):
		controls_help_overlay.toggle()


func _on_controls_help_closed() -> void:
	pass


func _handle_menu_back_requested() -> void:
	if _is_controls_help_open():
		if controls_help_overlay != null and controls_help_overlay.has_method("close"):
			controls_help_overlay.close()
		return
	if _is_settings_open():
		_close_settings_menu_if_open()
		return
	if _is_meta_shop_open():
		_close_meta_shop()
		return
	if _is_hero_collection_open():
		_close_hero_collection()
		return
	if run_briefing_screen != null and run_briefing_screen.visible:
		_on_run_briefing_back_requested()
		return
	if stage_select != null and stage_select.visible:
		_on_stage_select_back_requested()
		return
	if character_select != null and character_select.visible:
		_on_character_select_back_requested()
		return


func _is_settings_open() -> bool:
	if settings_menu == null:
		return false
	if settings_menu.has_method("is_open"):
		return settings_menu.is_open()
	return settings_menu.visible


func _is_meta_shop_open() -> bool:
	return meta_upgrade_shop != null and meta_upgrade_shop.visible


func _is_hero_collection_open() -> bool:
	return hero_collection_screen != null and hero_collection_screen.visible


func _is_controls_help_open() -> bool:
	if controls_help_overlay == null:
		return false
	if controls_help_overlay.has_method("is_open"):
		return controls_help_overlay.is_open()
	return controls_help_overlay.visible


func _open_meta_shop() -> void:
	if meta_upgrade_shop == null:
		push_warning("Main: MetaUpgradeShop not initialized.")
		return
	if main_menu != null:
		main_menu.hide()
	if meta_upgrade_shop.has_method("open"):
		meta_upgrade_shop.open(_resolve_training_hero_id())


func _close_meta_shop() -> void:
	if meta_upgrade_shop != null and meta_upgrade_shop.has_method("close"):
		meta_upgrade_shop.close()
	if main_menu != null:
		main_menu.show()


func _open_hero_collection() -> void:
	if hero_collection_screen == null:
		push_warning("Main: HeroCollectionScreen not initialized.")
		return
	if _is_meta_shop_open() or _is_settings_open() or _is_controls_help_open():
		return
	if character_select != null and character_select.visible:
		return
	if stage_select != null and stage_select.visible:
		return
	if run_briefing_screen != null and run_briefing_screen.visible:
		return
	if main_menu != null:
		main_menu.hide()
	if hero_collection_screen.has_method("open"):
		hero_collection_screen.open()


func _close_hero_collection() -> void:
	if hero_collection_screen != null and hero_collection_screen.has_method("close"):
		hero_collection_screen.close()
	if main_menu != null:
		main_menu.show()


func _on_meta_buy_requested(hero_id: String, upgrade_id: String) -> void:
	if meta_progression_manager != null and meta_progression_manager.has_method("purchase_training_upgrade"):
		meta_progression_manager.purchase_training_upgrade(hero_id, upgrade_id)


func _on_equipment_buy_requested(hero_id: String, equipment_id: String) -> void:
	if meta_progression_manager != null and meta_progression_manager.has_method("purchase_equipment_upgrade"):
		meta_progression_manager.purchase_equipment_upgrade(hero_id, equipment_id)


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


func _resolve_training_hero_id() -> String:
	if hero_data_provider != null and hero_data_provider.has_method("is_valid_hero"):
		if not selected_hero_id.is_empty() and hero_data_provider.is_valid_hero(selected_hero_id):
			return selected_hero_id
		if user_preferences_manager != null and user_preferences_manager.has_method("get_last_hero_id"):
			var remembered: String = user_preferences_manager.get_last_hero_id()
			if not remembered.is_empty() and hero_data_provider.is_valid_hero(remembered):
				return remembered
	if hero_data_provider != null and hero_data_provider.has_method("get_default_hero"):
		var default_hero: Dictionary = hero_data_provider.get_default_hero()
		return str(default_hero.get("id", "guardian"))
	return "guardian"


func _get_stage_data(stage_id: String) -> Dictionary:
	if stage_data_provider == null:
		return {}
	if stage_id.is_empty() and stage_data_provider.has_method("get_default_stage"):
		return stage_data_provider.get_default_stage()
	if stage_data_provider.has_method("is_valid_stage") and stage_data_provider.is_valid_stage(stage_id):
		if stage_data_provider.has_method("get_stage"):
			return stage_data_provider.get_stage(stage_id)
	if stage_data_provider.has_method("get_default_stage"):
		return stage_data_provider.get_default_stage()
	return {}


func _on_last_choices_changed(_hero_id: String, _stage_id: String) -> void:
	_refresh_selection_preferences()
	if main_menu != null and main_menu.has_method("set_last_choice_hint"):
		var hint_names := _get_last_choice_hint_names()
		main_menu.set_last_choice_hint(str(hint_names.get("hero_name", "")), str(hint_names.get("stage_name", "")))


func _get_last_choice_hint_names() -> Dictionary:
	var hero_id := ""
	var stage_id := ""
	if user_preferences_manager != null:
		if user_preferences_manager.has_method("get_last_hero_id"):
			hero_id = user_preferences_manager.get_last_hero_id()
		if user_preferences_manager.has_method("get_last_stage_id"):
			stage_id = user_preferences_manager.get_last_stage_id()

	return {
		"hero_name": _get_hero_display_name(hero_id),
		"stage_name": _get_stage_display_name(stage_id),
	}


func _get_hero_display_name(hero_id: String) -> String:
	if hero_id.is_empty() or hero_data_provider == null:
		return ""
	if hero_data_provider.has_method("get_hero"):
		var hero: Dictionary = hero_data_provider.get_hero(hero_id)
		return str(hero.get("display_name", ""))
	return ""


func _get_stage_display_name(stage_id: String) -> String:
	if stage_id.is_empty() or stage_data_provider == null:
		return ""
	if stage_data_provider.has_method("get_stage"):
		var stage: Dictionary = stage_data_provider.get_stage(stage_id)
		return str(stage.get("display_name", ""))
	return ""


func _refresh_selection_preferences() -> void:
	if user_preferences_manager == null:
		return
	if character_select != null and character_select.has_method("set_preferred_hero_id") and user_preferences_manager.has_method("get_last_hero_id"):
		character_select.set_preferred_hero_id(user_preferences_manager.get_last_hero_id())
	if stage_select != null and stage_select.has_method("set_preferred_stage_id") and user_preferences_manager.has_method("get_last_stage_id"):
		stage_select.set_preferred_stage_id(user_preferences_manager.get_last_stage_id())
