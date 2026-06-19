extends Node

signal debug_mode_changed(enabled: bool)
signal debug_level_requested
signal debug_spawn_powerup_requested
signal debug_spawn_elite_requested
signal debug_spawn_miniboss_requested
signal debug_add_xp_requested
signal debug_print_stats_requested
signal debug_kill_nearby_enemies_requested

@export var debug_input_logging: bool = false

var debug_enabled: bool = false
var player: Node

func setup(new_player: Node) -> void:
	player = new_player
	set_debug_enabled(false)


func is_debug_enabled() -> bool:
	return debug_enabled


func set_debug_enabled(enabled: bool) -> void:
	if debug_enabled == enabled:
		return

	debug_enabled = enabled
	if debug_input_logging:
		print("DEBUG_MODE: enabled=%s" % debug_enabled)
	debug_mode_changed.emit(debug_enabled)


func toggle_debug_mode() -> void:
	set_debug_enabled(not debug_enabled)


func can_request_debug_level() -> bool:
	if not debug_enabled:
		return false
	if get_tree().paused:
		return false
	if player == null:
		return false
	if player.has_method("is_dead") and player.is_dead():
		return false
	return true


func request_debug_level() -> void:
	if not can_request_debug_level():
		if debug_input_logging:
			if not debug_enabled:
				print("DEBUG_LEVEL: rejected - disabled")
			elif get_tree().paused:
				print("DEBUG_LEVEL: rejected - tree paused")
			elif player == null:
				print("DEBUG_LEVEL: rejected - missing player")
			elif player.has_method("is_dead") and player.is_dead():
				print("DEBUG_LEVEL: rejected - player dead")
		return

	if debug_input_logging:
		print("DEBUG_LEVEL: requested")
	debug_level_requested.emit()


func _can_request_action(action_name: String) -> bool:
	if not debug_enabled:
		if debug_input_logging:
			print("DEBUG_ACTION: %s rejected - debug disabled" % action_name)
		return false
	if get_tree().paused:
		if debug_input_logging:
			print("DEBUG_ACTION: %s rejected - tree paused" % action_name)
		return false
	if player != null and player.has_method("is_dead") and player.is_dead():
		if debug_input_logging:
			print("DEBUG_ACTION: %s rejected - player dead" % action_name)
		return false
	return true


func request_spawn_powerup() -> void:
	if not _can_request_action("spawn_powerup"):
		return
	if debug_input_logging:
		print("DEBUG_ACTION: spawn_powerup accepted")
	debug_spawn_powerup_requested.emit()


func request_spawn_elite() -> void:
	if not _can_request_action("spawn_elite"):
		return
	if debug_input_logging:
		print("DEBUG_ACTION: spawn_elite accepted")
	debug_spawn_elite_requested.emit()


func request_spawn_miniboss() -> void:
	if not _can_request_action("spawn_miniboss"):
		return
	if debug_input_logging:
		print("DEBUG_ACTION: spawn_miniboss accepted")
	debug_spawn_miniboss_requested.emit()


func request_add_xp() -> void:
	if not _can_request_action("add_xp"):
		return
	if debug_input_logging:
		print("DEBUG_ACTION: add_xp accepted")
	debug_add_xp_requested.emit()


func request_print_stats() -> void:
	if not _can_request_action("print_stats"):
		return
	if debug_input_logging:
		print("DEBUG_ACTION: print_stats accepted")
	debug_print_stats_requested.emit()


func request_kill_nearby_enemies() -> void:
	if not _can_request_action("kill_nearby_enemies"):
		return
	if debug_input_logging:
		print("DEBUG_ACTION: kill_nearby_enemies accepted")
	debug_kill_nearby_enemies_requested.emit()
