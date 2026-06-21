extends CanvasLayer

signal back_requested
signal buy_requested(hero_id: String, upgrade_id: String)
signal equipment_buy_requested(hero_id: String, equipment_id: String)

const UIStateColors = preload("res://scenes/ui/UIStateColors.gd")

var _meta_manager: Node
var _hero_data_provider: Node
var _selected_hero_id: String = ""
var _active_tab: String = "equipment"
var _selected_inventory_cell_index: int = 0
var _heroes: Array[Dictionary] = []
var _currency_label: Label
var _goals_label: Label
var _back_button: Button
var _hero_selector: HBoxContainer
var _equipment_tab_button: Button
var _training_tab_button: Button
var _equipment_content: Control
var _training_content: Control
var _list_vbox: VBoxContainer

var _rows: Array[Dictionary] = []
var _hero_buttons: Dictionary = {}

# Equipment panel references
var _equip_hero_name_label: Label
var _equip_hero_subtitle_label: Label
var _equip_hero_swatch: ColorRect
var _equip_hero_status_label: Label
var _equipment_slot_rows: Dictionary = {}
var _inventory_grid: GridContainer
var _inventory_detail_label: Label
var _inventory_buttons: Dictionary = {}
var _inventory_equip_button: Button
var _selected_inventory_instance_id: String = ""
var _training_hero_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 18
	_build_ui()
	hide()


func setup(meta_progression_manager: Node, hero_data_provider: Node = null) -> void:
	_meta_manager = meta_progression_manager
	_hero_data_provider = hero_data_provider
	_reload_heroes()
	if _meta_manager == null:
		return
	if _meta_manager.has_signal("currency_changed") and not _meta_manager.currency_changed.is_connected(_on_currency_changed):
		_meta_manager.currency_changed.connect(_on_currency_changed)
	if _meta_manager.has_signal("meta_upgrade_changed") and not _meta_manager.meta_upgrade_changed.is_connected(_on_meta_upgrade_changed):
		_meta_manager.meta_upgrade_changed.connect(_on_meta_upgrade_changed)
	if _meta_manager.has_signal("equipment_upgrade_changed") and not _meta_manager.equipment_upgrade_changed.is_connected(_on_equipment_upgrade_changed):
		_meta_manager.equipment_upgrade_changed.connect(_on_equipment_upgrade_changed)
	if _meta_manager.has_signal("inventory_changed") and not _meta_manager.inventory_changed.is_connected(_on_inventory_changed):
		_meta_manager.inventory_changed.connect(_on_inventory_changed)
	if _meta_manager.has_signal("equipment_changed") and not _meta_manager.equipment_changed.is_connected(_on_equipment_slot_changed):
		_meta_manager.equipment_changed.connect(_on_equipment_slot_changed)
	if _meta_manager.has_method("ensure_training_data_for_all_heroes"):
		_meta_manager.ensure_training_data_for_all_heroes(_get_hero_ids())
	if _meta_manager.has_method("ensure_equipment_data_for_all_heroes"):
		_meta_manager.ensure_equipment_data_for_all_heroes(_get_hero_ids())


func open(hero_id: String = "") -> void:
	set_selected_hero(hero_id)
	_active_tab = "equipment"
	refresh()
	show()
	if _equipment_tab_button != null:
		_equipment_tab_button.grab_focus()


func close() -> void:
	hide()


func refresh() -> void:
	if _meta_manager == null:
		return
	if _selected_hero_id.is_empty():
		set_selected_hero("")
	if _currency_label != null:
		_currency_label.text = "Currency: %d" % _meta_manager.get_currency()
	_update_goals_label()
	_rebuild_rows_if_needed()
	_update_rows()
	_refresh_equipment_panel()
	_refresh_inventory_shell()
	_update_tab_state()


func set_selected_hero(hero_id: String) -> void:
	_reload_heroes()
	var resolved := _resolve_hero_id(hero_id)
	_selected_hero_id = resolved
	if _meta_manager != null and _meta_manager.has_method("ensure_training_data_for_hero"):
		_meta_manager.ensure_training_data_for_hero(_selected_hero_id)
	if _meta_manager != null and _meta_manager.has_method("ensure_equipment_data_for_hero"):
		_meta_manager.ensure_equipment_data_for_hero(_selected_hero_id)
	if visible:
		refresh()


# ─── UI skeleton ──────────────────────────────────────────────────────────────

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.045, 0.06, 0.075, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)
	margin.add_child(main_vbox)

	# ── header ────────────────────────────────────────────────────────────────
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 8)
	nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(nav)

	_equipment_tab_button = Button.new()
	_equipment_tab_button.text = "Equipment"
	_equipment_tab_button.custom_minimum_size = Vector2(150, 42)
	_equipment_tab_button.pressed.connect(_set_active_tab.bind("equipment"))
	nav.add_child(_equipment_tab_button)

	_training_tab_button = Button.new()
	_training_tab_button.text = "Training"
	_training_tab_button.custom_minimum_size = Vector2(150, 42)
	_training_tab_button.pressed.connect(_set_active_tab.bind("training"))
	nav.add_child(_training_tab_button)

	var nav_spacer := Control.new()
	nav_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(nav_spacer)

	_currency_label = Label.new()
	_currency_label.text = "Currency: 0"
	_currency_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_currency_label.add_theme_font_size_override("font_size", 14)
	_currency_label.modulate = Color(0.88, 0.92, 0.96, 1.0)
	nav.add_child(_currency_label)

	_back_button = Button.new()
	_back_button.text = "Main Menu"
	_back_button.custom_minimum_size = Vector2(150, 42)
	_back_button.pressed.connect(_on_back_pressed)
	nav.add_child(_back_button)

	_goals_label = Label.new()
	_goals_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_goals_label.add_theme_font_size_override("font_size", 10)
	_goals_label.modulate = Color(0.56, 0.62, 0.7, 1.0)
	main_vbox.add_child(_goals_label)

	main_vbox.add_child(HSeparator.new())

	# ── tab content area ──────────────────────────────────────────────────────
	_equipment_content = _build_equipment_panel()
	_equipment_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_equipment_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(_equipment_content)

	_training_content = _build_training_panel()
	_training_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_training_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(_training_content)

	_update_tab_state()

