extends Node3D

## First isolated 3D run. Main owns transitions and rewards; this scene owns the live run.

signal restart_run_requested
signal quit_to_menu_requested
signal run_result_ready(summary: Dictionary)

@export_range(8.0, 200.0, 1.0) var arena_width: float = 40.0
@export_range(8.0, 200.0, 1.0) var arena_depth: float = 40.0
@export_range(60.0, 600.0, 1.0) var prototype_run_seconds: float = 300.0

var _settings_manager: Node
var _audio_manager: Node
var _selected_hero: Dictionary = {}
var _selected_stage: Dictionary = {}
var _run_finished: bool = false
var _pending_level_ups: int = 0

var player: Player3D
@onready var player_spawn: Marker3D = $PlayerSpawn
@onready var camera_rig: CameraRig3D = $CameraRig3D
@onready var spawn_director: Node = $Managers/SpawnDirector
@onready var enemy_spawner: EnemySpawner3D = $Managers/EnemySpawner3D
@onready var run_manager: Node = $Managers/RunManager
@onready var passive_manager: PassiveAbilityManager3D = $Managers/PassiveAbilityManager3D
@onready var upgrade_manager: RunUpgradeManager3D = $Managers/RunUpgradeManager3D
@onready var evolution_manager: Node = $Managers/EvolutionManager3D
var auto_attack: Node
var ability_manager: Node
var hero_visual: Node
var action_controller: Node
var kit_controller: Node
@onready var game_hud: Node = $GameHUD
@onready var level_up_screen: Node = $LevelUpScreen
@onready var evolution_reward_screen: Node = $EvolutionRewardScreen
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
	process_mode = Node.PROCESS_MODE_ALWAYS
	_configure_gameplay_pause_modes()
	_initialize_world()
	_initialize_gameplay()
	_connect_runtime_signals()
	_initialize_input()
	_configure_optional_ui()
	_start_run()


func _configure_gameplay_pause_modes() -> void:
	for gameplay_node: Node in [$PlayerContainer, $CameraRig3D, $Managers, $EnemyContainer, $PickupContainer, $EffectContainer]:
		gameplay_node.process_mode = Node.PROCESS_MODE_PAUSABLE


func _initialize_world() -> void:
	_update_ground_size()
	_instantiate_selected_player()
	player.global_position = player_spawn.global_position
	player.set_playable_bounds(arena_width, arena_depth)
	camera_rig.setup(player)


func _initialize_gameplay() -> void:
	run_manager.apply_run_tuning(prototype_run_seconds, prototype_run_seconds)
	run_manager.final_boss_required = false
	run_manager.final_boss_required_changed.emit(false)
	spawn_director.setup(run_manager)
	enemy_spawner.setup(player, self, $EnemyContainer, $PickupContainer, spawn_director, run_manager)
	if auto_attack != null and auto_attack.has_method("setup"):
		if str(_selected_hero.get("kit_id", "")) == "solar_guardian":
			auto_attack.setup(player, $EnemyContainer, hero_visual, $EffectContainer, kit_controller)
		else:
			auto_attack.setup(player, $EnemyContainer, hero_visual, $EffectContainer)
	if ability_manager != null and ability_manager.has_method("setup"):
		ability_manager.setup(player, auto_attack, $EnemyContainer, $EffectContainer, hero_visual)
	passive_manager.setup(player, auto_attack, ability_manager, $EnemyContainer, $PickupContainer, $EffectContainer)
	var allowed_upgrades: Array[String] = []
	if str(_selected_hero.get("kit_id", "")) == "solar_guardian":
		for upgrade_id: String in RunUpgradeManager3D.UPGRADES:
			if str(RunUpgradeManager3D.UPGRADES[upgrade_id].get("category", "")) == "passive": allowed_upgrades.append(upgrade_id)
	upgrade_manager.setup(player, auto_attack, ability_manager, passive_manager, allowed_upgrades)
	evolution_manager.setup(upgrade_manager, ability_manager, passive_manager, auto_attack, [] if str(_selected_hero.get("kit_id", "")) == "solar_guardian" else EvolutionManager3D.EVOLUTIONS)
	if str(_selected_hero.get("kit_id", "")) != "solar_guardian": _validate_progression()

