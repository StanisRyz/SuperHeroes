extends Node2D

signal restart_run_requested
signal quit_to_menu_requested

@export var arena_size: Vector2 = Vector2(4000.0, 4000.0)
@export var debug_input_logging: bool = false

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
@onready var debug_manager: Node = get_node_or_null("DebugManager")
@onready var debug_overlay: Node = get_node_or_null("DebugOverlay")
@onready var powerup_manager: Node = get_node_or_null("PowerupManager")
@onready var event_director: Node = get_node_or_null("EventDirector")
@onready var event_announcement: Node = get_node_or_null("EventAnnouncement")
@onready var miniboss_health_bar: Node = get_node_or_null("MinibossHealthBar")

var _debug_stats_overlay: Node = null
var _debug_powerup_cycle_index: int = 0
const DEBUG_POWERUP_CYCLE: Array = ["heal", "shield", "bomb", "magnet_burst", "move_speed_boost", "attack_speed_boost"]
const DEBUG_KILL_RADIUS: float = 500.0
const DEBUG_XP_AMOUNT: int = 50


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

	var auto_attack := player.get_node_or_null("AutoAttack")
	var player_buff_manager := player.get_node_or_null("PlayerBuffManager")
	if player_buff_manager == null:
		push_warning("Arena could not find Player/PlayerBuffManager node.")
	elif player_buff_manager.has_method("setup"):
		player_buff_manager.setup(player, auto_attack)
	else:
		push_warning("PlayerBuffManager does not implement setup(player, auto_attack).")

	_setup_mobile_controls(ability_manager)

	if hud == null:
		push_warning("Arena could not find GameHUD node.")
	elif hud.has_method("setup"):
		hud.setup(player, run_manager, ability_manager, player_buff_manager)
	else:
		push_warning("GameHUD does not implement setup(player, run_manager, ability_manager).")

	if powerup_manager == null:
		push_warning("Arena could not find PowerupManager node.")
	elif powerup_manager.has_method("setup"):
		powerup_manager.setup(player, auto_attack, enemy_container, pickup_container, floating_text_spawner, audio_manager)
	else:
		push_warning("PowerupManager does not implement setup(...).")

	_setup_spawn_director()
	_setup_level_up_flow(auto_attack, ability_manager)
	_setup_run_lifecycle()
	_setup_pause_menu()
	_setup_settings_menu()
	_setup_debug_flow()
	_setup_event_director()

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
		enemy_spawner.setup(player, playable_rect, enemy_container, pickup_container, run_manager, spawn_director, floating_text_spawner, audio_manager, powerup_manager, projectile_container)
	else:
		push_warning("EnemySpawner does not implement setup(player, playable_rect, enemy_container, pickup_container, run_manager, spawn_director, floating_text_spawner).")

	_setup_debug_stats_overlay()


func get_playable_rect() -> Rect2:
	return Rect2(-arena_size * 0.5, arena_size)


func _setup_level_up_flow(auto_attack: Node, ability_manager: Node) -> void:
	if upgrade_manager == null:
		push_warning("Arena could not find UpgradeManager node.")
	elif upgrade_manager.has_method("setup"):
		upgrade_manager.setup(player, auto_attack, ability_manager)
	else:
		push_warning("UpgradeManager does not implement setup(player, auto_attack, ability_manager).")

	if hud != null and hud.has_method("setup_upgrade_manager"):
		hud.setup_upgrade_manager(upgrade_manager)

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

	if mobile_controls.has_signal("ability_2_pressed"):
		if ability_manager != null and ability_manager.has_method("cast_ability_2"):
			if not mobile_controls.ability_2_pressed.is_connected(ability_manager.cast_ability_2):
				mobile_controls.ability_2_pressed.connect(ability_manager.cast_ability_2)
		else:
			push_warning("AbilityManager does not implement cast_ability_2().")

	if mobile_controls.has_signal("ability_3_pressed"):
		if ability_manager != null and ability_manager.has_method("cast_ability_3"):
			if not mobile_controls.ability_3_pressed.is_connected(ability_manager.cast_ability_3):
				mobile_controls.ability_3_pressed.connect(ability_manager.cast_ability_3)
		else:
			push_warning("AbilityManager does not implement cast_ability_3().")

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


