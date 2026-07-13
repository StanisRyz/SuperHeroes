extends Node3D

## First isolated 3D run. Main owns transitions and rewards; this scene owns the live run.

signal restart_run_requested
signal quit_to_menu_requested
signal run_result_ready(summary: Dictionary)

@export_range(8.0, 200.0, 1.0) var arena_width: float = 40.0
@export_range(8.0, 200.0, 1.0) var arena_depth: float = 40.0
@export_range(60.0, 90.0, 1.0) var prototype_run_seconds: float = 75.0

var _settings_manager: Node
var _audio_manager: Node
var _selected_hero: Dictionary = {}
var _selected_stage: Dictionary = {}
var _run_finished: bool = false
var _pending_level_ups: int = 0

@onready var player: Player3D = $PlayerContainer/Player3D
@onready var player_spawn: Marker3D = $PlayerSpawn
@onready var camera_rig: CameraRig3D = $CameraRig3D
@onready var spawn_director: Node = $Managers/SpawnDirector
@onready var enemy_spawner: EnemySpawner3D = $Managers/EnemySpawner3D
@onready var run_manager: Node = $Managers/RunManager
@onready var upgrade_manager: RunUpgradeManager3D = $Managers/RunUpgradeManager3D
@onready var auto_attack: KnightMeleeAutoAttack3D = player.get_node("AutoAttack") as KnightMeleeAutoAttack3D
@onready var game_hud: Node = $GameHUD
@onready var level_up_screen: Node = $LevelUpScreen
@onready var game_over_screen: Node = $GameOverScreen
@onready var victory_screen: Node = $VictoryScreen
@onready var pause_menu: Node = $PauseMenu
@onready var mobile_controls: Node = $MobileControls


func setup(settings_manager: Node = null, audio_manager: Node = null, selected_hero: Dictionary = {}, _meta_manager: Node = null, selected_stage: Dictionary = {}) -> void:
	_settings_manager = settings_manager
	_audio_manager = audio_manager
	_selected_hero = selected_hero.duplicate(true)
	_selected_stage = selected_stage.duplicate(true)


func _ready() -> void:
	_update_ground_size()
	player.global_position = player_spawn.global_position
	player.set_playable_bounds(arena_width, arena_depth)
	camera_rig.setup(player)
	run_manager.apply_run_tuning(prototype_run_seconds, prototype_run_seconds)
	run_manager.final_boss_required = false
	run_manager.final_boss_required_changed.emit(false)
	spawn_director.setup(run_manager)
	enemy_spawner.setup(player, self, $EnemyContainer, $PickupContainer, spawn_director, run_manager)
	auto_attack.setup(player, $EnemyContainer, player.knight_visual)
	upgrade_manager.setup(player, auto_attack)
	_configure_ui()
	_connect_runtime_signals()
	enemy_spawner.start_spawning()


func _unhandled_input(event: InputEvent) -> void:
	if player.prototype_debug_enabled and event.is_action_pressed("debug_kill_nearby_enemies"):
		enemy_spawner.debug_kill_nearest_enemy()
		get_viewport().set_input_as_handled()
		return
	if not _run_finished and event.is_action_pressed("pause"):
		_toggle_pause_menu()
		get_viewport().set_input_as_handled()


func is_xz_position_inside_playable_bounds(horizontal_position: Vector2) -> bool:
	return absf(horizontal_position.x) <= arena_width * 0.5 and absf(horizontal_position.y) <= arena_depth * 0.5


func is_world_position_inside_playable_bounds(world_position: Vector3) -> bool:
	return is_xz_position_inside_playable_bounds(WorldPlane.world_to_horizontal(world_position))


func clamp_world_position_to_playable_bounds(world_position: Vector3) -> Vector3:
	var horizontal_position: Vector2 = WorldPlane.world_to_horizontal(world_position)
	horizontal_position.x = clampf(horizontal_position.x, -arena_width * 0.5, arena_width * 0.5)
	horizontal_position.y = clampf(horizontal_position.y, -arena_depth * 0.5, arena_depth * 0.5)
	return WorldPlane.horizontal_to_world(horizontal_position, world_position.y)


