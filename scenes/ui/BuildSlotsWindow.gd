extends CanvasLayer

signal closed

const CATEGORY_ORDER := ["attack", "passive", "active"]
const CATEGORY_LABELS := {
	"attack": "Attack",
	"passive": "Passive",
	"active": "Active",
}
const CATEGORY_COLORS := {
	"attack": Color(1.0, 0.62, 0.32, 1.0),
	"passive": Color(0.42, 0.9, 0.62, 1.0),
	"active": Color(0.54, 0.74, 1.0, 1.0),
}

var _upgrade_manager: Node = null
var _evolution_manager: Node = null
var _section_labels: Dictionary = {}
var _slot_rows: Dictionary = {}
var _evolution_label: Label = null
var _evolution_ready_label: Label = null
var _evolution_closest_label: Label = null
var _evolution_progress_label: Label = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	layer = 35
	_build_ui()
	hide()


func setup(upgrade_manager: Node, evolution_manager: Node = null) -> void:
	_upgrade_manager = upgrade_manager
	_evolution_manager = evolution_manager
	if _upgrade_manager != null and _upgrade_manager.has_signal("build_changed") and not _upgrade_manager.build_changed.is_connected(_on_build_changed):
		_upgrade_manager.build_changed.connect(_on_build_changed)
	if _evolution_manager != null and _evolution_manager.has_signal("evolution_state_changed") and not _evolution_manager.evolution_state_changed.is_connected(_on_evolution_state_changed):
		_evolution_manager.evolution_state_changed.connect(_on_evolution_state_changed)
	_refresh()


func open() -> void:
	_refresh()
	show()


func close() -> void:
	if not visible:
		return
	hide()
	closed.emit()


func is_open() -> bool:
	return visible


func _build_ui() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var dimmer := ColorRect.new()
	dimmer.name = "Dimmer"
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.62)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dimmer)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -330.0
	panel.offset_top = -260.0
	panel.offset_right = 330.0
	panel.offset_bottom = 260.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(panel)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var main := VBoxContainer.new()
	main.name = "Main"
	main.add_theme_constant_override("separation", 12)
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)
	scroll.add_child(main)

	var header := HBoxContainer.new()
	header.name = "Header"
	header.add_theme_constant_override("separation", 12)
	main.add_child(header)

	var title := Label.new()
	title.name = "TitleLabel"
	title.text = "Build Slots"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	header.add_child(title)

	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.custom_minimum_size = Vector2(96.0, 40.0)
	close_button.text = "Close"
	close_button.pressed.connect(close)
	header.add_child(close_button)

	for category in CATEGORY_ORDER:
		main.add_child(_create_section(category))

	_evolution_label = Label.new()
	_evolution_label.name = "EvolutionLabel"
	_evolution_label.custom_minimum_size = Vector2(0.0, 28.0)
	_evolution_label.clip_text = true
	_evolution_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_evolution_label.modulate = Color(1.0, 0.85, 0.32, 1.0)
	main.add_child(_evolution_label)

	_evolution_ready_label = Label.new()
	_evolution_ready_label.name = "EvolutionReadyLabel"
	_evolution_ready_label.custom_minimum_size = Vector2(0.0, 24.0)
	_evolution_ready_label.clip_text = true
	_evolution_ready_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_evolution_ready_label.modulate = Color(0.86, 0.9, 1.0, 1.0)
	main.add_child(_evolution_ready_label)

	_evolution_closest_label = Label.new()
	_evolution_closest_label.name = "EvolutionClosestLabel"
	_evolution_closest_label.custom_minimum_size = Vector2(0.0, 24.0)
	_evolution_closest_label.clip_text = true
	_evolution_closest_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_evolution_closest_label.modulate = Color(0.78, 0.82, 0.92, 1.0)
	main.add_child(_evolution_closest_label)

	_evolution_progress_label = Label.new()
	_evolution_progress_label.name = "EvolutionProgressLabel"
	_evolution_progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_evolution_progress_label.modulate = Color(0.88, 0.9, 0.96, 1.0)
	main.add_child(_evolution_progress_label)


func _create_section(category: String) -> Control:
	var section := VBoxContainer.new()
	section.name = "%sSection" % str(CATEGORY_LABELS.get(category, category)).replace(" ", "")
	section.add_theme_constant_override("separation", 5)

	var title := Label.new()
	title.name = "Title"
	title.text = "%s 0 / 4" % CATEGORY_LABELS.get(category, category.capitalize())
	title.modulate = CATEGORY_COLORS.get(category, Color.WHITE)
	title.add_theme_font_size_override("font_size", 15)
	section.add_child(title)
	_section_labels[category] = title

	var rows: Array[Label] = []
	for index in range(4):
		var row := Label.new()
		row.name = "Slot%d" % (index + 1)
		row.custom_minimum_size = Vector2(0.0, 24.0)
		row.text = "%d. Empty" % (index + 1)
		row.clip_text = true
		row.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		section.add_child(row)
		rows.append(row)
	_slot_rows[category] = rows

	return section


func _refresh() -> void:
	var slot_state := _get_slot_state()
	for category in CATEGORY_ORDER:
		var category_state: Dictionary = slot_state.get(category, {})
		var selected: Array = category_state.get("selected", [])
		var used := int(category_state.get("used", selected.size()))
		var max_slots := int(category_state.get("max", 4))
		var title_label := _section_labels.get(category) as Label
		if title_label != null:
			title_label.text = "%s %d / %d" % [CATEGORY_LABELS.get(category, category.capitalize()), used, max_slots]

		var rows: Array = _slot_rows.get(category, [])
		for index in range(rows.size()):
			var row := rows[index] as Label
			if row == null:
				continue
			if index < selected.size():
				row.text = "%d. %s" % [index + 1, _format_upgrade_line(str(selected[index]))]
				row.modulate = Color.WHITE
			else:
				row.text = "%d. Empty" % (index + 1)
				row.modulate = Color(0.68, 0.68, 0.68, 1.0)
	_update_evolution_label()


