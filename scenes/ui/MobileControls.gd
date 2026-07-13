extends CanvasLayer

signal movement_changed(direction: Vector2)
signal ability_1_pressed
signal ability_2_pressed
signal ability_3_pressed
signal pause_pressed
signal build_slots_pressed
signal dash_pressed

@export var force_visible: bool = false
@export var joystick_radius: float = 80.0
@export var deadzone: float = 0.12

var _active_pointer_id := -999
var _movement_direction := Vector2.ZERO
var _settings_manager: Node
var _input_blocker: Callable
var _ability_button_labels: Dictionary = {
	1: "A1",
	2: "A2",
	3: "A3",
}
var _ability_states: Dictionary = {}

@onready var joystick_touch_area: Control = get_node_or_null("Root/JoystickArea")
@onready var joystick_base: Control = get_node_or_null("Root/JoystickArea/Base")
@onready var joystick_knob: Control = get_node_or_null("Root/JoystickArea/Base/Knob")
@onready var ability_button: Button = get_node_or_null("Root/AbilityButton")
@onready var beam_button: Button = get_node_or_null("Root/BeamButton")
@onready var slam_button: Button = get_node_or_null("Root/SlamButton")
@onready var dash_button: Button = get_node_or_null("Root/DashButton")
@onready var pause_button: Button = get_node_or_null("Root/PauseButton")
@onready var build_slots_button: Button = get_node_or_null("Root/BuildSlotsButton")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = true
	_set_mobile_control_buttons_visible(force_visible or DisplayServer.is_touchscreen_available())

	if joystick_touch_area == null:
		push_warning("MobileControls could not find JoystickArea.")
	else:
		joystick_touch_area.gui_input.connect(_on_joystick_gui_input)

	if ability_button == null:
		push_warning("MobileControls could not find AbilityButton.")
	elif not ability_button.pressed.is_connected(_on_ability_button_pressed):
		ability_button.pressed.connect(_on_ability_button_pressed)

	if beam_button == null:
		push_warning("MobileControls could not find BeamButton.")
	elif not beam_button.pressed.is_connected(_on_beam_button_pressed):
		beam_button.pressed.connect(_on_beam_button_pressed)

	if slam_button == null:
		push_warning("MobileControls could not find SlamButton.")
	elif not slam_button.pressed.is_connected(_on_slam_button_pressed):
		slam_button.pressed.connect(_on_slam_button_pressed)

	if dash_button == null:
		push_warning("MobileControls could not find DashButton.")
	elif not dash_button.pressed.is_connected(_on_dash_button_pressed):
		dash_button.pressed.connect(_on_dash_button_pressed)

	if pause_button == null:
		push_warning("MobileControls could not find PauseButton.")
	elif not pause_button.pressed.is_connected(_on_pause_button_pressed):
		pause_button.pressed.connect(_on_pause_button_pressed)

	if build_slots_button == null:
		push_warning("MobileControls could not find BuildSlotsButton.")
	elif not build_slots_button.pressed.is_connected(_on_build_slots_button_pressed):
		build_slots_button.pressed.connect(_on_build_slots_button_pressed)

	_update_joystick_visual(Vector2.ZERO)
	_update_ability_button(0.0)
	_update_beam_button(0.0)
	_update_slam_button(0.0)
	_update_dash_button(0.0)


func _process(_delta: float) -> void:
	if get_tree().paused and not _movement_direction.is_zero_approx():
		reset_controls()


func setup_ability_manager(ability_manager: Node) -> void:
	_read_ability_button_labels(ability_manager)
	_update_ability_button(0.0)
	_update_beam_button(0.0)
	_update_slam_button(0.0)

	if ability_manager == null:
		return

	if ability_manager.has_signal("ability_cooldown_changed") and not ability_manager.ability_cooldown_changed.is_connected(_on_ability_cooldown_changed):
		ability_manager.ability_cooldown_changed.connect(_on_ability_cooldown_changed)
	if ability_manager.has_signal("ability_state_changed") and not ability_manager.ability_state_changed.is_connected(_on_ability_state_changed):
		ability_manager.ability_state_changed.connect(_on_ability_state_changed)
	if ability_manager.has_method("get_all_ability_states"):
		for state: Dictionary in ability_manager.get_all_ability_states().values():
			_on_ability_state_changed(state)


func setup_player(player: Node) -> void:
	_update_dash_button(0.0)
	if player != null and player.has_signal("dash_cooldown_changed") and not player.dash_cooldown_changed.is_connected(_on_dash_cooldown_changed):
		player.dash_cooldown_changed.connect(_on_dash_cooldown_changed)