func _instantiate_selected_player() -> void:
	var player_scene_path := str(_selected_hero.get("runtime", {}).get("player_scene", "res://scenes3d/player/Player3D.tscn"))
	var player_scene := load(player_scene_path) as PackedScene
	if player_scene == null:
		push_error("Arena3D: missing 3D player scene %s." % player_scene_path)
		return
	player = player_scene.instantiate() as Player3D
	$PlayerContainer.add_child(player)
	auto_attack = player.get_node_or_null("AutoAttack")
	ability_manager = player.get_node_or_null("AbilityManager")
	kit_controller = player.get_node_or_null("SolarEnergy")
	hero_visual = player.hero_visual
	action_controller = player.get_node_or_null("ActionController")


func _initialize_input() -> void:
	player.set_external_move_vector(Vector2.ZERO)
	if mobile_controls != null and mobile_controls.has_method("reset_controls"):
		mobile_controls.reset_controls()


func _start_run() -> void:
	enemy_spawner.start_spawning()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if not _run_finished and event.is_action_pressed("pause"):
		_toggle_pause_menu()
		get_viewport().set_input_as_handled()
		return
	if player.prototype_debug_enabled and event.is_action_pressed("debug_kill_nearby_enemies"):
		enemy_spawner.debug_kill_nearest_enemy()
		get_viewport().set_input_as_handled()
		return
	if ability_manager != null and not _run_finished and event.is_action_pressed("ability_1"):
		ability_manager.cast_ability_1()
	if ability_manager != null and not _run_finished and event.is_action_pressed("ability_2"):
		ability_manager.cast_ability_2()
	if ability_manager != null and not _run_finished and event.is_action_pressed("ability_3"):
		ability_manager.cast_ability_3()


func is_xz_position_inside_playable_bounds(horizontal_position: Vector2) -> bool:
	return absf(horizontal_position.x) <= arena_width * 0.5 and absf(horizontal_position.y) <= arena_depth * 0.5


func is_world_position_inside_playable_bounds(world_position: Vector3) -> bool:
	return is_xz_position_inside_playable_bounds(WorldPlane.world_to_horizontal(world_position))


func clamp_world_position_to_playable_bounds(world_position: Vector3) -> Vector3:
	var horizontal_position: Vector2 = WorldPlane.world_to_horizontal(world_position)
	horizontal_position.x = clampf(horizontal_position.x, -arena_width * 0.5, arena_width * 0.5)
	horizontal_position.y = clampf(horizontal_position.y, -arena_depth * 0.5, arena_depth * 0.5)
	return WorldPlane.horizontal_to_world(horizontal_position, world_position.y)


func _configure_optional_ui() -> void:
	_configure_canvas_layers()
	if game_hud == null or not game_hud.has_method("setup"):
		push_warning("Arena3D: GameHUD is unavailable; continuing without optional HUD setup.")
	else:
		game_hud.setup(player, run_manager, ability_manager if ability_manager != null else kit_controller)
	for path: String in ["Root/BuffPanel/MoveSpeedLabel", "Root/BuffPanel/AttackSpeedLabel"]:
		var unsupported_node := game_hud.get_node_or_null(path) if game_hud != null else null
		if unsupported_node is CanvasItem:
			(unsupported_node as CanvasItem).hide()
	var hero_label := game_hud.get_node_or_null("Root/BuildPanel/HeroLabel") as Label
	if hero_label != null:
		hero_label.text = "Hero: %s" % str(_selected_hero.get("display_name", "Vanguard"))
	if game_hud != null and game_hud.has_method("setup_evolution_manager"):
		game_hud.setup_evolution_manager(evolution_manager if str(_selected_hero.get("kit_id", "")) != "solar_guardian" else null)
	if game_hud != null and game_hud.has_method("setup_passive_manager"):
		game_hud.setup_passive_manager(passive_manager)
	if level_up_screen != null and level_up_screen.has_method("setup_audio_manager"):
		level_up_screen.setup_audio_manager(_audio_manager)
	if game_over_screen != null and game_over_screen.has_method("setup_audio_manager"):
		game_over_screen.setup_audio_manager(_audio_manager)
	if pause_menu != null and pause_menu.has_method("setup_audio_manager"):
		pause_menu.setup_audio_manager(_audio_manager)
	if mobile_controls != null and mobile_controls.has_method("setup_player"):
		mobile_controls.setup_player(player)
	if mobile_controls != null and mobile_controls.has_method("setup_ability_manager"):
		mobile_controls.setup_ability_manager(ability_manager)
	if mobile_controls != null and str(_selected_hero.get("kit_id", "")) == "solar_guardian" and mobile_controls.has_method("set_abilities_visible"):
		mobile_controls.set_abilities_visible(false)
	if mobile_controls != null and mobile_controls.has_method("apply_settings"):
		mobile_controls.apply_settings(_settings_manager)
	for path: String in ["Root/BuildSlotsButton"]:
		var unsupported_mobile_node := mobile_controls.get_node_or_null(path) if mobile_controls != null else null
		if unsupported_mobile_node is CanvasItem:
			(unsupported_mobile_node as CanvasItem).hide()


