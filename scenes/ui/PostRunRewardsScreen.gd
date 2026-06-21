extends CanvasLayer

signal continue_requested

const UIStateColors = preload("res://scenes/ui/UIStateColors.gd")

var _result_label: Label
var _base_label: Label
var _time_label: Label
var _kill_label: Label
var _elite_label: Label
var _miniboss_label: Label
var _final_boss_label: Label
var _victory_label: Label
var _evo_label: Label
var _bonus_label: Label
var _goal_reward_label: Label
var _total_label: Label
var _currency_label: Label
var _progress_label: Label
var _goals_label: Label
var _item_rewards_label: Label
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
	panel.custom_minimum_size = Vector2(520, 620)
	panel.offset_left = -260.0
	panel.offset_top = -310.0
	panel.offset_right = 260.0
	panel.offset_bottom = 310.0
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

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

	_result_label = Label.new()
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 15)
	content.add_child(_result_label)

	content.add_child(HSeparator.new())

	_base_label = _add_row(content, "Participation")
	_time_label = _add_row(content, "Time bonus")
	_kill_label = _add_row(content, "Kill bonus")
	_elite_label = _add_row(content, "Elite kills")
	_miniboss_label = _add_row(content, "Miniboss kills")
	_final_boss_label = _add_row(content, "Final boss")
	_victory_label = _add_row(content, "Victory bonus")
	_evo_label = _add_row(content, "Evolutions")
	_bonus_label = _add_row(content, "Reward bonus")
	_goal_reward_label = _add_row(content, "Goal rewards")

	content.add_child(HSeparator.new())

	_total_label = Label.new()
	_total_label.add_theme_font_size_override("font_size", 15)
	content.add_child(_total_label)

	_currency_label = Label.new()
	_currency_label.add_theme_font_size_override("font_size", 14)
	content.add_child(_currency_label)

	_progress_label = Label.new()
	_progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_progress_label.add_theme_font_size_override("font_size", 12)
	content.add_child(_progress_label)

	_goals_label = Label.new()
	_goals_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_goals_label.add_theme_font_size_override("font_size", 12)
	content.add_child(_goals_label)

	content.add_child(HSeparator.new())

	var item_rewards_title := Label.new()
	item_rewards_title.text = "  Item Rewards"
	item_rewards_title.add_theme_font_size_override("font_size", 14)
	content.add_child(item_rewards_title)

	_item_rewards_label = Label.new()
	_item_rewards_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_item_rewards_label.add_theme_font_size_override("font_size", 12)
	content.add_child(_item_rewards_label)

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
	if visible:
		return
	var result := str(reward_data.get("result", "defeat"))
	_result_label.text = "Victory!" if result == "victory" else "Defeated"

	_set_row(_base_label, int(reward_data.get("base_reward", 0)))
	_set_row(_time_label, int(reward_data.get("time_reward", 0)))
	_set_row(_kill_label, int(reward_data.get("kill_reward", 0)))
	_set_row(_elite_label, int(reward_data.get("elite_reward", 0)))
	_set_row(_miniboss_label, int(reward_data.get("miniboss_reward", 0)))
	_set_row(_final_boss_label, int(reward_data.get("final_boss_reward", 0)))
	_set_row(_victory_label, int(reward_data.get("victory_bonus", 0)))
	_set_row(_evo_label, int(reward_data.get("evolution_bonus", 0)))
	_set_row(_bonus_label, int(reward_data.get("starting_bonus", 0)))
	_set_row(_goal_reward_label, int(reward_data.get("goal_reward", 0)))

	var total := int(reward_data.get("total_reward", 0))
	var currency := int(progress_summary.get("currency", 0))
	_total_label.text = "  Earned this run:  +%d" % total
	_total_label.modulate = UIStateColors.positive_color() if total > 0 else UIStateColors.muted_color()
	_currency_label.text = "  Total currency:    %d" % currency
	_currency_label.modulate = UIStateColors.positive_color() if currency > 0 else Color.WHITE
	_update_progress_text(reward_data)
	_update_goals_text(reward_data)
	_update_item_rewards_text(reward_data)

	show()
	if _continue_button != null:
		_continue_button.disabled = false
		_continue_button.grab_focus()


