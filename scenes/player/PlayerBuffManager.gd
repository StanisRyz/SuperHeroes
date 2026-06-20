extends Node

signal buff_started(buff_id: String, duration: float)
signal buff_updated(buff_id: String, time_left: float, duration: float)
signal buff_finished(buff_id: String)
signal shield_changed(shield_charges: int)

var player: Node
var auto_attack: Node
var _shield_charges: int = 0
var _active_timed_buffs: Dictionary = {}


func setup(new_player: Node, new_auto_attack: Node) -> void:
	player = new_player
	auto_attack = new_auto_attack


func _process(delta: float) -> void:
	var finished: Array[String] = []
	for buff_id in _active_timed_buffs:
		var buff: Dictionary = _active_timed_buffs[buff_id]
		buff.time_left = maxf(buff.time_left - delta, 0.0)
		buff_updated.emit(buff_id, buff.time_left, buff.duration)
		if buff.time_left <= 0.0:
			finished.append(buff_id)

	for buff_id in finished:
		_restore_buff(buff_id)
		_active_timed_buffs.erase(buff_id)
		buff_finished.emit(buff_id)


func apply_move_speed_boost(multiplier: float, duration: float) -> void:
	if player == null or not "speed" in player:
		return

	var base_speed: float
	if _active_timed_buffs.has("move_speed_boost"):
		base_speed = float(_active_timed_buffs["move_speed_boost"].original_value)
		player.speed = base_speed
	else:
		base_speed = float(player.speed)

	_active_timed_buffs["move_speed_boost"] = {
		"time_left": duration,
		"duration": duration,
		"original_value": base_speed
	}
	player.speed = base_speed * multiplier
	buff_started.emit("move_speed_boost", duration)


func apply_attack_speed_boost(multiplier: float, duration: float) -> void:
	_apply_attack_speed_boost_with_id("attack_speed_boost", multiplier, duration)


func apply_named_attack_speed_boost(buff_id: String, multiplier: float, duration: float) -> void:
	if buff_id.is_empty():
		buff_id = "attack_speed_boost"
	_apply_attack_speed_boost_with_id(buff_id, multiplier, duration)


func clear_timed_buff(buff_id: String) -> void:
	if not _active_timed_buffs.has(buff_id):
		return
	_restore_buff(buff_id)
	_active_timed_buffs.erase(buff_id)
	buff_finished.emit(buff_id)


func _apply_attack_speed_boost_with_id(buff_id: String, multiplier: float, duration: float) -> void:
	if auto_attack == null or not "attack_interval" in auto_attack:
		return

	var base_interval: float
	if _active_timed_buffs.has(buff_id):
		base_interval = float(_active_timed_buffs[buff_id].original_value)
		auto_attack.attack_interval = base_interval
	else:
		base_interval = float(auto_attack.attack_interval)

	_active_timed_buffs[buff_id] = {
		"time_left": duration,
		"duration": duration,
		"original_value": base_interval
	}
	auto_attack.attack_interval = base_interval / multiplier
	buff_started.emit(buff_id, duration)


func add_shield_charges(amount: int) -> void:
	_shield_charges += amount
	shield_changed.emit(_shield_charges)


func consume_shield_charge() -> bool:
	if _shield_charges <= 0:
		return false
	_shield_charges -= 1
	shield_changed.emit(_shield_charges)
	return true


func get_active_buffs() -> Dictionary:
	return _active_timed_buffs.duplicate()


func get_shield_charges() -> int:
	return _shield_charges


func _restore_buff(buff_id: String) -> void:
	if not _active_timed_buffs.has(buff_id):
		return

	var buff: Dictionary = _active_timed_buffs[buff_id]
	match buff_id:
		"move_speed_boost":
			if player != null and "speed" in player:
				player.speed = buff.original_value
		"attack_speed_boost":
			if auto_attack != null and "attack_interval" in auto_attack:
				auto_attack.attack_interval = buff.original_value
		"battle_focus":
			if auto_attack != null and "attack_interval" in auto_attack:
				auto_attack.attack_interval = buff.original_value