func _build_training_panel() -> Control:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	var section_title := Label.new()
	section_title.text = "Training Upgrades"
	section_title.add_theme_font_size_override("font_size", 16)
	section_title.modulate = Color(0.9, 0.9, 0.7, 1.0)
	vbox.add_child(section_title)

	_training_hero_label = Label.new()
	_training_hero_label.text = "Hero: -"
	_training_hero_label.add_theme_font_size_override("font_size", 12)
	_training_hero_label.modulate = Color(0.72, 0.8, 0.9, 1.0)
	vbox.add_child(_training_hero_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_list_vbox = VBoxContainer.new()
	_list_vbox.add_theme_constant_override("separation", 8)
	_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list_vbox)

	return vbox


func _build_equipment_panel() -> Control:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var content_row := HBoxContainer.new()
	content_row.add_theme_constant_override("separation", 12)
	content_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content_row)

	var equipped_panel := PanelContainer.new()
	equipped_panel.custom_minimum_size = Vector2(430, 0)
	equipped_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_row.add_child(equipped_panel)

	var equipped_vbox := VBoxContainer.new()
	equipped_vbox.add_theme_constant_override("separation", 8)
	equipped_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equipped_panel.add_child(equipped_vbox)

	var section_title := Label.new()
	section_title.text = "Equipped Gear"
	section_title.add_theme_font_size_override("font_size", 16)
	section_title.modulate = Color(0.7, 0.85, 1.0, 1.0)
	equipped_vbox.add_child(section_title)

	# ── hero preview ──────────────────────────────────────────────────────────
	var hero_panel := PanelContainer.new()
	hero_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equipped_vbox.add_child(hero_panel)

	var hero_vbox := VBoxContainer.new()
	hero_vbox.add_theme_constant_override("separation", 4)
	hero_panel.add_child(hero_vbox)

	_equip_hero_swatch = ColorRect.new()
	_equip_hero_swatch.custom_minimum_size = Vector2(0, 6)
	_equip_hero_swatch.color = Color(0.5, 0.5, 0.5, 1.0)
	hero_vbox.add_child(_equip_hero_swatch)

	_equip_hero_name_label = Label.new()
	_equip_hero_name_label.text = "—"
	_equip_hero_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_equip_hero_name_label.add_theme_font_size_override("font_size", 15)
	hero_vbox.add_child(_equip_hero_name_label)

	_equip_hero_subtitle_label = Label.new()
	_equip_hero_subtitle_label.text = ""
	_equip_hero_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_equip_hero_subtitle_label.add_theme_font_size_override("font_size", 11)
	_equip_hero_subtitle_label.modulate = Color(0.75, 0.82, 0.92, 1.0)
	hero_vbox.add_child(_equip_hero_subtitle_label)

	_equip_hero_status_label = Label.new()
	_equip_hero_status_label.text = ""
	_equip_hero_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_equip_hero_status_label.add_theme_font_size_override("font_size", 10)
	_equip_hero_status_label.modulate = Color(0.6, 0.9, 0.6, 1.0)
	hero_vbox.add_child(_equip_hero_status_label)

	# ── slot grid ─────────────────────────────────────────────────────────────
	# Layout:
	#   [Core]          [Gauntlets]
	#   [Suit]   HERO   [Boots]
	#   [Emblem]        [Artifact]
	var slot_hbox := HBoxContainer.new()
	slot_hbox.add_theme_constant_override("separation", 8)
	slot_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equipped_vbox.add_child(slot_hbox)

	var left_col := VBoxContainer.new()
	left_col.add_theme_constant_override("separation", 6)
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_hbox.add_child(left_col)
	left_col.add_child(_build_equipment_slot("core", "Core"))
	left_col.add_child(_build_equipment_slot("suit", "Suit"))
	left_col.add_child(_build_equipment_slot("emblem", "Emblem"))

	var center_spacer := Control.new()
	center_spacer.custom_minimum_size = Vector2(32, 0)
	center_spacer.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slot_hbox.add_child(center_spacer)

	var right_col := VBoxContainer.new()
	right_col.add_theme_constant_override("separation", 6)
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_hbox.add_child(right_col)
	right_col.add_child(_build_equipment_slot("gauntlets", "Gauntlets"))
	right_col.add_child(_build_equipment_slot("boots", "Boots"))
	right_col.add_child(_build_equipment_slot("artifact", "Artifact"))

	var note := Label.new()
	note.text = "Equipped gear uses shared currency. Select an inventory item to equip it."
	note.add_theme_font_size_override("font_size", 10)
	note.modulate = Color(0.55, 0.6, 0.65, 1.0)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	equipped_vbox.add_child(note)

	var inventory_panel := _build_inventory_panel()
	inventory_panel.custom_minimum_size = Vector2(470, 0)
	inventory_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_row.add_child(inventory_panel)

	return scroll


func _build_inventory_panel() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)

	var title := Label.new()
	title.text = "Inventory"
	title.add_theme_font_size_override("font_size", 15)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_inventory_equip_button = Button.new()
	_inventory_equip_button.text = "Equip"
	_inventory_equip_button.disabled = true
	_inventory_equip_button.custom_minimum_size = Vector2(120, 32)
	_inventory_equip_button.pressed.connect(_on_inventory_equip_pressed)
	header.add_child(_inventory_equip_button)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(body)

	body.add_child(_build_inventory_grid())

	var detail_scroll := ScrollContainer.new()
	detail_scroll.custom_minimum_size = Vector2(0, 130)
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(detail_scroll)

	_inventory_detail_label = Label.new()
	_inventory_detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inventory_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_inventory_detail_label.add_theme_font_size_override("font_size", 11)
	_inventory_detail_label.modulate = Color(0.82, 0.86, 0.92, 1.0)
	detail_scroll.add_child(_inventory_detail_label)

	return panel


