extends CanvasLayer

signal movement_changed(direction: Vector2)
signal ability_1_pressed
signal pause_pressed
signal dash_pressed

@export var force_visible: bool = false
@export var joystick_radius: float = 80.0
@export var deadzone: float = 0.12

var _active_pointer_id := -999
var _movement_direction := Vector2.ZERO
var _settings_manager: Node

@onready var joystick_touch_area: Control = get_node_or_null("Root/JoystickArea")
@onready var joystick_base: Control = get_node_or_null("Root/JoystickArea/Base")
@onready var joystick_knob: Control = get_node_or_null("Root/JoystickArea/Base/Knob")
@onready var ability_button: Button = get_node_or_null("Root/AbilityButton")
@onready var dash_button: Button = get_node_or_null("Root/DashButton")
@onready var pause_button: Button = get_node_or_null("Root/PauseButton")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = force_visible or DisplayServer.is_touchscreen_available()

	if joystick_touch_area == null:
		push_warning("MobileControls could not find JoystickArea.")
	else:
		joystick_touch_area.gui_input.connect(_on_joystick_gui_input)

	if ability_button == null:
		push_warning("MobileControls could not find AbilityButton.")
	elif not ability_button.pressed.is_connected(_on_ability_button_pressed):
		ability_button.pressed.connect(_on_ability_button_pressed)

	if dash_button == null:
		push_warning("MobileControls could not find DashButton.")
	elif not dash_button.pressed.is_connected(_on_dash_button_pressed):
		dash_button.pressed.connect(_on_dash_button_pressed)

	if pause_button == null:
		push_warning("MobileControls could not find PauseButton.")
	elif not pause_button.pressed.is_connected(_on_pause_button_pressed):
		pause_button.pressed.connect(_on_pause_button_pressed)

	_update_joystick_visual(Vector2.ZERO)
	_update_ability_button(0.0)
	_update_dash_button(0.0)


func _process(_delta: float) -> void:
	if get_tree().paused and not _movement_direction.is_zero_approx():
		reset_controls()


func setup_ability_manager(ability_manager: Node) -> void:
	_update_ability_button(0.0)

	if ability_manager == null:
		return

	if ability_manager.has_signal("ability_cooldown_changed") and not ability_manager.ability_cooldown_changed.is_connected(_on_ability_cooldown_changed):
		ability_manager.ability_cooldown_changed.connect(_on_ability_cooldown_changed)


func setup_player(player: Node) -> void:
	_update_dash_button(0.0)
	if player != null and player.has_signal("dash_cooldown_changed") and not player.dash_cooldown_changed.is_connected(_on_dash_cooldown_changed):
		player.dash_cooldown_changed.connect(_on_dash_cooldown_changed)


func apply_settings(settings_manager: Node) -> void:
	_settings_manager = settings_manager
	if _settings_manager != null and _settings_manager.has_signal("settings_changed") and not _settings_manager.settings_changed.is_connected(_update_visibility_from_settings):
		_settings_manager.settings_changed.connect(_update_visibility_from_settings)

	_update_visibility_from_settings()


func reset_controls() -> void:
	_active_pointer_id = -999
	_set_movement_direction(Vector2.ZERO)


func _on_joystick_gui_input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventScreenTouch:
		_handle_touch_event(event)
	elif event is InputEventScreenDrag:
		_handle_drag_event(event)
	elif event is InputEventMouseButton:
		_handle_mouse_button_event(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion_event(event)


func _handle_touch_event(event: InputEventScreenTouch) -> void:
	if get_tree().paused:
		reset_controls()
		return

	if event.pressed and _active_pointer_id == -999:
		_active_pointer_id = event.index
		_update_direction_from_position(event.position)
	elif not event.pressed and _active_pointer_id == event.index:
		reset_controls()


func _handle_drag_event(event: InputEventScreenDrag) -> void:
	if get_tree().paused:
		reset_controls()
		return

	if _active_pointer_id == event.index:
		_update_direction_from_position(event.position)


func _handle_mouse_button_event(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if get_tree().paused:
		reset_controls()
		return

	if event.pressed and _active_pointer_id == -999:
		_active_pointer_id = -1
		_update_direction_from_position(event.position)
	elif not event.pressed and _active_pointer_id == -1:
		reset_controls()


func _handle_mouse_motion_event(event: InputEventMouseMotion) -> void:
	if get_tree().paused:
		reset_controls()
		return

	if _active_pointer_id == -1:
		_update_direction_from_position(event.position)


func _update_direction_from_position(local_position: Vector2) -> void:
	var center := _get_joystick_center()
	var pointer_offset := local_position - center
	var normalized_offset := pointer_offset / joystick_radius
	var direction := normalized_offset.limit_length(1.0)

	if direction.length() < deadzone:
		direction = Vector2.ZERO

	_set_movement_direction(direction)


func _set_movement_direction(direction: Vector2) -> void:
	var clamped_direction := direction.limit_length(1.0)
	if _movement_direction.is_equal_approx(clamped_direction):
		return

	_movement_direction = clamped_direction
	_update_joystick_visual(_movement_direction)
	movement_changed.emit(_movement_direction)


func _update_joystick_visual(direction: Vector2) -> void:
	if joystick_knob == null:
		return

	var knob_size := joystick_knob.size
	var center := _get_base_center()
	joystick_knob.position = center - knob_size * 0.5 + direction * joystick_radius


func _get_joystick_center() -> Vector2:
	if joystick_touch_area == null:
		return Vector2.ZERO

	return joystick_touch_area.size * 0.5


func _get_base_center() -> Vector2:
	if joystick_base == null:
		return _get_joystick_center()

	return joystick_base.size * 0.5


func _on_ability_button_pressed() -> void:
	if get_tree().paused:
		return

	ability_1_pressed.emit()


func _on_pause_button_pressed() -> void:
	if get_tree().paused:
		return

	pause_pressed.emit()


func _on_dash_button_pressed() -> void:
	if get_tree().paused:
		return

	dash_pressed.emit()


func _on_ability_cooldown_changed(slot: int, cooldown_remaining: float, _cooldown_total: float) -> void:
	if slot == 1:
		_update_ability_button(cooldown_remaining)


func _on_dash_cooldown_changed(cooldown_remaining: float, _cooldown_total: float) -> void:
	_update_dash_button(cooldown_remaining)


func _update_ability_button(cooldown_remaining: float) -> void:
	if ability_button == null:
		return

	if cooldown_remaining <= 0.0:
		ability_button.text = "Nova"
	else:
		ability_button.text = "%.1f" % cooldown_remaining


func _update_dash_button(cooldown_remaining: float) -> void:
	if dash_button == null:
		return

	if cooldown_remaining <= 0.0:
		dash_button.text = "Dash"
	else:
		dash_button.text = "%.1f" % cooldown_remaining


func _update_visibility_from_settings() -> void:
	var forced := force_visible
	if _settings_manager != null:
		forced = forced or bool(_settings_manager.get_setting("force_mobile_controls", false))

	visible = forced or DisplayServer.is_touchscreen_available()