func _configure_canvas_layers() -> void:
	_set_canvas_layer(game_hud, 1)
	_set_canvas_layer(mobile_controls, 2)
	_set_canvas_layer(pause_menu, 10)
	_set_canvas_layer(level_up_screen, 11)
	_set_canvas_layer(evolution_reward_screen, 12)
	_set_canvas_layer(game_over_screen, 20)
	_set_canvas_layer(victory_screen, 20)


func _set_canvas_layer(node: Node, layer: int) -> void:
	if node is CanvasLayer:
		(node as CanvasLayer).layer = layer


func _connect_runtime_signals() -> void:
	player.died.connect(_on_player_died)
	player.level_up_available.connect(_on_player_level_up_available)
	run_manager.victory_reached.connect(_on_victory_reached)
	run_manager.run_ended.connect(_on_run_ended)
	_connect_signal_if_available(level_up_screen, "upgrade_selected", _on_upgrade_selected)
	_connect_signal_if_available(evolution_reward_screen, "evolution_selected", _on_evolution_selected)
	_connect_signal_if_available(evolution_reward_screen, "closed_without_selection", _on_evolution_reward_closed_without_selection)
	_connect_signal_if_available(game_over_screen, "restart_requested", _request_restart)
	_connect_signal_if_available(game_over_screen, "quit_to_menu_requested", _request_quit_to_menu)
	_connect_signal_if_available(victory_screen, "restart_requested", _request_restart)
	_connect_signal_if_available(victory_screen, "quit_to_menu_requested", _request_quit_to_menu)
	_connect_signal_if_available(pause_menu, "resume_requested", _resume_run)
	_connect_signal_if_available(pause_menu, "restart_requested", _request_restart)
	_connect_signal_if_available(pause_menu, "quit_to_menu_requested", _request_quit_to_menu)
	_connect_signal_if_available(mobile_controls, "movement_changed", player.set_external_move_vector)
	_connect_signal_if_available(mobile_controls, "dash_pressed", player.try_dash)
	if ability_manager != null:
		_connect_signal_if_available(mobile_controls, "ability_1_pressed", ability_manager.cast_ability_1)
		_connect_signal_if_available(mobile_controls, "ability_2_pressed", ability_manager.cast_ability_2)
		_connect_signal_if_available(mobile_controls, "ability_3_pressed", ability_manager.cast_ability_3)
	_connect_signal_if_available(mobile_controls, "pause_pressed", _toggle_pause_menu)


func _connect_signal_if_available(node: Node, signal_name: StringName, callback: Callable) -> void:
	if node != null and node.has_signal(signal_name) and not node.is_connected(signal_name, callback):
		node.connect(signal_name, callback)


func _on_player_level_up_available(_level: int) -> void:
	if _run_finished:
		return
	_pending_level_ups += 1
	_open_next_level_up()


func _open_next_level_up() -> void:
	if _run_finished or _pending_level_ups <= 0 or level_up_screen == null or level_up_screen.visible:
		return
	var options := upgrade_manager.get_upgrade_options(3)
	if evolution_manager != null and evolution_manager.has_method("enrich_upgrade_options"):
		options = evolution_manager.enrich_upgrade_options(options)
	if options.is_empty():
		_pending_level_ups = 0
		return
	get_tree().paused = true
	level_up_screen.show_options(options)
	_refresh_optional_ability_state()