func _setup_event_director() -> void:
	if event_director == null:
		push_warning("Arena could not find EventDirector node.")
		return
	if event_director.has_method("setup"):
		event_director.setup(run_manager)
	else:
		push_warning("EventDirector does not implement setup(run_manager).")
		return

	if event_director.has_signal("event_started") and not event_director.event_started.is_connected(_on_event_started):
		event_director.event_started.connect(_on_event_started)
	if event_director.has_signal("event_finished") and not event_director.event_finished.is_connected(_on_event_finished):
		event_director.event_finished.connect(_on_event_finished)
	if event_director.has_signal("elite_spawn_requested") and not event_director.elite_spawn_requested.is_connected(_on_elite_spawn_requested):
		event_director.elite_spawn_requested.connect(_on_elite_spawn_requested)
	if event_director.has_signal("miniboss_spawn_requested") and not event_director.miniboss_spawn_requested.is_connected(_on_miniboss_spawn_requested):
		event_director.miniboss_spawn_requested.connect(_on_miniboss_spawn_requested)

	if enemy_spawner != null and miniboss_health_bar != null:
		if enemy_spawner.has_signal("miniboss_spawned") and not enemy_spawner.miniboss_spawned.is_connected(miniboss_health_bar.track_enemy):
			enemy_spawner.miniboss_spawned.connect(miniboss_health_bar.track_enemy)

	if enemy_spawner != null:
		if enemy_spawner.has_signal("miniboss_phase_changed") and not enemy_spawner.miniboss_phase_changed.is_connected(_on_miniboss_phase_changed):
			enemy_spawner.miniboss_phase_changed.connect(_on_miniboss_phase_changed)
		if enemy_spawner.has_signal("miniboss_defeated") and not enemy_spawner.miniboss_defeated.is_connected(_on_miniboss_defeated):
			enemy_spawner.miniboss_defeated.connect(_on_miniboss_defeated)


func _on_event_started(event_data: Dictionary) -> void:
	var announcement: String = event_data.get("announcement", "")
	var duration: float = event_data.get("duration", 2.0)
	var display_duration := maxf(duration if duration > 0.0 else 2.0, 2.0)
	if announcement != "" and event_announcement != null and event_announcement.has_method("show_announcement"):
		event_announcement.show_announcement(announcement, display_duration)
	var event_type: String = event_data.get("type", "timed")
	if event_type == "timed" and spawn_director != null and spawn_director.has_method("apply_event_modifier"):
		spawn_director.apply_event_modifier(event_data)


func _on_event_finished(event_id: String) -> void:
	if spawn_director != null and spawn_director.has_method("clear_event_modifier"):
		spawn_director.clear_event_modifier(event_id)


func _on_elite_spawn_requested(event_data: Dictionary) -> void:
	if enemy_spawner != null and enemy_spawner.has_method("spawn_elite_enemy"):
		enemy_spawner.spawn_elite_enemy(event_data)


func _on_miniboss_spawn_requested(event_data: Dictionary) -> void:
	if enemy_spawner != null and enemy_spawner.has_method("spawn_miniboss_enemy"):
		enemy_spawner.spawn_miniboss_enemy(event_data)


func _on_miniboss_phase_changed(phase: int) -> void:
	if phase == 2 and event_announcement != null and event_announcement.has_method("show_announcement"):
		event_announcement.show_announcement("Miniboss Enraged!", 2.5)


func _on_miniboss_defeated() -> void:
	if event_announcement != null and event_announcement.has_method("show_announcement"):
		event_announcement.show_announcement("Miniboss Defeated!", 3.0)


