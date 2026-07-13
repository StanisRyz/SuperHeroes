extends Node3D

## Presentation-only charge markers. Player3D remains the shield-state owner.
const ORBIT_RADIUS := 1.05
const ORBIT_SPEED := 1.8

var _player: Node3D
var _orbit_angle := 0.0
@onready var _markers: Array[MeshInstance3D] = [get_node("MarkerOne") as MeshInstance3D, get_node("MarkerTwo") as MeshInstance3D]


func setup(player: Node3D) -> void:
	_disconnect_player()
	_player = player
	if _player != null and _player.has_signal("shield_changed") and not _player.is_connected("shield_changed", _on_shield_changed):
		_player.connect("shield_changed", _on_shield_changed)
	_update_markers()
	_update_orbit()


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player) or _player.is_queued_for_deletion():
		queue_free()
		return
	_orbit_angle += ORBIT_SPEED * delta
	_update_orbit()


func _on_shield_changed(_current: int, _maximum: int) -> void:
	_update_markers()


func _update_markers() -> void:
	var charges := int(_player.get_shield_charges()) if _player != null and is_instance_valid(_player) and _player.has_method("get_shield_charges") else 0
	for index in _markers.size():
		_markers[index].visible = index < charges


func _update_orbit() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	global_position = _player.global_position + Vector3(0.0, 0.78, 0.0)
	for index in _markers.size():
		var angle := _orbit_angle + TAU * float(index) / float(_markers.size())
		_markers[index].position = Vector3(cos(angle) * ORBIT_RADIUS, 0.0, sin(angle) * ORBIT_RADIUS)


func _exit_tree() -> void:
	_disconnect_player()


func _disconnect_player() -> void:
	if _player != null and is_instance_valid(_player) and _player.has_signal("shield_changed") and _player.is_connected("shield_changed", _on_shield_changed):
		_player.disconnect("shield_changed", _on_shield_changed)
