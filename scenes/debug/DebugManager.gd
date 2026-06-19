extends Node

signal debug_mode_changed(enabled: bool)
signal debug_level_requested

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
	debug_mode_changed.emit(debug_enabled)


func toggle_debug_mode() -> void:
	set_debug_enabled(not debug_enabled)
