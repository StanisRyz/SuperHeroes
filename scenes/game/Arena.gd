extends Node2D

signal restart_run_requested
signal quit_to_menu_requested

@export var arena_size: Vector2 = Vector2(4000.0, 4000.0)

var settings_manager: Node
var audio_manager: Node

@onready var player: Node = get_node_or_null("Player")
@onready var enemy_container: Node = get_node_or_null("EnemyContainer")
@onready var projectile_container: Node = get_node_or_null("ProjectileContainer")
@onready var pickup_container: Node = get_node_or_null("PickupContainer")
@onready var enemy_spawner: Node = get_node_or_null("EnemySpawner")
@onready var run_manager: Node = get_node_or_null("RunManager")
@onready var spawn_director: Node = get_node_or_null("SpawnDirector")
@onready var hud: Node = get_node_or_null("GameHUD")
@onready var upgrade_manager: Node = get_node_or_null("UpgradeManager")
@onready var level_up_screen: Node = get_node_or_null("LevelUpScreen")
@onready var game_over_screen: Node = get_node_or_null("GameOverScreen")
@onready var mobile_controls: Node = get_node_or_null("MobileControls")
@onready var floating_text_spawner: Node = get_node_or_null("FloatingTextSpawner")
@onready var pause_menu: Node = get_node_or_null("PauseMenu")
@onready var settings_menu: Node = get_node_or_null("SettingsMenu")


func setup(new_settings_manager: Node = null, new_audio_manager: Node = null) -> void:
	settings_manager = new_settings_manager
	audio_manager = new_audio_manager

func _ready() -> void:
	var playable_rect := get_playable_rect()

	if player == null:
		push_warning("Arena could not find Player node to apply playable bounds.")
		return

	if player.has_method("set_playable_rect"):
		player.set_playable_rect(playable_rect)
	else:
		push_warning("Player does not implement set_playable_rect(rect).")

	if player.has_method("set_camera_limits"):
		player.set_camera_limits(playable_rect)
	else:
		push_warning("Player does not implement set_camera_limits(rect).")
	_apply_settings()
	if settings_manager != null and settings_manager.has_signal("settings_changed") and not settings_manager.settings_changed.is_connected(_apply_settings):
		settings_manager.settings_changed.connect(_apply_settings)

	var ability_manager := player.get_node_or_null("AbilityManager")
	if ability_manager == null:
		push_warning("Arena could not find Player/AbilityManager node.")
	elif ability_manager.has_method("setup"):
		ability_manager.setup(player, enemy_container)
	else:
		push_warning("AbilityManager does not implement setup(player, enemy_container).")

	_setup_mobile_controls(ability_manager)

	if hud == null:
		push_warning("Arena could not find GameHUD node.")
	elif hud.has_method("setup"):
		hud.setup(player, run_manager, ability_manager)
	else:
		push_warning("GameHUD does not implement setup(player, run_manager, ability_manager).")

	var auto_attack := player.get_node_or_null("AutoAttack")
	_setup_spawn_director()
	_setup_level_up_flow(auto_attack, ability_manager)
	_setup_run_lifecycle()
	_setup_pause_menu()
	_setup_settings_menu()

	if projectile_container == null:
		push_warning("Arena could not find ProjectileContainer node.")
	elif auto_attack == null:
		push_warning("Arena could not find Player/AutoAttack node.")
	elif auto_attack.has_method("setup_projectile_container"):
		auto_attack.setup_projectile_container(projectile_container)
		if auto_attack.has_method("setup_audio_manager"):
			auto_attack.setup_audio_manager(audio_manager)
	else:
		push_warning("AutoAttack does not implement setup_projectile_container(container).")

	if enemy_container == null:
		push_warning("Arena could not find EnemyContainer node for spawned enemies.")
	elif pickup_container == null:
		push_warning("Arena could not find PickupContainer node for pickup drops.")
	elif enemy_spawner == null:
		push_warning("Arena could not find EnemySpawner node.")
	elif enemy_spawner.has_method("setup"):
		enemy_spawner.setup(player, playable_rect, enemy_container, pickup_container, run_manager, spawn_director, floating_text_spawner, audio_manager)
	else:
		push_warning("EnemySpawner does not implement setup(player, playable_rect, enemy_container, pickup_container, run_manager, spawn_director, floating_text_spawner).")


func get_playable_rect() -> Rect2:
	return Rect2(-arena_size * 0.5, arena_size)


