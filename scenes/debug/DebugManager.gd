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


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return

	if event.is_action_pressed("debug_toggle"):
		toggle_debug_mode()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("debug_level_up"):
		if _can_request_debug_level():
			debug_level_requested.emit()
			get_viewport().set_input_as_handled()


func _can_request_debug_level() -> bool:
	if not debug_enabled or get_tree().paused or player == null:
		return false
	if player.has_method("is_dead") and player.is_dead():
		return false

	return true
