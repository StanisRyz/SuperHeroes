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
var _section_labels: Dictionary = {}
var _slot_rows: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	layer = 35
	_build_ui()
	hide()


func setup(upgrade_manager: Node) -> void:
	_upgrade_manager = upgrade_manager
	if _upgrade_manager != null and _upgrade_manager.has_signal("build_changed") and not _upgrade_manager.build_changed.is_connected(_on_build_changed):
		_upgrade_manager.build_changed.connect(_on_build_changed)
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
	margin.add_child(main)

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
	return "%s  Lv %d/%d" % [title, current_level, max_level]


func _on_build_changed(_dominant_archetype: String, _points: Dictionary) -> void:
	if visible:
		_refresh()