func _configure_ui() -> void:
	game_hud.setup(player, run_manager)
	for path: String in ["Root/AbilityPanel", "Root/BuffPanel", "Root/BuildPanel/EvolutionLabel"]:
		var unsupported_node := game_hud.get_node_or_null(path)
		if unsupported_node is CanvasItem:
			(unsupported_node as CanvasItem).hide()
	var hero_label := game_hud.get_node_or_null("Root/BuildPanel/HeroLabel") as Label
	if hero_label != null:
		hero_label.text = "Hero: %s" % str(_selected_hero.get("display_name", "Vanguard"))
	level_up_screen.setup_audio_manager(_audio_manager)
	game_over_screen.setup_audio_manager(_audio_manager)
	pause_menu.setup_audio_manager(_audio_manager)
	mobile_controls.setup_player(player)
	mobile_controls.apply_settings(_settings_manager)
	for path: String in ["Root/AbilityButton", "Root/BeamButton", "Root/SlamButton", "Root/BuildSlotsButton"]:
		var unsupported_mobile_node := mobile_controls.get_node_or_null(path)
		if unsupported_mobile_node is CanvasItem:
			(unsupported_mobile_node as CanvasItem).hide()


func _connect_runtime_signals() -> void:
	player.died.connect(_on_player_died)
	player.level_up_available.connect(_on_player_level_up_available)
	run_manager.victory_reached.connect(_on_victory_reached)
	run_manager.run_ended.connect(_on_run_ended)
	level_up_screen.upgrade_selected.connect(_on_upgrade_selected)
	game_over_screen.restart_requested.connect(restart_run_requested.emit)
	game_over_screen.quit_to_menu_requested.connect(quit_to_menu_requested.emit)
	victory_screen.restart_requested.connect(restart_run_requested.emit)
	victory_screen.quit_to_menu_requested.connect(quit_to_menu_requested.emit)
	pause_menu.resume_requested.connect(_resume_run)
	pause_menu.restart_requested.connect(restart_run_requested.emit)
	pause_menu.quit_to_menu_requested.connect(quit_to_menu_requested.emit)
	mobile_controls.movement_changed.connect(player.set_external_move_vector)
	mobile_controls.dash_pressed.connect(player.try_dash)
	mobile_controls.pause_pressed.connect(_toggle_pause_menu)


func _on_player_level_up_available(_level: int) -> void:
	if _run_finished:
		return
	_pending_level_ups += 1
	_open_next_level_up()


func _open_next_level_up() -> void:
	if _run_finished or _pending_level_ups <= 0 or level_up_screen.visible:
		return
	var options := upgrade_manager.get_upgrade_options(3)
	if options.is_empty():
		_pending_level_ups = 0
		return
	get_tree().paused = true
	level_up_screen.show_options(options)


func _on_upgrade_selected(upgrade_id: String) -> void:
	if _run_finished:
		return
	upgrade_manager.apply_upgrade(upgrade_id)
	_pending_level_ups = maxi(_pending_level_ups - 1, 0)
	get_tree().paused = false
	_open_next_level_up()


func _on_player_died() -> void:
	_finish_run("defeat")


func _on_victory_reached(_stats: Dictionary) -> void:
	_finish_run("victory")


func _on_run_ended(_stats: Dictionary) -> void:
	enemy_spawner.stop_spawning()


func _finish_run(result: String) -> void:
	if _run_finished:
		return
	_run_finished = true
	enemy_spawner.stop_spawning()
	auto_attack.stop_attacking()
	player.set_external_move_vector(Vector2.ZERO)
	if run_manager.is_run_active:
		run_manager.end_run()
	var summary := _build_run_summary(result)
	run_result_ready.emit(summary)
	get_tree().paused = true
	if result == "victory":
		victory_screen.show_stats(summary)
	else:
		game_over_screen.show_stats(summary)


func _build_run_summary(result: String) -> Dictionary:
	var summary: Dictionary = run_manager.get_stats()
	summary.merge(upgrade_manager.get_run_summary(), true)
	summary["result"] = result
	summary["player_level"] = player.level
	summary["hero_id"] = str(_selected_hero.get("id", "vanguard"))
	summary["hero_display_name"] = str(_selected_hero.get("display_name", "Vanguard"))
	summary["stage_id"] = str(_selected_stage.get("id", ""))
	summary["stage_display_name"] = str(_selected_stage.get("display_name", ""))
	summary["objective_type"] = "survival"
	summary["objective_completed"] = result == "victory"
	summary["run_grade"] = "A" if result == "victory" else "C"
	return summary


func _toggle_pause_menu() -> void:
	if _run_finished:
		return
	if pause_menu.visible:
		_resume_run()
	else:
		get_tree().paused = true
		pause_menu.open()


func _resume_run() -> void:
	pause_menu.close()
	if not _run_finished:
		get_tree().paused = false


func _update_ground_size() -> void:
	var ground_mesh := $Ground/MeshInstance3D.mesh as PlaneMesh
	if ground_mesh != null:
		ground_mesh.size = Vector2(arena_width, arena_depth)
	var ground_collision := $Ground/CollisionShape3D.shape as BoxShape3D
	if ground_collision != null:
		ground_collision.size = Vector3(arena_width, 0.5, arena_depth)
