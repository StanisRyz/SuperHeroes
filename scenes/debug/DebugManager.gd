extends Node

signal debug_mode_changed(enabled: bool)
signal debug_level_requested

@export var debug_input_logging: bool = true

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