func hide_screen() -> void:
	hide()
	if _continue_button != null:
		_continue_button.disabled = false


func _set_row(lbl: Label, value: int) -> void:
	if lbl != null:
		lbl.text = "+%d" % value
		lbl.modulate = UIStateColors.positive_color() if value > 0 else UIStateColors.muted_color()


func _update_progress_text(reward_data: Dictionary) -> void:
	if _progress_label == null:
		return
	var run_summary: Dictionary = reward_data.get("run_summary", {})
	var mastery: Dictionary = reward_data.get("mastery_changes", {})
	var stage_mastery: Dictionary = reward_data.get("stage_mastery_changes", {})
	var hero_after: Dictionary = mastery.get("after", {})
	var stage_after: Dictionary = stage_mastery.get("after", {})
	var lines: PackedStringArray = []
	lines.append("Grade: %s   Build: %s" % [
		str(run_summary.get("run_grade", "C")),
		str(run_summary.get("dominant_archetype", "")).capitalize() if not str(run_summary.get("dominant_archetype", "")).is_empty() else "Mixed",
	])
	lines.append("Slots: A%d / P%d / Act%d   Evolutions: %d (A%d / Act%d / P%d)" % [
		int(run_summary.get("selected_attack_line_count", 0)),
		int(run_summary.get("selected_passive_line_count", 0)),
		int(run_summary.get("selected_active_line_count", 0)),
		int(run_summary.get("applied_evolution_count", 0)),
		int(run_summary.get("attack_evolution_count", 0)),
		int(run_summary.get("active_evolution_count", 0)),
		int(run_summary.get("passive_evolution_count", 0)),
	])
	var titles: Array = run_summary.get("applied_evolution_titles", [])
	if not titles.is_empty():
		lines.append("Selected evolutions: %s" % _format_list(titles))
	lines.append("Hero mastery: Lv %d -> %d, runs %d, victories %d" % [
		int(mastery.get("level_before", 1)),
		int(mastery.get("level_after", 1)),
		int(hero_after.get("runs_played", 0)),
		int(hero_after.get("victories", 0)),
	])
	lines.append("Stage mastery: attempts %d, victories %d, best grade %s" % [
		int(stage_after.get("attempts", 0)),
		int(stage_after.get("victories", 0)),
		str(stage_after.get("best_grade", "-")),
	])
	_progress_label.text = "\n".join(lines)


func _update_goals_text(reward_data: Dictionary) -> void:
	if _goals_label == null:
		return
	var goals: Array = reward_data.get("newly_completed_goals", [])
	if goals.is_empty():
		_goals_label.text = "Goals completed: none this run"
		_goals_label.modulate = UIStateColors.muted_color()
		return
	var lines: PackedStringArray = ["Goals completed:"]
	for goal in goals:
		lines.append("+%d  %s" % [int(goal.get("reward_currency", 0)), str(goal.get("title", goal.get("id", "")))])
	_goals_label.text = "\n".join(lines)
	_goals_label.modulate = UIStateColors.positive_color()


func _update_item_rewards_text(reward_data: Dictionary) -> void:
	if _item_rewards_label == null:
		return
	var items: Array = reward_data.get("item_rewards", [])
	if items.is_empty():
		_item_rewards_label.text = "  No items found."
		_item_rewards_label.modulate = UIStateColors.muted_color()
		return
	var lines: PackedStringArray = []
	for item in items:
		var iname := str(item.get("name", item.get("template_id", "?")))
		var slot := str(item.get("slot_id", ""))
		var rarity := str(item.get("rarity", ""))
		lines.append("  + %s  [%s / %s]" % [iname, slot, rarity])
	_item_rewards_label.text = "\n".join(lines)
	_item_rewards_label.modulate = UIStateColors.positive_color()


func _format_list(values: Array) -> String:
	var parts: PackedStringArray = []
	for value in values:
		parts.append(str(value))
	return ", ".join(parts)


func _on_continue_pressed() -> void:
	if _continue_button != null:
		if _continue_button.disabled:
			return
		_continue_button.disabled = true
	continue_requested.emit()