func _setup_level_up_flow(auto_attack: Node, ability_manager: Node) -> void:
	if upgrade_manager == null:
		push_warning("Arena could not find UpgradeManager node.")
	elif upgrade_manager.has_method("setup"):
		upgrade_manager.setup(player, auto_attack, ability_manager)
	else:
		push_warning("UpgradeManager does not implement setup(player, auto_attack, ability_manager).")

	if player.has_signal("level_up_available") and not player.level_up_available.is_connected(_on_player_level_up_available):
		player.level_up_available.connect(_on_player_level_up_available)

	if level_up_screen == null:
		push_warning("Arena could not find LevelUpScreen node.")
	elif level_up_screen.has_signal("upgrade_selected") and not level_up_screen.upgrade_selected.is_connected(_on_upgrade_selected):
		level_up_screen.upgrade_selected.connect(_on_upgrade_selected)
		if level_up_screen.has_method("setup_audio_manager"):
			level_up_screen.setup_audio_manager(audio_manager)


func _setup_spawn_director() -> void:
	if spawn_director == null:
		push_warning("Arena could not find SpawnDirector node.")
	elif spawn_director.has_method("setup"):
		spawn_director.setup(run_manager)
	else:
		push_warning("SpawnDirector does not implement setup(run_manager).")


func _setup_mobile_controls(ability_manager: Node) -> void:
	if mobile_controls == null:
		push_warning("Arena could not find MobileControls node.")
		return

	if mobile_controls.has_signal("movement_changed"):
		if player.has_method("set_external_move_vector"):
			if not mobile_controls.movement_changed.is_connected(player.set_external_move_vector):
				mobile_controls.movement_changed.connect(player.set_external_move_vector)
		else:
			push_warning("Player does not implement set_external_move_vector(direction).")
	else:
		push_warning("MobileControls is missing movement_changed signal.")

	if mobile_controls.has_signal("ability_1_pressed"):
		if ability_manager != null and ability_manager.has_method("cast_ability_1"):
			if not mobile_controls.ability_1_pressed.is_connected(ability_manager.cast_ability_1):
				mobile_controls.ability_1_pressed.connect(ability_manager.cast_ability_1)
		else:
			push_warning("AbilityManager does not implement cast_ability_1().")
	else:
		push_warning("MobileControls is missing ability_1_pressed signal.")

	if mobile_controls.has_method("setup_ability_manager"):
		mobile_controls.setup_ability_manager(ability_manager)
	if mobile_controls.has_method("setup_player"):
		mobile_controls.setup_player(player)
	if mobile_controls.has_method("apply_settings"):
		mobile_controls.apply_settings(settings_manager)

	if mobile_controls.has_signal("pause_pressed"):
		if not mobile_controls.pause_pressed.is_connected(_request_pause_menu):
			mobile_controls.pause_pressed.connect(_request_pause_menu)
	if mobile_controls.has_signal("dash_pressed") and player.has_method("try_dash"):
		if not mobile_controls.dash_pressed.is_connected(player.try_dash):
			mobile_controls.dash_pressed.connect(player.try_dash)


func _on_player_level_up_available(_level: int) -> void:
	if _is_player_dead() or _is_game_over_visible():
		return

	if upgrade_manager == null or level_up_screen == null:
		push_warning("Level-up flow is missing UpgradeManager or LevelUpScreen.")
		return

	if not upgrade_manager.has_method("get_upgrade_options") or not level_up_screen.has_method("show_options"):
		push_warning("Level-up flow nodes are missing required methods.")
		return

	get_tree().paused = true
	_reset_mobile_controls()
	if audio_manager != null and audio_manager.has_method("play_level_up"):
		audio_manager.play_level_up()
	level_up_screen.show_options(upgrade_manager.get_upgrade_options(3))


func _on_upgrade_selected(upgrade_id: String) -> void:
	if _is_player_dead() or _is_game_over_visible():
		return

	if upgrade_manager != null and upgrade_manager.has_method("apply_upgrade"):
		upgrade_manager.apply_upgrade(upgrade_id)
	else:
		push_warning("UpgradeManager cannot apply selected upgrade.")

	get_tree().paused = false


func _setup_run_lifecycle() -> void:
	if player.has_signal("died") and not player.died.is_connected(_on_player_died):
		player.died.connect(_on_player_died)

	if run_manager == null:
		push_warning("Arena could not find RunManager node.")

	if game_over_screen == null:
		push_warning("Arena could not find GameOverScreen node.")
	elif game_over_screen.has_signal("restart_requested") and not game_over_screen.restart_requested.is_connected(_on_restart_requested):
		game_over_screen.restart_requested.connect(_on_restart_requested)