func _build_equipment_slot(slot_id: String, slot_name: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 1)
	panel.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = slot_name
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	var item_lbl := Label.new()
	item_lbl.text = "Equipment"
	item_lbl.add_theme_font_size_override("font_size", 10)
	item_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(item_lbl)

	var level_lbl := Label.new()
	level_lbl.text = "Level 0 / 0"
	level_lbl.add_theme_font_size_override("font_size", 10)
	level_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_lbl.modulate = Color(0.7, 0.7, 0.7, 1.0)
	vbox.add_child(level_lbl)

	var hint_lbl := Label.new()
	hint_lbl.text = ""
	hint_lbl.add_theme_font_size_override("font_size", 9)
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_lbl.modulate = Color(0.5, 0.55, 0.6, 1.0)
	vbox.add_child(hint_lbl)

	var buy_btn := Button.new()
	buy_btn.text = "Upgrade"
	buy_btn.disabled = true
	buy_btn.custom_minimum_size = Vector2(0, 28)
	buy_btn.add_theme_font_size_override("font_size", 9)
	buy_btn.pressed.connect(_on_equipment_buy_pressed.bind(slot_id))
	vbox.add_child(buy_btn)

	_equipment_slot_rows[slot_id] = {
		"slot_name": name_lbl,
		"display_name": item_lbl,
		"level": level_lbl,
		"bonus": hint_lbl,
		"button": buy_btn,
		"panel": panel,
	}
	# Allow clicking the slot panel to view detail of the equipped item
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.gui_input.connect(_on_equipment_slot_panel_clicked.bind(slot_id))
	return panel


func _refresh_equipment_panel() -> void:
	var hero := _get_selected_hero_data()
	if _equip_hero_name_label == null:
		return
	var display_name := str(hero.get("display_name", _selected_hero_id.capitalize()))
	var subtitle := str(hero.get("subtitle", str(hero.get("playstyle", ""))))
	var color: Color = hero.get("color", Color(0.5, 0.5, 0.5, 1.0))
	var unlocked: bool = hero.get("unlocked_by_default", true)

	_equip_hero_name_label.text = display_name
	_equip_hero_subtitle_label.text = subtitle
	if _training_hero_label != null:
		_training_hero_label.text = "Hero: %s" % display_name
	if _equip_hero_swatch != null:
		_equip_hero_swatch.color = color
	if _equip_hero_status_label != null:
		_equip_hero_status_label.text = "Owned" if unlocked else "Locked"
		_equip_hero_status_label.modulate = Color(0.6, 0.9, 0.6, 1.0) if unlocked else Color(0.8, 0.5, 0.3, 1.0)
		_update_equipment_slots()


func _build_inventory_grid() -> Control:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 250)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_inventory_grid = GridContainer.new()
	_inventory_grid.columns = 5
	_inventory_grid.add_theme_constant_override("h_separation", 6)
	_inventory_grid.add_theme_constant_override("v_separation", 6)
	_inventory_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_inventory_grid)
	return scroll


func _get_inventory_cell_data() -> Array:
	var cells: Array = []
	if _meta_manager != null and _meta_manager.has_method("get_inventory_items_for_hero"):
		var items: Array = _meta_manager.get_inventory_items_for_hero(_selected_hero_id)
		var equipped: Dictionary = {}
		if _meta_manager.has_method("get_equipped_items_for_hero"):
			equipped = _meta_manager.get_equipped_items_for_hero(_selected_hero_id)
		for item in items:
			if not item is Dictionary:
				continue
			var instance_id := str(item.get("instance_id", ""))
			var template_id := str(item.get("template_id", ""))
			var slot_id := str(item.get("slot_id", ""))
			var level := int(item.get("level", 0))
			var def := _resolve_item_template(template_id)
			var display_name := str(def.get("display_name", template_id)) if not def.is_empty() else template_id
			var max_level := int(def.get("max_level", 10)) if not def.is_empty() else 10
			var is_equipped := str(equipped.get(slot_id, "")) == instance_id
			cells.append({
				"occupied": true,
				"instance_id": instance_id,
				"template_id": template_id,
				"slot_id": slot_id,
				"display_name": display_name,
				"level": level,
				"max_level": max_level,
				"is_equipped": is_equipped,
				"definition": def,
			})
	else:
		# Fallback: show primary equipment definitions as preview cells
		var defs: Array = _meta_manager.get_equipment_definitions(_selected_hero_id) if _meta_manager != null and _meta_manager.has_method("get_equipment_definitions") else []
		for def in defs:
			if not def is Dictionary:
				continue
			var equipment_id := str(def.get("equipment_id", ""))
			if equipment_id.is_empty():
				continue
			var level := _get_equipment_level(equipment_id)
			cells.append({
				"occupied": true,
				"instance_id": "",
				"template_id": equipment_id,
				"slot_id": str(def.get("slot_id", "")),
				"display_name": str(def.get("display_name", "")),
				"level": level,
				"max_level": int(def.get("max_level", 0)),
				"is_equipped": true,
				"definition": def,
			})
	while cells.size() < 20:
		cells.append({"occupied": false})
	return cells


func _resolve_item_template(template_id: String) -> Dictionary:
	if template_id.is_empty():
		return {}
	if _meta_manager == null:
		return {}
	if _meta_manager.has_method("get_equipment_definition"):
		var def: Dictionary = _meta_manager.get_equipment_definition(_selected_hero_id, template_id)
		if not def.is_empty():
			return def
	if _meta_manager.has_method("get_alt_item_template"):
		var def: Dictionary = _meta_manager.get_alt_item_template(template_id)
		if not def.is_empty():
			return def
	return {}


func _refresh_inventory_shell() -> void:
	_refresh_inventory_grid()


func _refresh_inventory_grid() -> void:
	if _inventory_grid == null:
		return
	for child in _inventory_grid.get_children():
		child.queue_free()
	_inventory_buttons.clear()

	var cells := _get_inventory_cell_data()
	# Restore selection by instance_id if possible
	var restore_index := 0
	if not _selected_inventory_instance_id.is_empty():
		for i in range(cells.size()):
			var c: Dictionary = cells[i]
			if bool(c.get("occupied", false)) and str(c.get("instance_id", "")) == _selected_inventory_instance_id:
				restore_index = i
				break
	if _selected_inventory_cell_index < 0 or _selected_inventory_cell_index >= cells.size():
		_selected_inventory_cell_index = 0
	else:
		_selected_inventory_cell_index = restore_index
	for i in range(cells.size()):
		var cell := _build_inventory_cell(cells[i], i)
		_inventory_grid.add_child(cell)
		_inventory_buttons[i] = cell
	_select_inventory_cell(_selected_inventory_cell_index)