func _on_upgrade_selected(upgrade_id: String) -> void:
	if _run_finished:
		return
	if not upgrade_manager.apply_upgrade(upgrade_id):
		_open_next_level_up()
		return
	_pending_level_ups = maxi(_pending_level_ups - 1, 0)
	evolution_manager.refresh_evolution_states()
	_refresh_evolution_progress_ui()
	if _open_evolution_reward_if_ready():
		return
	_continue_after_evolution_reward()


func _open_evolution_reward_if_ready() -> bool:
	if _run_finished or evolution_reward_screen == null or evolution_reward_screen.visible:
		return false
	var options: Array = evolution_manager.get_available_evolutions()
	if options.is_empty():
		return false
	get_tree().paused = true
	player.set_external_move_vector(Vector2.ZERO)
	if mobile_controls != null and mobile_controls.has_method("reset_controls"):
		mobile_controls.reset_controls()
	evolution_reward_screen.show_options(options.slice(0, 3))
	_refresh_optional_ability_state()
	return true


func _validate_progression() -> void:
	if evolution_manager.has_method("get_progression_matrix_validation_errors"):
		for validation_error: String in evolution_manager.get_progression_matrix_validation_errors():
			push_error("Arena3D progression: %s" % validation_error)


func _refresh_evolution_progress_ui() -> void:
	if game_hud == null or not evolution_manager.has_method("get_closest_evolution_path_state"):
		return
	var path: Dictionary = evolution_manager.get_closest_evolution_path_state()
	if game_hud.has_method("update_evolution_path_state"):
		var ready_count := 0
		for state: Dictionary in evolution_manager.get_all_evolution_path_states().values():
			if bool(state.get("ready", false)):
				ready_count += 1
		game_hud.update_evolution_path_state(path, ready_count)


func _on_evolution_selected(evolution_id: String) -> void:
	if _run_finished or not evolution_manager.apply_evolution(evolution_id):
		return
	_hide_evolution_reward_screen()
	evolution_manager.refresh_evolution_states()
	_refresh_evolution_progress_ui()
	if _open_evolution_reward_if_ready():
		return
	_continue_after_evolution_reward()


func _on_evolution_reward_closed_without_selection() -> void:
	if _run_finished:
		return
	_hide_evolution_reward_screen()
	_continue_after_evolution_reward()


func _continue_after_evolution_reward() -> void:
	if _run_finished:
		return
	if _pending_level_ups > 0:
		_open_next_level_up()
	else:
		get_tree().paused = false
		_refresh_optional_ability_state()


func _hide_evolution_reward_screen() -> void:
	if evolution_reward_screen != null and evolution_reward_screen.has_method("hide_screen"):
		evolution_reward_screen.hide_screen()


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
	if auto_attack != null and auto_attack.has_method("stop_attacking"): auto_attack.stop_attacking()
	if ability_manager != null and ability_manager.has_method("stop"): ability_manager.stop()
	_hide_evolution_reward_screen()
	player.set_external_move_vector(Vector2.ZERO)
	if mobile_controls != null and mobile_controls.has_method("reset_controls"):
		mobile_controls.reset_controls()
	if run_manager.is_run_active:
		run_manager.end_run()
	var summary := _build_run_summary(result)
	passive_manager.stop()
	run_result_ready.emit(summary)
	get_tree().paused = true
	_refresh_optional_ability_state()
	if result == "victory":
		victory_screen.show_stats(summary)
	else:
		game_over_screen.show_stats(summary)