func _setup_debug_flow() -> void:
	print("DEBUG_WIRING: DebugManager exists=%s" % (debug_manager != null))
	print("DEBUG_WIRING: DebugOverlay exists=%s" % (debug_overlay != null))
	if player != null:
		print("DEBUG_WIRING: Player.set_debug_invulnerable=%s" % player.has_method("set_debug_invulnerable"))
		print("DEBUG_WIRING: Player.debug_gain_one_level=%s" % player.has_method("debug_gain_one_level"))
		print("DEBUG_WIRING: Player.debug_add_experience=%s" % player.has_method("debug_add_experience"))
	else:
		print("DEBUG_WIRING: Player is null")

	if debug_manager == null:
		push_warning("Arena could not find DebugManager node.")
		return

	if debug_manager.has_method("setup"):
		debug_manager.setup(player)
	else:
		push_warning("DebugManager does not implement setup(player).")

	var signals_connected := true
	if debug_manager.has_signal("debug_mode_changed"):
		if not debug_manager.debug_mode_changed.is_connected(_on_debug_mode_changed):
			debug_manager.debug_mode_changed.connect(_on_debug_mode_changed)
	else:
		push_warning("DebugManager is missing debug_mode_changed signal.")
		signals_connected = false

	if debug_manager.has_signal("debug_level_requested"):
		if not debug_manager.debug_level_requested.is_connected(_on_debug_level_requested):
			debug_manager.debug_level_requested.connect(_on_debug_level_requested)
	else:
		push_warning("DebugManager is missing debug_level_requested signal.")
		signals_connected = false

	_connect_debug_signal("debug_spawn_powerup_requested", _on_debug_spawn_powerup_requested)
	_connect_debug_signal("debug_spawn_elite_requested", _on_debug_spawn_elite_requested)
	_connect_debug_signal("debug_spawn_miniboss_requested", _on_debug_spawn_miniboss_requested)
	_connect_debug_signal("debug_add_xp_requested", _on_debug_add_xp_requested)
	_connect_debug_signal("debug_print_stats_requested", _on_debug_print_stats_requested)
	_connect_debug_signal("debug_kill_nearby_enemies_requested", _on_debug_kill_nearby_enemies_requested)

	print("DEBUG_WIRING: signals connected=%s" % signals_connected)

	if debug_manager.has_method("is_debug_enabled"):
		_on_debug_mode_changed(debug_manager.is_debug_enabled())


func _connect_debug_signal(signal_name: String, callable: Callable) -> void:
	if debug_manager.has_signal(signal_name):
		if not debug_manager.get(signal_name).is_connected(callable):
			debug_manager.get(signal_name).connect(callable)
	else:
		push_warning("DebugManager is missing signal: %s" % signal_name)


func _setup_debug_stats_overlay() -> void:
	var overlay_scene: PackedScene = load("res://scenes/ui/DebugStatsOverlay.tscn")
	if overlay_scene == null:
		push_warning("Arena: DebugStatsOverlay.tscn not found — skipping debug stats overlay.")
		return

	_debug_stats_overlay = overlay_scene.instantiate()
	add_child(_debug_stats_overlay)

	var auto_attack := player.get_node_or_null("AutoAttack") if player != null else null
	var ability_manager := player.get_node_or_null("AbilityManager") if player != null else null

	if _debug_stats_overlay.has_method("setup"):
		_debug_stats_overlay.setup(player, auto_attack, ability_manager, upgrade_manager, powerup_manager, enemy_spawner)

	var is_debug: bool = debug_manager != null and debug_manager.has_method("is_debug_enabled") and debug_manager.is_debug_enabled()
	if _debug_stats_overlay.has_method("set_debug_enabled"):
		_debug_stats_overlay.set_debug_enabled(is_debug)

	print("DEBUG_WIRING: DebugStatsOverlay instantiated=%s" % (_debug_stats_overlay != null))


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if event.echo:
		return

	var kc: int = event.keycode if event.keycode != 0 else event.physical_keycode

	if kc == KEY_F12 or kc == KEY_F10 or kc == KEY_F1 or kc == KEY_F2:
		print("DEBUG_INPUT: key=%s physical=%d keycode=%d pressed=%s echo=%s" % [
			OS.get_keycode_string(kc), event.physical_keycode, event.keycode, event.pressed, event.echo
		])

	if not event.pressed:
		return

	var handled_debug_key := false

	if kc == KEY_F12 or kc == KEY_F10:
		_toggle_debug_mode_from_input()
		handled_debug_key = true
	elif event.is_action_pressed("debug_toggle"):
		_toggle_debug_mode_from_input()
		handled_debug_key = true
	elif kc == KEY_F1 or kc == KEY_F2:
		_request_debug_level_from_input()
		handled_debug_key = true
	elif event.is_action_pressed("debug_level_up"):
		_request_debug_level_from_input()
		handled_debug_key = true
	elif _is_debug_action_blocked():
		pass
	elif kc == KEY_F3 or event.is_action_pressed("debug_spawn_powerup"):
		print("DEBUG_INPUT: action=debug_spawn_powerup")
		if debug_manager != null and debug_manager.has_method("request_spawn_powerup"):
			debug_manager.request_spawn_powerup()
		handled_debug_key = true
	elif kc == KEY_F4 or event.is_action_pressed("debug_spawn_elite"):
		print("DEBUG_INPUT: action=debug_spawn_elite")
		if debug_manager != null and debug_manager.has_method("request_spawn_elite"):
			debug_manager.request_spawn_elite()
		handled_debug_key = true
	elif kc == KEY_F5 or event.is_action_pressed("debug_spawn_miniboss"):
		print("DEBUG_INPUT: action=debug_spawn_miniboss")
		if debug_manager != null and debug_manager.has_method("request_spawn_miniboss"):
			debug_manager.request_spawn_miniboss()
		handled_debug_key = true
	elif kc == KEY_F6 or event.is_action_pressed("debug_add_xp"):
		print("DEBUG_INPUT: action=debug_add_xp")
		if debug_manager != null and debug_manager.has_method("request_add_xp"):
			debug_manager.request_add_xp()
		handled_debug_key = true
	elif kc == KEY_F7 or event.is_action_pressed("debug_print_stats"):
		print("DEBUG_INPUT: action=debug_print_stats")
		if debug_manager != null and debug_manager.has_method("request_print_stats"):
			debug_manager.request_print_stats()
		handled_debug_key = true
	elif kc == KEY_F8 or event.is_action_pressed("debug_kill_nearby_enemies"):
		print("DEBUG_INPUT: action=debug_kill_nearby_enemies")
		if debug_manager != null and debug_manager.has_method("request_kill_nearby_enemies"):
			debug_manager.request_kill_nearby_enemies()
		handled_debug_key = true

	if handled_debug_key:
		get_viewport().set_input_as_handled()


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