func _build_inventory_cell(cell_data: Dictionary, index: int) -> Control:
	var button := Button.new()
	button.custom_minimum_size = Vector2(72, 72)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 9)
	button.clip_text = true
	button.pressed.connect(_select_inventory_cell.bind(index))
	if bool(cell_data.get("occupied", false)):
		var display_name := str(cell_data.get("display_name", "Item"))
		var slot_id := str(cell_data.get("slot_id", ""))
		var level := int(cell_data.get("level", 0))
		var max_level := int(cell_data.get("max_level", 0))
		var is_equipped := bool(cell_data.get("is_equipped", false))
		var slot_label := _format_slot_name(slot_id)
		var equipped_tag := " [E]" if is_equipped else ""
		button.text = "%s%s\n%s\nLv %d/%d" % [
			_get_short_item_name(display_name),
			equipped_tag,
			slot_label,
			level,
			max_level,
		]
		if is_equipped:
			button.modulate = UIStateColors.positive_color()
	else:
		button.text = "+\nEmpty"
		button.modulate = Color(0.48, 0.52, 0.58, 1.0)
	return button


func _select_inventory_cell(index: int) -> void:
	var cells := _get_inventory_cell_data()
	if cells.is_empty():
		_update_inventory_detail({})
		return
	_selected_inventory_cell_index = clampi(index, 0, cells.size() - 1)
	var selected_cell: Dictionary = cells[_selected_inventory_cell_index]
	_selected_inventory_instance_id = str(selected_cell.get("instance_id", "")) if bool(selected_cell.get("occupied", false)) else ""
	for cell_index in _inventory_buttons:
		var button := _inventory_buttons[cell_index] as Button
		if button == null:
			continue
		var is_selected: bool = int(cell_index) == _selected_inventory_cell_index
		var data: Dictionary = cells[int(cell_index)]
		var is_occupied: bool = bool(data.get("occupied", false))
		var is_equipped_item: bool = bool(data.get("is_equipped", false))
		if is_selected and is_occupied and is_equipped_item:
			# Selected + equipped: bright white-green highlight
			button.modulate = Color(0.85, 1.0, 0.85, 1.0)
		elif is_selected and is_occupied:
			# Selected + unequipped: bright yellow-white highlight
			button.modulate = Color(1.0, 1.0, 0.75, 1.0)
		elif is_selected:
			# Selected + empty: slightly brighter gray
			button.modulate = Color(0.72, 0.76, 0.82, 1.0)
		elif is_occupied and is_equipped_item:
			# Unselected + equipped: green tint
			button.modulate = UIStateColors.positive_color()
		elif is_occupied:
			# Unselected + in inventory: neutral white
			button.modulate = Color.WHITE
		else:
			# Empty cell: muted gray
			button.modulate = Color(0.48, 0.52, 0.58, 1.0)
	_update_inventory_detail(selected_cell)


func _update_inventory_detail(cell_data: Dictionary) -> void:
	var is_occupied := bool(cell_data.get("occupied", false))
	var instance_id := str(cell_data.get("instance_id", ""))

	# Update equip button
	if _inventory_equip_button != null:
		if not is_occupied or instance_id.is_empty():
			_inventory_equip_button.text = "Equip"
			_inventory_equip_button.disabled = true
			_inventory_equip_button.modulate = UIStateColors.muted_color()
		elif _is_item_equipped(instance_id):
			_inventory_equip_button.text = "Equipped"
			_inventory_equip_button.disabled = true
			_inventory_equip_button.modulate = UIStateColors.muted_color()
		else:
			_inventory_equip_button.text = "Equip"
			_inventory_equip_button.disabled = false
			_inventory_equip_button.modulate = UIStateColors.positive_color()

	if _inventory_detail_label == null:
		return

	if not is_occupied or instance_id.is_empty():
		_inventory_detail_label.text = "[Empty Slot]\nNo item selected.\nFuture items will appear here."
		return

	# Gather data
	var item: Dictionary = {}
	if _meta_manager != null and _meta_manager.has_method("get_inventory_item"):
		item = _meta_manager.get_inventory_item(_selected_hero_id, instance_id)
	var tmpl := _get_item_template_for_instance(instance_id)
	var stat_info := _get_item_stat_info(instance_id)
	var slot_id := str(item.get("slot_id", str(cell_data.get("slot_id", ""))))
	var level := int(item.get("level", int(cell_data.get("level", 0))))
	var max_level := int(cell_data.get("max_level", int(tmpl.get("max_level", 0))))
	if max_level <= 0 and not tmpl.is_empty():
		max_level = int(tmpl.get("max_level", 10))
	var is_equipped := _is_item_equipped(instance_id)

	var display_name := _get_item_display_name(instance_id)
	var slot_display := _format_slot_name(slot_id)
	var status_str := "EQUIPPED" if is_equipped else "In Inventory"
	var stat_str := _format_stat_line(stat_info)
	var desc := str(tmpl.get("description", ""))

	var compare_str := ""
	if not slot_id.is_empty() and _meta_manager != null:
		compare_str = _format_compare_section(instance_id, slot_id)

	var lines := PackedStringArray()
	lines.append("=== %s ===" % display_name)
	lines.append("Slot: %s" % slot_display)
	lines.append("Level: %d / %d" % [level, max_level])
	lines.append("Status: %s" % status_str)
	if not stat_str.is_empty():
		lines.append("")
		lines.append(stat_str)
	if not desc.is_empty():
		lines.append("")
		lines.append(desc)
	if not compare_str.is_empty():
		lines.append("")
		lines.append(compare_str)
	_inventory_detail_label.text = "\n".join(lines)


func _get_short_item_name(display_name: String) -> String:
	var words := display_name.split(" ", false)
	if words.size() <= 1:
		return display_name.substr(0, 10)
	var initials := ""
	for word in words:
		if word.length() > 0:
			initials += word.substr(0, 1)
	return initials.to_upper()


# ─── Inventory detail helpers ─────────────────────────────────────────────────

func _is_item_equipped(instance_id: String) -> bool:
	if _meta_manager == null or instance_id.is_empty() or _selected_hero_id.is_empty():
		return false
	if not _meta_manager.has_method("get_equipped_items_for_hero"):
		return false
	var equipped: Dictionary = _meta_manager.get_equipped_items_for_hero(_selected_hero_id)
	for slot in equipped:
		if str(equipped[slot]) == instance_id:
			return true
	return false