func _build_run_summary(result: String) -> Dictionary:
	var summary: Dictionary = run_manager.get_stats()
	summary.merge(upgrade_manager.get_run_summary(), true)
	var applied_evolutions: Array = evolution_manager.get_applied_evolutions()
	var applied_evolution_titles: Array = evolution_manager.get_applied_evolution_titles()
	var applied_evolution_count: int = applied_evolutions.size()
	summary["applied_evolutions"] = applied_evolutions
	summary["applied_evolution_titles"] = applied_evolution_titles
	summary["applied_evolution_count"] = applied_evolution_count
	var evolution_type_counts: Dictionary = evolution_manager.get_applied_evolution_type_counts()
	summary["active_evolution_count"] = int(evolution_type_counts.get("active", 0))
	summary["attack_evolution_count"] = int(evolution_type_counts.get("attack", 0))
	summary["passive_evolution_count"] = int(evolution_type_counts.get("passive", 0))
	var selected_passive_ids: Array[String] = passive_manager.get_selected_passive_ids()
	var selected_passive_titles: Array[String] = passive_manager.get_selected_passive_titles()
	summary["selected_passive_ids"] = selected_passive_ids
	summary["selected_passive_titles"] = selected_passive_titles
	summary["selected_passive_count"] = selected_passive_ids.size()
	var passive_levels: Dictionary = {}
	for passive_id: String in selected_passive_ids:
		passive_levels[passive_id] = passive_manager.get_passive_level(passive_id)
	summary["passive_levels"] = passive_levels
	summary["primary_attack_name"] = auto_attack.get_primary_attack_display_name() if auto_attack != null and auto_attack.has_method("get_primary_attack_display_name") else ""
	summary["selected_attack_evolution_ids"] = auto_attack.get_selected_attack_evolution_ids() if auto_attack != null and auto_attack.has_method("get_selected_attack_evolution_ids") else []
	var path_states: Dictionary = evolution_manager.get_all_evolution_path_states()
	var highest_progress := 0
	var partial_count := 0
	var ready_count := 0
	var path_levels := {}
	for evolution_id: String in path_states:
		var path: Dictionary = path_states[evolution_id]
		var progress := int(path.get("total_progress", 0))
		path_levels[evolution_id] = progress
		highest_progress = maxi(highest_progress, progress)
		if str(path.get("state", "")) == "partial": partial_count += 1
		if str(path.get("state", "")) == "ready": ready_count += 1
	var closest_path: Dictionary = evolution_manager.get_closest_evolution_path_state()
	summary["closest_evolution_id"] = evolution_manager.get_closest_evolution_id()
	summary["closest_evolution_title"] = str(closest_path.get("title", ""))
	summary["closest_evolution_progress"] = int(closest_path.get("total_progress", 0))
	summary["highest_evolution_progress"] = highest_progress
	summary["partial_evolution_count"] = partial_count
	summary["ready_evolution_count"] = ready_count
	summary["selected_evolution_count"] = applied_evolution_count
	summary["evolution_path_levels"] = path_levels
	summary["shield_charges"] = player.get_shield_charges()
	summary["shield_maximum_charges"] = player.get_maximum_shield_charges()
	summary["shield_blocks"] = player.get_shield_block_count()
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
	if _run_finished or (level_up_screen != null and level_up_screen.visible) or (evolution_reward_screen != null and evolution_reward_screen.visible):
		return
	if pause_menu != null and pause_menu.visible:
		_resume_run()
	else:
		player.set_external_move_vector(Vector2.ZERO)
		if mobile_controls != null and mobile_controls.has_method("reset_controls"):
			mobile_controls.reset_controls()
		get_tree().paused = true
		if pause_menu != null and pause_menu.has_method("open"):
			pause_menu.open()
	_refresh_optional_ability_state()


func _request_restart() -> void:
	_hide_evolution_reward_screen()
	restart_run_requested.emit()


func _request_quit_to_menu() -> void:
	_hide_evolution_reward_screen()
	quit_to_menu_requested.emit()


func _resume_run() -> void:
	player.set_external_move_vector(Vector2.ZERO)
	if mobile_controls != null and mobile_controls.has_method("reset_controls"):
		mobile_controls.reset_controls()
	if pause_menu != null and pause_menu.has_method("close"):
		pause_menu.close()
	if not _run_finished:
		get_tree().paused = false
		_refresh_optional_ability_state()

func _refresh_optional_ability_state() -> void:
	if ability_manager != null and ability_manager.has_method("refresh_ability_states"):
		ability_manager.refresh_ability_states()


func _update_ground_size() -> void:
	var ground_mesh := $Ground/MeshInstance3D.mesh as PlaneMesh
	if ground_mesh != null:
		ground_mesh.size = Vector2(arena_width, arena_depth)
	var ground_collision := $Ground/CollisionShape3D.shape as BoxShape3D
	if ground_collision != null:
		ground_collision.size = Vector3(arena_width, 0.5, arena_depth)
