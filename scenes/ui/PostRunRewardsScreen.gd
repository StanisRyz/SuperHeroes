extends CanvasLayer

signal continue_requested

var _result_label: Label
var _base_label: Label
var _time_label: Label
var _kill_label: Label
var _elite_label: Label
var _miniboss_label: Label
var _victory_label: Label
var _evo_label: Label
var _bonus_label: Label
var _total_label: Label
var _currency_label: Label
var _continue_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	_build_ui()
	hide()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.80)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(440, 500)
	panel.offset_left = -220.0
	panel.offset_top = -250.0
	panel.offset_right = 220.0
	panel.offset_bottom = 250.0
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 7)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Run Rewards"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	_result_label = Label.new()
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 15)
	vbox.add_child(_result_label)

	vbox.add_child(HSeparator.new())

	_base_label = _add_row(vbox, "Participation")
	_time_label = _add_row(vbox, "Time bonus")
	_kill_label = _add_row(vbox, "Kill bonus")
	_elite_label = _add_row(vbox, "Elite kills")
	_miniboss_label = _add_row(vbox, "Miniboss kills")
	_victory_label = _add_row(vbox, "Victory bonus")
	_evo_label = _add_row(vbox, "Evolutions")
	_bonus_label = _add_row(vbox, "Reward bonus")

	vbox.add_child(HSeparator.new())

	_total_label = Label.new()
	_total_label.add_theme_font_size_override("font_size", 15)
	vbox.add_child(_total_label)

	_currency_label = Label.new()
	_currency_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_currency_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	_continue_button = Button.new()
	_continue_button.text = "Continue"
	_continue_button.custom_minimum_size = Vector2(180, 46)
	_continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_continue_button.pressed.connect(_on_continue_pressed)
	vbox.add_child(_continue_button)


func _add_row(parent: VBoxContainer, label_text: String) -> Label:
	var hbox := HBoxContainer.new()
	parent.add_child(hbox)
	var key_lbl := Label.new()
	key_lbl.text = "  %s:" % label_text
	key_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key_lbl.add_theme_font_size_override("font_size", 12)
	hbox.add_child(key_lbl)
	var val_lbl := Label.new()
	val_lbl.custom_minimum_size = Vector2(60, 0)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.add_theme_font_size_override("font_size", 12)
	hbox.add_child(val_lbl)
	return val_lbl


func show_rewards(reward_data: Dictionary, progress_summary: Dictionary) -> void:
	var result := str(reward_data.get("result", "defeat"))
	_result_label.text = "Victory!" if result == "victory" else "Defeated"

	_set_row(_base_label, int(reward_data.get("base_reward", 0)))
	_set_row(_time_label, int(reward_data.get("time_reward", 0)))
	_set_row(_kill_label, int(reward_data.get("kill_reward", 0)))
	_set_row(_elite_label, int(reward_data.get("elite_reward", 0)))
	_set_row(_miniboss_label, int(reward_data.get("miniboss_reward", 0)))
	_set_row(_victory_label, int(reward_data.get("victory_bonus", 0)))
	_set_row(_evo_label, int(reward_data.get("evolution_bonus", 0)))
	_set_row(_bonus_label, int(reward_data.get("starting_bonus", 0)))

	_total_label.text = "  Earned this run:  +%d" % int(reward_data.get("total_reward", 0))
	_currency_label.text = "  Total currency:    %d" % int(progress_summary.get("currency", 0))

	show()
	if _continue_button != null:
		_continue_button.grab_focus()


func hide_screen() -> void:
	hide()


func _set_row(lbl: Label, value: int) -> void:
	if lbl != null:
		lbl.text = "+%d" % value


func _on_continue_pressed() -> void:
	continue_requested.emit()