func _get_item_template_for_instance(instance_id: String) -> Dictionary:
	if _meta_manager == null or instance_id.is_empty() or _selected_hero_id.is_empty():
		return {}
	if not _meta_manager.has_method("get_item_template_for_instance"):
		return {}
	return _meta_manager.get_item_template_for_instance(_selected_hero_id, instance_id)


func _get_item_stat_info(instance_id: String) -> Dictionary:
	if _meta_manager == null or instance_id.is_empty():
		return {}
	if not _meta_manager.has_method("get_item_stat_total"):
		return {}
	return _meta_manager.get_item_stat_total(_selected_hero_id, instance_id)


func _format_stat_line(stat_info: Dictionary) -> String:
	var stat_type := str(stat_info.get("stat_type", ""))
	var total := float(stat_info.get("total", 0.0))
	var per_level := float(stat_info.get("per_level", 0.0))
	var level := int(stat_info.get("level", 0))
	if stat_type.is_empty():
		return ""
	var stat_display := _format_stat_type_name(stat_type)
	if level <= 0:
		return "%s: +%.1f per level (unleveled)" % [stat_display, per_level]
	return "%s: +%.1f per level\nTotal: +%.1f %s" % [stat_display, per_level, total, stat_display]


func _format_stat_type_name(stat_type: String) -> String:
	match stat_type:
		"attack_damage": return "Attack Damage"
		"attack_speed": return "Attack Speed"
		"max_health": return "Max Health"
		"health_regen": return "Health Regen"
		"move_speed": return "Move Speed"
		"ability_cooldown": return "Cooldown Reduction"
		"ability_damage": return "Ability Damage"
		"shield_capacity": return "Shield Capacity"
		"xp_gain": return "XP Gain"
		"mark_damage": return "Mark Damage"
		"rage_gain": return "Rage Gain"
		"impact_damage": return "Impact Damage"
		"knockback_resist": return "Knockback Resist"
		"low_health_damage": return "Low-Health Damage"
		"support_damage": return "Support Damage"
		_: return stat_type.replace("_", " ").capitalize()


func _get_item_display_name(instance_id: String) -> String:
	var tmpl := _get_item_template_for_instance(instance_id)
	if not tmpl.is_empty():
		var n := str(tmpl.get("display_name", ""))
		if not n.is_empty():
			return n
		n = str(tmpl.get("name", ""))
		if not n.is_empty():
			return n
	return instance_id.replace("_", " ").capitalize()


func _format_compare_section(selected_instance_id: String, slot_id: String) -> String:
	if _meta_manager == null:
		return ""
	if not _meta_manager.has_method("get_equipped_instance_id_for_slot"):
		return ""
	var equipped_instance_id := str(_meta_manager.get_equipped_instance_id_for_slot(_selected_hero_id, slot_id))
	if equipped_instance_id.is_empty():
		return "No item currently equipped in this slot."
	if equipped_instance_id == selected_instance_id:
		return "This item is currently equipped."
	var sel_stat := _get_item_stat_info(selected_instance_id)
	var eq_stat := _get_item_stat_info(equipped_instance_id)
	var sel_name := _get_item_display_name(selected_instance_id)
	var eq_name := _get_item_display_name(equipped_instance_id)
	var sel_level := int(sel_stat.get("level", 0))
	var eq_level := int(eq_stat.get("level", 0))
	var sel_total := float(sel_stat.get("total", 0.0))
	var eq_total := float(eq_stat.get("total", 0.0))
	var stat_type := str(sel_stat.get("stat_type", str(eq_stat.get("stat_type", ""))))
	var stat_display := _format_stat_type_name(stat_type)
	var delta := sel_total - eq_total
	var delta_str := ""
	if abs(delta) < 0.001:
		delta_str = "Delta: 0 (equal)"
	elif delta > 0.0:
		delta_str = "Delta: +%.1f (better)" % delta
	else:
		delta_str = "Delta: %.1f (worse)" % delta
	return "--- Compare ---\nEquipped: %s Lv %d  %s: +%.1f\nSelected: %s Lv %d  %s: +%.1f\n%s" % [
		eq_name, eq_level, stat_display, eq_total,
		sel_name, sel_level, stat_display, sel_total,
		delta_str,
	]


func _get_selected_hero_data() -> Dictionary:
	for hero in _heroes:
		if str(hero.get("id", "")) == _selected_hero_id:
			return hero
	if _hero_data_provider != null and _hero_data_provider.has_method("get_hero"):
		var d: Dictionary = _hero_data_provider.get_hero(_selected_hero_id)
		if not d.is_empty():
			return d
	return {}