func _on_debug_mode_changed(enabled: bool) -> void:
	if debug_overlay != null and debug_overlay.has_method("set_debug_enabled"):
		debug_overlay.set_debug_enabled(enabled)
	else:
		push_warning("DebugOverlay does not implement set_debug_enabled(enabled).")

	if player != null and player.has_method("set_debug_invulnerable"):
		player.set_debug_invulnerable(enabled)
	else:
		push_warning("Player does not implement set_debug_invulnerable(enabled).")

	if _debug_stats_overlay != null and _debug_stats_overlay.has_method("set_debug_enabled"):
		_debug_stats_overlay.set_debug_enabled(enabled)


func _on_debug_level_requested() -> void:
	if _is_debug_level_blocked():
		return

	if player != null and player.has_method("debug_gain_one_level"):
		player.debug_gain_one_level()
	else:
		push_warning("Player does not implement debug_gain_one_level().")


func _on_debug_spawn_powerup_requested() -> void:
	if enemy_spawner == null or not enemy_spawner.has_method("debug_spawn_powerup"):
		push_warning("Arena: EnemySpawner missing debug_spawn_powerup().")
		return
	var powerup_id: String = DEBUG_POWERUP_CYCLE[_debug_powerup_cycle_index % DEBUG_POWERUP_CYCLE.size()]
	_debug_powerup_cycle_index += 1
	enemy_spawner.debug_spawn_powerup(powerup_id)
	print("DEBUG_ACTION: spawned powerup %s" % powerup_id)


func _on_debug_spawn_elite_requested() -> void:
	if enemy_spawner == null or not enemy_spawner.has_method("spawn_elite_enemy"):
		push_warning("Arena: EnemySpawner missing spawn_elite_enemy().")
		return
	enemy_spawner.spawn_elite_enemy({})
	print("DEBUG_ACTION: spawned elite")


func _on_debug_spawn_miniboss_requested() -> void:
	if enemy_spawner == null or not enemy_spawner.has_method("spawn_miniboss_enemy"):
		push_warning("Arena: EnemySpawner missing spawn_miniboss_enemy().")
		return
	enemy_spawner.spawn_miniboss_enemy({})
	if enemy_spawner.has_signal("miniboss_spawned") and miniboss_health_bar != null:
		if not enemy_spawner.miniboss_spawned.is_connected(miniboss_health_bar.track_enemy):
			enemy_spawner.miniboss_spawned.connect(miniboss_health_bar.track_enemy)
	print("DEBUG_ACTION: spawned miniboss")


func _on_debug_add_xp_requested() -> void:
	if player == null:
		return
	if player.has_method("debug_add_experience"):
		player.debug_add_experience(DEBUG_XP_AMOUNT)
	elif player.has_method("add_experience"):
		player.add_experience(DEBUG_XP_AMOUNT)
	print("DEBUG_ACTION: added XP %d" % DEBUG_XP_AMOUNT)


func _on_debug_print_stats_requested() -> void:
	if _debug_stats_overlay != null and _debug_stats_overlay.has_method("refresh_now"):
		_debug_stats_overlay.refresh_now()
	_print_compact_stats()