func setup_input_blocker(blocker: Callable) -> void:
	_input_blocker = blocker


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
	if _is_action_blocked() or _is_ability_blocked(1):
		return
	ability_1_pressed.emit()


func _on_beam_button_pressed() -> void:
	if _is_action_blocked() or _is_ability_blocked(2):
		return
	ability_2_pressed.emit()


func _on_slam_button_pressed() -> void:
	if _is_action_blocked() or _is_ability_blocked(3):
		return
	ability_3_pressed.emit()


func _on_pause_button_pressed() -> void:
	pause_pressed.emit()


func _on_build_slots_button_pressed() -> void:
	build_slots_pressed.emit()


func _on_dash_button_pressed() -> void:
	if _is_action_blocked():
		return
	dash_pressed.emit()


func _is_action_blocked() -> bool:
	if get_tree().paused:
		return true
	if _input_blocker.is_valid():
		return bool(_input_blocker.call())
	return false


func _on_ability_cooldown_changed(slot: int, cooldown_remaining: float, _cooldown_total: float) -> void:
	match slot:
		1: _update_ability_button(cooldown_remaining)
		2: _update_beam_button(cooldown_remaining)
		3: _update_slam_button(cooldown_remaining)


func _on_ability_state_changed(state: Dictionary) -> void:
	var slot := int(state.get("slot", 0))
	if slot < 1 or slot > 3:
		return
	_ability_states[slot] = state.duplicate()
	_ability_button_labels[slot] = str(state.get("short_name", _ability_button_labels.get(slot, "Ability")))
	match slot:
		1: _update_ability_button(float(state.get("cooldown_remaining", 0.0)))
		2: _update_beam_button(float(state.get("cooldown_remaining", 0.0)))
		3: _update_slam_button(float(state.get("cooldown_remaining", 0.0)))


func _is_ability_blocked(slot: int) -> bool:
	return bool(_ability_states.get(slot, {}).get("is_blocked", false))


func _on_dash_cooldown_changed(cooldown_remaining: float, _cooldown_total: float) -> void:
	_update_dash_button(cooldown_remaining)


func _update_ability_button(cooldown_remaining: float) -> void:
	if ability_button == null:
		return
	ability_button.text = _ability_button_text(1, cooldown_remaining)


func _update_beam_button(cooldown_remaining: float) -> void:
	if beam_button == null:
		return
	beam_button.text = _ability_button_text(2, cooldown_remaining)


func _update_slam_button(cooldown_remaining: float) -> void:
	if slam_button == null:
		return
	slam_button.text = _ability_button_text(3, cooldown_remaining)


func _ability_button_text(slot: int, cooldown_remaining: float) -> String:
	if cooldown_remaining > 0.0:
		return "%.1f" % cooldown_remaining
	var state: Dictionary = _ability_states.get(slot, {})
	if bool(state.get("is_blocked", false)):
		return str(state.get("blocked_reason", "Blocked")).capitalize()
	return str(_ability_button_labels.get(slot, "Ability"))


func _update_dash_button(cooldown_remaining: float) -> void:
	if dash_button == null:
		return
	dash_button.text = "Dash" if cooldown_remaining <= 0.0 else "%.1f" % cooldown_remaining


func _update_visibility_from_settings() -> void:
	var forced := force_visible
	if _settings_manager != null:
		forced = forced or bool(_settings_manager.get_setting("force_mobile_controls", false))

	visible = true
	_set_mobile_control_buttons_visible(forced or DisplayServer.is_touchscreen_available())


func _set_mobile_control_buttons_visible(controls_visible: bool) -> void:
	for control in [joystick_touch_area, ability_button, beam_button, slam_button, dash_button]:
		if control != null:
			control.visible = controls_visible
	if pause_button != null:
		pause_button.visible = true
	if build_slots_button != null:
		build_slots_button.visible = true


func _read_ability_button_labels(ability_manager: Node) -> void:
	if ability_manager == null or not ability_manager.has_method("get_all_ability_states"):
		return
	var states: Dictionary = ability_manager.get_all_ability_states()
	for slot in states:
		var state: Dictionary = states[slot]
		if ability_manager.has_method("get_ability_name"):
			_ability_button_labels[int(slot)] = ability_manager.get_ability_name(int(slot), true)
		else:
			_ability_button_labels[int(slot)] = str(state.get("short_name", state.get("display_name", _ability_button_labels.get(int(slot), "Ability"))))