func _update_equipment_slots() -> void:
	var defs_by_slot := _get_equipment_definitions_by_slot()
	# Get currently equipped instance per slot for name/level display
	var equipped_instances: Dictionary = {}
	if _meta_manager != null and _meta_manager.has_method("get_equipped_items_for_hero"):
		equipped_instances = _meta_manager.get_equipped_items_for_hero(_selected_hero_id)

	for slot_id in _equipment_slot_rows:
		var row: Dictionary = _equipment_slot_rows.get(slot_id, {})
		var def: Dictionary = defs_by_slot.get(slot_id, {})
		var slot_name_lbl := row.get("slot_name") as Label
		var display_name_lbl := row.get("display_name") as Label
		var level_lbl := row.get("level") as Label
		var bonus_lbl := row.get("bonus") as Label
		var button := row.get("button") as Button

		var slot_name := _format_slot_name(str(slot_id))
		var display_name := "Equipment"
		var level_text := "Level 0 / 0"
		var bonus_text := "No equipment data"
		var equipment_id := ""
		var level := 0
		var max_level := 0
		var cost := 0
		var can_buy := false

		# Resolve display from equipped inventory item if available
		var equipped_instance_id := str(equipped_instances.get(slot_id, ""))
		var equipped_item: Dictionary = {}
		if not equipped_instance_id.is_empty() and _meta_manager != null and _meta_manager.has_method("get_inventory_item"):
			equipped_item = _meta_manager.get_inventory_item(_selected_hero_id, equipped_instance_id)

		if not equipped_item.is_empty():
			var template_id := str(equipped_item.get("template_id", ""))
			var item_def := _resolve_item_template(template_id)
			display_name = str(equipped_item.get("display_name", str(item_def.get("display_name", display_name)))) if equipped_item.has("display_name") else str(item_def.get("display_name", display_name))
			display_name = str(item_def.get("display_name", display_name)) if not item_def.is_empty() else display_name
			level = int(equipped_item.get("level", 0))
			max_level = int(item_def.get("max_level", 10)) if not item_def.is_empty() else 10
			# For upgrade cost/availability, still use the primary def with matching equipment_id
			if not def.is_empty():
				equipment_id = str(def.get("equipment_id", ""))
				slot_name = str(def.get("slot_name", slot_name))
				cost = _get_equipment_cost(equipment_id)
				can_buy = _can_buy_equipment(equipment_id)
			level_text = "Level %d / %d" % [level, max_level]
			var bonus_def := item_def if not item_def.is_empty() else def
			if not bonus_def.is_empty():
				bonus_text = "%s\nCurrent: %s\nNext: %s" % [
					_format_equipment_bonus(bonus_def),
					_format_equipment_total_bonus(bonus_def, level),
					_format_equipment_total_bonus(bonus_def, level + 1) if level < max_level else "MAX",
				]
		elif not def.is_empty():
			slot_name = str(def.get("slot_name", slot_name))
			display_name = str(def.get("display_name", display_name))
			equipment_id = str(def.get("equipment_id", ""))
			level = _get_equipment_level(equipment_id)
			max_level = int(def.get("max_level", 0))
			cost = _get_equipment_cost(equipment_id)
			can_buy = _can_buy_equipment(equipment_id)
			level_text = "Level %d / %d" % [level, max_level]
			bonus_text = "%s\nCurrent: %s\nNext: %s" % [
				_format_equipment_bonus(def),
				_format_equipment_total_bonus(def, level),
				_format_equipment_total_bonus(def, level + 1) if level < max_level else "MAX",
			]

		if slot_name_lbl != null:
			slot_name_lbl.text = slot_name
		if display_name_lbl != null:
			display_name_lbl.text = display_name
		if level_lbl != null:
			level_lbl.text = level_text
		if bonus_lbl != null:
			bonus_lbl.text = bonus_text
		if button != null:
			if def.is_empty() and equipped_item.is_empty():
				button.text = "Unavailable"
				button.disabled = true
				button.modulate = UIStateColors.muted_color()
			elif level >= max_level:
				button.text = "MAX"
				button.disabled = true
				button.modulate = UIStateColors.muted_color()
			elif can_buy:
				button.text = "Upgrade %d" % cost
				button.disabled = false
				button.modulate = UIStateColors.positive_color()
			else:
				button.text = "Need %d" % cost
				button.disabled = true
				button.modulate = UIStateColors.muted_color()


func _get_equipment_definitions_by_slot() -> Dictionary:
	var result := {}
	if _meta_manager == null or not _meta_manager.has_method("get_equipment_definitions"):
		return result
	var defs: Array = _meta_manager.get_equipment_definitions(_selected_hero_id)
	for def in defs:
		if not def is Dictionary:
			continue
		var slot_id := str(def.get("slot_id", ""))
		if not slot_id.is_empty():
			result[slot_id] = def
	return result


func _get_equipment_definition(equipment_id: String) -> Dictionary:
	if equipment_id.is_empty():
		return {}
	if _meta_manager != null and _meta_manager.has_method("get_equipment_definition"):
		return _meta_manager.get_equipment_definition(_selected_hero_id, equipment_id)
	for def in _get_equipment_definitions_by_slot().values():
		if str(def.get("equipment_id", "")) == equipment_id:
			return def
	return {}


func _get_equipment_level(equipment_id: String) -> int:
	if equipment_id.is_empty():
		return 0
	if _meta_manager != null and _meta_manager.has_method("get_equipment_level"):
		return int(_meta_manager.get_equipment_level(_selected_hero_id, equipment_id))
	return 0


func _get_equipment_cost(equipment_id: String) -> int:
	if equipment_id.is_empty():
		return 0
	if _meta_manager != null and _meta_manager.has_method("get_equipment_upgrade_cost"):
		return int(_meta_manager.get_equipment_upgrade_cost(_selected_hero_id, equipment_id))
	return 0


func _can_buy_equipment(equipment_id: String) -> bool:
	if equipment_id.is_empty():
		return false
	if _meta_manager != null and _meta_manager.has_method("can_purchase_equipment_upgrade"):
		return bool(_meta_manager.can_purchase_equipment_upgrade(_selected_hero_id, equipment_id))
	return false


func _format_equipment_bonus(def: Dictionary) -> String:
	var bonus_type := str(def.get("stat_bonus_type", ""))
	var value = def.get("stat_bonus_per_level", 0)
	var label := _format_bonus_type(bonus_type)
	if value is float and abs(float(value)) < 1.0:
		return "+%d%% %s / level" % [int(round(float(value) * 100.0)), label]
	return "+%s %s / level" % [str(value), label]


func _format_equipment_total_bonus(def: Dictionary, level: int) -> String:
	var bonus_type := str(def.get("stat_bonus_type", ""))
	var value := float(def.get("stat_bonus_per_level", 0.0)) * float(level)
	var label := _format_bonus_type(bonus_type)
	if abs(value) < 1.0 and not is_zero_approx(value):
		return "+%d%% %s" % [int(round(value * 100.0)), label]
	return "+%s %s" % [_format_number(value), label]


func _format_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundi(value)))
	return "%.2f" % value


func _format_bonus_type(bonus_type: String) -> String:
	match bonus_type:
		"ability_damage":
			return "ability damage"
		"max_health":
			return "max HP"
		"xp_gain":
			return "XP gain"
		"attack_damage":
			return "attack damage"
		"move_speed":
			return "move speed"
		"shield_capacity":
			return "shield capacity"
		"ability_cooldown":
			return "ability cooldown"
		"mark_damage":
			return "marked damage"
		"support_damage":
			return "support damage"
		"rage_gain":
			return "Rage gain"
		"impact_damage":
			return "impact damage"
		"knockback_resist":
			return "knockback resist"
		"low_health_damage":
			return "low-health damage"
		_:
			return bonus_type.replace("_", " ")


