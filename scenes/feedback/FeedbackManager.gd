extends Node

# Central non-gameplay feedback router. Gameplay scripts call these methods to
# request visual/audio feedback. All gating (settings, throttle) lives here.

const MAX_FLOATING_TEXTS_PER_FRAME: int = 6
const THROTTLE_WINDOW: float = 0.08

var _settings_manager: Node = null
var _floating_text_spawner: Node = null
var _event_announcement: Node = null
var _camera_target: Node = null

var _spawns_this_frame: int = 0
var _throttle_timer: float = 0.0
var _last_announcement: String = ""
var _last_announcement_time: float = -999.0


func setup(
	settings_manager: Node = null,
	floating_text_spawner: Node = null,
	event_announcement: Node = null,
	camera_target: Node = null
) -> void:
	_settings_manager = settings_manager
	_floating_text_spawner = floating_text_spawner
	_event_announcement = event_announcement
	_camera_target = camera_target


func _process(delta: float) -> void:
	_throttle_timer += delta
	if _throttle_timer >= THROTTLE_WINDOW:
		_throttle_timer = 0.0
		_spawns_this_frame = 0


# --- Public API ---

func show_damage(amount: int, world_position: Vector2, is_critical: bool = false) -> void:
	if not _floating_text_enabled():
		return
	if not _can_spawn_text(true):
		return
	if _floating_text_spawner != null and _floating_text_spawner.has_method("spawn_damage_text"):
		_floating_text_spawner.spawn_damage_text(amount, world_position, is_critical)
		_spawns_this_frame += 1


func show_heal(amount: int, world_position: Vector2) -> void:
	if not _floating_text_enabled():
		return
	if not _can_spawn_text(true):
		return
	if _floating_text_spawner != null and _floating_text_spawner.has_method("spawn_heal_text"):
		_floating_text_spawner.spawn_heal_text(amount, world_position)
		_spawns_this_frame += 1


func show_powerup(powerup_id: String, world_position: Vector2) -> void:
	if not _floating_text_enabled():
		return
	if not _can_spawn_text(true):
		return
	if _floating_text_spawner != null and _floating_text_spawner.has_method("spawn_powerup_text"):
		_floating_text_spawner.spawn_powerup_text(powerup_id, world_position)
		_spawns_this_frame += 1


func show_status(text: String, world_position: Vector2) -> void:
	if not _floating_text_enabled():
		return
	if not _can_spawn_text(false):
		return
	if _floating_text_spawner != null and _floating_text_spawner.has_method("spawn_status_text"):
		_floating_text_spawner.spawn_status_text(text, world_position)
		_spawns_this_frame += 1


func show_announcement(text: String, duration: float = 2.0) -> void:
	if _event_announcement == null or not _event_announcement.has_method("show_announcement"):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if text == _last_announcement and now - _last_announcement_time < 0.5:
		return
	_last_announcement = text
	_last_announcement_time = now
	_event_announcement.show_announcement(text, duration)


func shake(intensity: float = 1.0, duration: float = 0.12) -> void:
	if not _shake_enabled():
		return
	var scaled := intensity * _shake_intensity()
	if _camera_target != null and _camera_target.has_method("shake_camera"):
		_camera_target.shake_camera(scaled, duration)


func flash_node(node: CanvasItem, color: Color, duration: float = 0.08) -> void:
	if not _impact_flash_enabled():
		return
	if node == null or not is_instance_valid(node):
		return
	var tween := node.create_tween()
	tween.tween_property(node, "modulate", color, 0.0)
	tween.tween_property(node, "modulate", Color.WHITE, duration)


# --- Settings helpers ---

func _shake_enabled() -> bool:
	if _settings_manager == null:
		return true
	return bool(_settings_manager.get_setting("screen_shake_enabled", true))


func _shake_intensity() -> float:
	if _settings_manager == null:
		return 1.0
	return float(_settings_manager.get_setting("screen_shake_intensity", 1.0))


func _floating_text_enabled() -> bool:
	if _settings_manager == null:
		return true
	return bool(_settings_manager.get_setting("floating_text_enabled", true))


func _impact_flash_enabled() -> bool:
	if _settings_manager == null:
		return true
	return bool(_settings_manager.get_setting("impact_flash_enabled", true))


func _can_spawn_text(is_critical: bool) -> bool:
	if is_critical:
		return true
	return _spawns_this_frame < MAX_FLOATING_TEXTS_PER_FRAME