func _get_slot_state() -> Dictionary:
	if _upgrade_manager == null:
		return {}
	if _upgrade_manager.has_method("get_slot_state"):
		return _upgrade_manager.get_slot_state()
	if _upgrade_manager.has_method("debug_get_slot_state"):
		return _upgrade_manager.debug_get_slot_state()
	return {}


func _format_upgrade_line(upgrade_id: String) -> String:
	if _upgrade_manager == null or not _upgrade_manager.has_method("get_upgrade_definition_summary"):
		return upgrade_id
	var summary: Dictionary = _upgrade_manager.get_upgrade_definition_summary(upgrade_id)
	if summary.is_empty():
		return upgrade_id
	var title := str(summary.get("title", upgrade_id))
	var current_level := int(summary.get("current_level", 0))
	var max_level := int(summary.get("max_level", 1))
	var hint := _format_line_evolution_hint(upgrade_id)
	if hint.is_empty():
		return "%s  Lv %d/%d" % [title, current_level, max_level]
	return "%s  Lv %d/%d -> %s" % [title, current_level, max_level, hint]


func _format_line_evolution_hint(upgrade_id: String) -> String:
	if _evolution_manager == null or not _evolution_manager.has_method("get_synergy_info_for_upgrade_line"):
		return ""
	var info: Dictionary = _evolution_manager.get_synergy_info_for_upgrade_line(upgrade_id)
	if info.is_empty():
		return ""
	var title := str(info.get("evolution_title", info.get("synergy_evolution_title", "")))
	var state := str(info.get("state", ""))
	if state == "ready":
		return "READY: %s" % title
	if state == "selected":
		return "Selected: %s" % title
	return "%s %d/3" % [title, int(info.get("selected_lines_count", 0))]


func _on_build_changed(_dominant_archetype: String, _points: Dictionary) -> void:
	if visible:
		_refresh()


func _on_evolution_state_changed() -> void:
	if visible:
		_refresh()


func _update_evolution_label() -> void:
	if _evolution_label == null or _evolution_ready_label == null or _evolution_closest_label == null or _evolution_progress_label == null:
		return
	if _evolution_manager == null:
		_evolution_label.text = "Evolutions: None"
		_evolution_ready_label.text = "Ready: 0"
		_evolution_closest_label.text = "Closest: none"
		_evolution_progress_label.text = ""
		return
	var titles: Array = []
	if _evolution_manager.has_method("get_applied_evolution_titles"):
		titles = _evolution_manager.get_applied_evolution_titles()
	_evolution_label.text = "Evolutions: %s" % (", ".join(titles) if not titles.is_empty() else "None")
	if _evolution_manager.has_method("get_evolution_grid_display_state"):
		var state: Dictionary = _evolution_manager.get_evolution_grid_display_state()
		_evolution_ready_label.text = "Ready: %d   Selected: %d" % [int(state.get("ready_count", 0)), int(state.get("selected_count", 0))]
		var closest: Dictionary = state.get("closest", {})
		if closest.is_empty():
			_evolution_closest_label.text = "Closest: none"
		else:
			_evolution_closest_label.text = "Closest: %s  %d/3 lines  %d/3 max" % [
				str(closest.get("evolution_title", "?")),
				int(closest.get("selected_lines_count", 0)),
				int(closest.get("maxed_lines_count", 0)),
			]
		_evolution_progress_label.text = _format_progress_block(state)
	else:
		_evolution_ready_label.text = "Ready: 0"
		_evolution_closest_label.text = "Closest: unavailable"
		_evolution_progress_label.text = ""


func _format_progress_block(state: Dictionary) -> String:
	var lines: PackedStringArray = []
	var ready_entries: Array = state.get("ready", [])
	if not ready_entries.is_empty():
		var ready_titles: PackedStringArray = []
		for entry in ready_entries:
			ready_titles.append("%s [%s]" % [str(entry.get("evolution_title", "?")), str(entry.get("target_type", "")).to_upper()])
		lines.append("Ready: %s" % ", ".join(ready_titles))
	var progress: Array = state.get("progress", [])
	var shown := 0
	for entry in progress:
		if shown >= 4:
			break
		var entry_state := str(entry.get("state", ""))
		if entry_state == "locked" or entry_state == "selected":
			continue
		lines.append("%s [%s] %d/3 lines, %d/3 max" % [
			str(entry.get("evolution_title", "?")),
			str(entry.get("target_type", "")).to_upper(),
			int(entry.get("selected_lines_count", 0)),
			int(entry.get("maxed_lines_count", 0)),
		])
		var missing: Array = entry.get("synergy_missing", [])
		if not missing.is_empty():
			lines.append("  Needs: %s" % _format_compact_list(missing, 3))
		shown += 1
	return "\n".join(lines)


func _format_compact_list(values: Array, limit: int) -> String:
	var parts: PackedStringArray = []
	for index in range(mini(values.size(), limit)):
		parts.append(str(values[index]))
	if values.size() > limit:
		parts.append("+%d" % (values.size() - limit))
	return ", ".join(parts)