func _format_slot_name(slot_id: String) -> String:
	match slot_id:
		"core":
			return "Core"
		"suit":
			return "Suit"
		"emblem":
			return "Emblem"
		"gauntlets":
			return "Gauntlets"
		"boots":
			return "Boots"
		"artifact":
			return "Artifact"
		_:
			return slot_id.capitalize()


# ─── Training rows ────────────────────────────────────────────────────────────

func _rebuild_rows_if_needed() -> void:
	if _meta_manager == null or _list_vbox == null:
		return
	var defs: Array[Dictionary] = _meta_manager.get_meta_upgrade_definitions()
	if _rows.size() == defs.size():
		return

	for child in _list_vbox.get_children():
		child.queue_free()
	_rows.clear()

	for def in defs:
		var upgrade_id := str(def.get("id", ""))
		var row := _build_row(upgrade_id, def)
		_list_vbox.add_child(row)


func _build_row(upgrade_id: String, def: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)
	hbox.add_child(info)

	var title_lbl := Label.new()
	title_lbl.text = str(def.get("title", ""))
	title_lbl.add_theme_font_size_override("font_size", 14)
	info.add_child(title_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = str(def.get("description", ""))
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.modulate = Color(0.8, 0.8, 0.8, 1.0)
	info.add_child(desc_lbl)

	var level_lbl := Label.new()
	level_lbl.add_theme_font_size_override("font_size", 11)
	info.add_child(level_lbl)

	var buy_btn := Button.new()
	buy_btn.custom_minimum_size = Vector2(110, 44)
	buy_btn.pressed.connect(_on_buy_pressed.bind(upgrade_id))
	hbox.add_child(buy_btn)

	var row_data := {
		"id": upgrade_id,
		"max_level": int(def.get("max_level", 1)),
		"level_lbl": level_lbl,
		"buy_btn": buy_btn,
		"panel": panel,
	}
	_rows.append(row_data)
	return panel


func _update_rows() -> void:
	if _meta_manager == null:
		return
	for row in _rows:
		var upgrade_id := str(row.get("id", ""))
		var max_level := int(row.get("max_level", 1))
		var level: int = _meta_manager.get_training_level(_selected_hero_id, upgrade_id) if _meta_manager.has_method("get_training_level") else _meta_manager.get_meta_upgrade_level(upgrade_id)
		var cost: int = _meta_manager.get_training_upgrade_cost(_selected_hero_id, upgrade_id) if _meta_manager.has_method("get_training_upgrade_cost") else _meta_manager.get_meta_upgrade_cost(upgrade_id)
		var can_buy: bool = _meta_manager.can_purchase_training_upgrade(_selected_hero_id, upgrade_id) if _meta_manager.has_method("can_purchase_training_upgrade") else _meta_manager.can_buy_meta_upgrade(upgrade_id)

		var level_lbl := row.get("level_lbl") as Label
		if level_lbl != null:
			level_lbl.text = "Level %d / %d" % [level, max_level]

		var buy_btn := row.get("buy_btn") as Button
		if buy_btn != null:
			if level >= max_level:
				buy_btn.text = "MAX"
				buy_btn.disabled = true
				buy_btn.modulate = UIStateColors.muted_color()
			elif can_buy:
				buy_btn.text = "Buy  %d" % cost
				buy_btn.disabled = false
				buy_btn.modulate = UIStateColors.positive_color()
			else:
				buy_btn.text = "Buy  %d" % cost
				buy_btn.disabled = true
				buy_btn.modulate = UIStateColors.muted_color()


func _update_goals_label() -> void:
	if _goals_label == null:
		return
	if _meta_manager == null or not _meta_manager.has_method("get_goal_progress"):
		_goals_label.text = ""
		return
	var goals: Array = _meta_manager.get_goal_progress()
	var completed := 0
	var next_lines: PackedStringArray = []
	for goal in goals:
		if bool(goal.get("completed", false)):
			completed += 1
		elif next_lines.size() < 3:
			next_lines.append("%s %d/%d" % [
				str(goal.get("title", goal.get("id", ""))),
				int(goal.get("progress_current", 0)),
				int(goal.get("progress_target", 1)),
			])
	var text := "Goals: %d / %d complete" % [completed, goals.size()]
	if not next_lines.is_empty():
		text += "   Next: %s" % " | ".join(next_lines)
	_goals_label.text = text


# ─── Signal handlers ──────────────────────────────────────────────────────────

func _set_active_tab(tab_id: String) -> void:
	if tab_id != "equipment" and tab_id != "training":
		return
	_active_tab = tab_id
	_update_tab_state()


func _update_tab_state() -> void:
	if _equipment_content != null:
		_equipment_content.visible = _active_tab == "equipment"
	if _training_content != null:
		_training_content.visible = _active_tab == "training"
	if _equipment_tab_button != null:
		var equipment_selected := _active_tab == "equipment"
		_equipment_tab_button.disabled = equipment_selected
		_equipment_tab_button.modulate = UIStateColors.positive_color() if equipment_selected else Color.WHITE
	if _training_tab_button != null:
		var training_selected := _active_tab == "training"
		_training_tab_button.disabled = training_selected
		_training_tab_button.modulate = UIStateColors.positive_color() if training_selected else Color.WHITE


func _on_buy_pressed(upgrade_id: String) -> void:
	if _selected_hero_id.is_empty():
		push_warning("MetaUpgradeShop: cannot buy training upgrade without selected hero.")
		return
	buy_requested.emit(_selected_hero_id, upgrade_id)


func _on_equipment_buy_pressed(slot_id: String) -> void:
	if _selected_hero_id.is_empty():
		push_warning("MetaUpgradeShop: cannot buy equipment without selected hero.")
		return
	var defs_by_slot := _get_equipment_definitions_by_slot()
	var def: Dictionary = defs_by_slot.get(slot_id, {})
	var equipment_id := str(def.get("equipment_id", ""))
	if equipment_id.is_empty():
		push_warning("MetaUpgradeShop: cannot buy missing equipment slot %s." % slot_id)
		return
	equipment_buy_requested.emit(_selected_hero_id, equipment_id)


func _on_back_pressed() -> void:
	back_requested.emit()


func _on_currency_changed(_amount: int) -> void:
	if visible:
		refresh()


func _on_meta_upgrade_changed(upgrade_id: String, _level: int) -> void:
	if visible:
		refresh()
		_flash_row(upgrade_id)


func _on_equipment_upgrade_changed(hero_id: String, equipment_id: String, _level: int) -> void:
	if visible:
		refresh()
		if hero_id == _selected_hero_id:
			_flash_equipment_slot(equipment_id)


# ─── Hero selector ────────────────────────────────────────────────────────────

func _reload_heroes() -> void:
	_heroes.clear()
	if _hero_data_provider != null and _hero_data_provider.has_method("get_all_heroes"):
		_heroes = _hero_data_provider.get_all_heroes()
	if _heroes.is_empty():
		_heroes = [
			{"id": "guardian", "display_name": "Guardian"},
			{"id": "blaster", "display_name": "Blaster"},
			{"id": "vanguard", "display_name": "Vanguard"},
		]
	_rebuild_hero_selector()


func _rebuild_hero_selector() -> void:
	if _hero_selector == null:
		return
	for child in _hero_selector.get_children():
		child.queue_free()
	_hero_buttons.clear()
	for hero in _heroes:
		var hero_id := str(hero.get("id", ""))
		if hero_id.is_empty():
			continue
		var button := Button.new()
		button.text = str(hero.get("display_name", hero_id.capitalize()))
		button.custom_minimum_size = Vector2(150, 42)
		button.pressed.connect(_on_hero_button_pressed.bind(hero_id))
		_hero_selector.add_child(button)
		_hero_buttons[hero_id] = button
	_update_hero_buttons()


func _update_hero_buttons() -> void:
	for hero_id in _hero_buttons:
		var button := _hero_buttons[hero_id] as Button
		if button == null:
			continue
		var selected: bool = hero_id == _selected_hero_id
		button.disabled = selected
		button.modulate = UIStateColors.positive_color() if selected else Color.WHITE


func _on_hero_button_pressed(hero_id: String) -> void:
	set_selected_hero(hero_id)


# ─── Helpers ──────────────────────────────────────────────────────────────────

func _resolve_hero_id(hero_id: String) -> String:
	if _has_hero(hero_id):
		return hero_id
	if _hero_data_provider != null and _hero_data_provider.has_method("get_default_hero"):
		var default_hero: Dictionary = _hero_data_provider.get_default_hero()
		var default_id := str(default_hero.get("id", ""))
		if _has_hero(default_id):
			return default_id
	return str(_heroes[0].get("id", "guardian")) if not _heroes.is_empty() else "guardian"


func _has_hero(hero_id: String) -> bool:
	if hero_id.is_empty():
		return false
	for hero in _heroes:
		if str(hero.get("id", "")) == hero_id:
			return true
	return false


func _get_selected_hero_display_name() -> String:
	for hero in _heroes:
		if str(hero.get("id", "")) == _selected_hero_id:
			return str(hero.get("display_name", _selected_hero_id.capitalize()))
	return _selected_hero_id.capitalize()


func _get_hero_ids() -> Array[String]:
	var ids: Array[String] = []
	for hero in _heroes:
		var hero_id := str(hero.get("id", ""))
		if not hero_id.is_empty():
			ids.append(hero_id)
	return ids


func _flash_row(upgrade_id: String) -> void:
	for row in _rows:
		if str(row.get("id", "")) != upgrade_id:
			continue
		var panel := row.get("panel") as CanvasItem
		if panel == null or not is_instance_valid(panel):
			return
		var tween := panel.create_tween()
		tween.tween_property(panel, "modulate", Color(0.6, 1.0, 0.6, 1.0), 0.0)
		tween.tween_property(panel, "modulate", Color.WHITE, 0.35)
		return


func _flash_equipment_slot(equipment_id: String) -> void:
	var defs_by_slot := _get_equipment_definitions_by_slot()
	for slot_id in defs_by_slot:
		var def: Dictionary = defs_by_slot.get(slot_id, {})
		if str(def.get("equipment_id", "")) != equipment_id:
			continue
		var row: Dictionary = _equipment_slot_rows.get(slot_id, {})
		var panel := row.get("panel") as CanvasItem
		if panel == null or not is_instance_valid(panel):
			return
		var tween := panel.create_tween()
		tween.tween_property(panel, "modulate", Color(0.6, 1.0, 0.6, 1.0), 0.0)
		tween.tween_property(panel, "modulate", Color.WHITE, 0.35)
		return


func _on_inventory_equip_pressed() -> void:
	if _selected_inventory_instance_id.is_empty() or _selected_hero_id.is_empty():
		return
	if _meta_manager == null or not _meta_manager.has_method("get_inventory_item"):
		return
	var item: Dictionary = _meta_manager.get_inventory_item(_selected_hero_id, _selected_inventory_instance_id)
	if item.is_empty():
		return
	var slot_id := str(item.get("slot_id", ""))
	if slot_id.is_empty():
		return
	if _meta_manager.has_method("equip_inventory_item"):
		_meta_manager.equip_inventory_item(_selected_hero_id, _selected_inventory_instance_id, slot_id)


func _on_equipment_slot_panel_clicked(event: InputEvent, slot_id: String) -> void:
	if not event is InputEventMouseButton:
		return
	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return
	_select_inventory_item_for_slot(slot_id)


func _select_inventory_item_for_slot(slot_id: String) -> void:
	if _meta_manager == null or not _meta_manager.has_method("get_equipped_instance_id_for_slot"):
		return
	var equipped_instance_id := str(_meta_manager.get_equipped_instance_id_for_slot(_selected_hero_id, slot_id))
	if equipped_instance_id.is_empty():
		return
	var cells := _get_inventory_cell_data()
	for i in range(cells.size()):
		var c: Dictionary = cells[i]
		if bool(c.get("occupied", false)) and str(c.get("instance_id", "")) == equipped_instance_id:
			_select_inventory_cell(i)
			return


func _on_inventory_changed(hero_id: String) -> void:
	if visible and hero_id == _selected_hero_id:
		_refresh_equipment_panel()
		_refresh_inventory_shell()


func _on_equipment_slot_changed(hero_id: String, _slot_id: String, _instance_id: String) -> void:
	if visible and hero_id == _selected_hero_id:
		_update_equipment_slots()
		_refresh_inventory_shell()