func _setup_pause_menu() -> void:
	if pause_menu == null:
		push_warning("Arena could not find PauseMenu node.")
		return

	if pause_menu.has_signal("resume_requested") and not pause_menu.resume_requested.is_connected(_on_pause_resume_requested):
		pause_menu.resume_requested.connect(_on_pause_resume_requested)
	if pause_menu.has_signal("restart_requested") and not pause_menu.restart_requested.is_connected(_on_pause_restart_requested):
		pause_menu.restart_requested.connect(_on_pause_restart_requested)
	if pause_menu.has_signal("quit_to_menu_requested") and not pause_menu.quit_to_menu_requested.is_connected(_on_pause_quit_to_menu_requested):
		pause_menu.quit_to_menu_requested.connect(_on_pause_quit_to_menu_requested)
	if pause_menu.has_signal("settings_requested") and not pause_menu.settings_requested.is_connected(_on_pause_settings_requested):
		pause_menu.settings_requested.connect(_on_pause_settings_requested)
	if pause_menu.has_method("setup_audio_manager"):
		pause_menu.setup_audio_manager(audio_manager)


func _setup_settings_menu() -> void:
	if settings_menu == null:
		push_warning("Arena could not find SettingsMenu node.")
		return

	if settings_menu.has_method("setup"):
		settings_menu.setup(settings_manager, audio_manager)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_request_pause_menu()
		get_viewport().set_input_as_handled()


func _on_player_died() -> void:
	var stats := {}
	if run_manager != null and run_manager.has_method("end_run"):
		run_manager.end_run()
	if run_manager != null and run_manager.has_method("get_stats"):
		stats = run_manager.get_stats()

	stats["level"] = int(player.get("level")) if player.get("level") != null else 1

	if level_up_screen != null:
		level_up_screen.hide()

	get_tree().paused = true
	_reset_mobile_controls()
	if audio_manager != null and audio_manager.has_method("play_game_over"):
		audio_manager.play_game_over()
	if game_over_screen != null and game_over_screen.has_method("setup_audio_manager"):
		game_over_screen.setup_audio_manager(audio_manager)
	if game_over_screen != null and game_over_screen.has_method("show_stats"):
		game_over_screen.show_stats(stats)
	else:
		push_warning("GameOverScreen does not implement show_stats(stats).")


func _on_restart_requested() -> void:
	get_tree().paused = false
	restart_run_requested.emit()


func _request_pause_menu() -> void:
	if get_tree().paused or _is_player_dead() or _is_level_up_visible() or _is_game_over_visible():
		return

	get_tree().paused = true
	_reset_mobile_controls()
	if pause_menu != null and pause_menu.has_method("open"):
		pause_menu.open()


func _on_pause_resume_requested() -> void:
	if pause_menu != null and pause_menu.has_method("close"):
		pause_menu.close()
	get_tree().paused = false


func _on_pause_restart_requested() -> void:
	if pause_menu != null and pause_menu.has_method("close"):
		pause_menu.close()
	get_tree().paused = false
	restart_run_requested.emit()


func _on_pause_quit_to_menu_requested() -> void:
	if pause_menu != null and pause_menu.has_method("close"):
		pause_menu.close()
	get_tree().paused = false
	quit_to_menu_requested.emit()


func _on_pause_settings_requested() -> void:
	if settings_menu != null and settings_menu.has_method("open"):
		settings_menu.open()


func _is_player_dead() -> bool:
	return player != null and player.has_method("is_dead") and player.is_dead()


func _is_game_over_visible() -> bool:
	return game_over_screen != null and game_over_screen.visible


func _is_level_up_visible() -> bool:
	return level_up_screen != null and level_up_screen.visible


func _reset_mobile_controls() -> void:
	if mobile_controls != null and mobile_controls.has_method("reset_controls"):
		mobile_controls.reset_controls()


func _apply_settings() -> void:
	if player != null and player.has_method("set_screen_shake_enabled") and settings_manager != null:
		player.set_screen_shake_enabled(bool(settings_manager.get_setting("screen_shake_enabled", true)))
	if mobile_controls != null and mobile_controls.has_method("apply_settings"):
		mobile_controls.apply_settings(settings_manager)