func _on_debug_kill_nearby_enemies_requested() -> void:
	if player == null or enemy_container == null:
		return

	var player_node := player as Node2D
	if player_node == null:
		return

	var killed_count := 0
	for enemy in enemy_container.get_children():
		if not is_instance_valid(enemy):
			continue
		if not enemy is Node2D:
			continue
		if not enemy.has_method("take_damage"):
			continue
		var enemy_node := enemy as Node2D
		if enemy_node.global_position.distance_to(player_node.global_position) <= DEBUG_KILL_RADIUS:
			enemy.take_damage(99999)
			killed_count += 1

	print("DEBUG_ACTION: killed nearby enemies count=%d" % killed_count)


func _print_compact_stats() -> void:
	print("=== DEBUG STATS ===")
	if player != null and is_instance_valid(player):
		print("Player: lvl=%d HP=%d/%d" % [
			player.get("level") or 1,
			player.get("current_health") or 0,
			player.get("max_health") or 0
		])
	var auto_attack := player.get_node_or_null("AutoAttack") if player != null else null
	if auto_attack != null and is_instance_valid(auto_attack):
		print("Weapon: dmg=%d interval=%.2f count=%d pierce=%d explosion=%.0f" % [
			auto_attack.get("attack_damage") or 0,
			auto_attack.get("attack_interval") or 0.0,
			auto_attack.get("projectile_count") or 0,
			auto_attack.get("projectile_pierce") or 0,
			auto_attack.get("projectile_explosion_radius") or 0.0
		])
	var ability_manager := player.get_node_or_null("AbilityManager") if player != null else null
	if ability_manager != null and is_instance_valid(ability_manager):
		if ability_manager.has_method("get_all_ability_states"):
			var states: Dictionary = ability_manager.get_all_ability_states()
			for slot: int in states.keys():
				var s: Dictionary = states[slot]
				print("Ability %d [%s]: cd=%.1f/%.1f" % [slot, s.get("id", "?"), s.get("cooldown_remaining", 0.0), s.get("cooldown_total", 0.0)])
	if upgrade_manager != null and is_instance_valid(upgrade_manager):
		if upgrade_manager.has_method("debug_get_build_state"):
			var build: Dictionary = upgrade_manager.debug_get_build_state()
			print("Build: dominant=%s upgrades=%d synergies=%d" % [
				build.get("dominant_archetype", "none"),
				build.get("selected_upgrade_history_size", 0),
				build.get("unlocked_synergy_upgrade_ids", []).size()
			])
	if enemy_spawner != null and is_instance_valid(enemy_spawner) and enemy_spawner.has_method("debug_get_powerup_wiring_state"):
		var wiring: Dictionary = enemy_spawner.debug_get_powerup_wiring_state()
		print("Powerup wiring: pickup=%s pm=%s container=%s drop_chance=%.2f" % [
			wiring.get("pickup_scene_assigned", false),
			wiring.get("powerup_manager_assigned", false),
			wiring.get("pickup_container_valid", false),
			wiring.get("drop_chance", 0.0)
		])
	print("==================")


func _toggle_debug_mode_from_input() -> void:
	if _is_debug_toggle_blocked():
		return

	if debug_input_logging:
		print("Debug input: toggle pressed")
	if debug_manager != null and debug_manager.has_method("toggle_debug_mode"):
		debug_manager.toggle_debug_mode()
		if debug_input_logging and debug_manager.has_method("is_debug_enabled"):
			print("Debug input: debug_enabled=%s" % debug_manager.is_debug_enabled())
	else:
		push_warning("DebugManager does not implement toggle_debug_mode().")


func _request_debug_level_from_input() -> void:
	if _is_debug_level_blocked():
		return
	if debug_manager == null or not debug_manager.has_method("is_debug_enabled") or not debug_manager.is_debug_enabled():
		return

	if debug_input_logging:
		print("Debug input: level requested")
	if debug_manager.has_method("request_debug_level"):
		debug_manager.request_debug_level()
	else:
		_on_debug_level_requested()


func _is_debug_action_blocked() -> bool:
	if get_tree().paused:
		return true
	if _is_game_over_visible():
		return true
	if _is_player_dead():
		return true
	if debug_manager == null or not debug_manager.has_method("is_debug_enabled") or not debug_manager.is_debug_enabled():
		return true
	return false


func _is_debug_toggle_blocked() -> bool:
	return get_tree().paused or _is_level_up_visible() or _is_game_over_visible() or _is_player_dead()


func _is_debug_level_blocked() -> bool:
	return get_tree().paused or _is_level_up_visible() or _is_game_over_visible() or _is_player_dead()


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
