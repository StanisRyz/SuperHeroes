extends CanvasLayer

signal back_requested
signal buy_requested(hero_id: String, upgrade_id: String)
signal equipment_buy_requested(hero_id: String, equipment_id: String)

const UIStateColors = preload("res://scenes/ui/UIStateColors.gd")
const EquipmentFormat = preload("res://scenes/equipment/EquipmentFormat.gd")

var _meta_manager: Node
var _hero_data_provider: Node
var _selected_hero_id: String = ""
var _active_tab: String = "equipment"
var _selected_inventory_cell_index: int = 0
var _heroes: Array[Dictionary] = []
var _currency_label: Label
var _goals_label: Label
var _back_button: Button
var _equipment_tab_button: Button
var _training_tab_button: Button
var _equipment_content: Control
var _training_content: Control
var _list_vbox: VBoxContainer

var _rows: Array[Dictionary] = []
var _hero_dropdown: OptionButton

# Starter pack popup
var _starter_pack_popup: PopupPanel = null
var _starter_pack_items_label: Label = null

# Equipped slot popup
var _slot_popup: PopupPanel
var _slot_popup_slot_id: String = ""
var _slot_popup_title_label: Label
var _slot_popup_detail_label: Label
var _slot_popup_unequip_button: Button
var _slot_popup_close_button: Button

# Equipment panel references
var _equip_hero_name_label: Label
var _equip_hero_subtitle_label: Label
var _equip_hero_swatch: ColorRect
var _equip_hero_status_label: Label
var _equipment_slot_rows: Dictionary = {}
var _char_holder_panel: PanelContainer
var _char_holder_name: Label
var _char_holder_subtitle: Label
var _inventory_grid: GridContainer
var _inventory_detail_label: Label
var _inventory_buttons: Dictionary = {}
var _inventory_equip_button: Button
var _inventory_upgrade_button: Button
var _inventory_lock_button: Button
var _inventory_favorite_button: Button
var _inventory_dismantle_button: Button
var _inventory_capacity_label: Label
var _selected_inventory_instance_id: String = ""
var _training_hero_label: Label
var _gold_label: Label
var _materials_label: Label
var _last_upgrade_message: String = ""

# Item action popup
var _item_action_popup: PopupPanel = null
var _item_action_title_label: Label = null

var _inventory_slot_filter: String = "all"
var _inventory_state_filter: String = "all"
var _inventory_sort_mode: String = "default"

# Dismantle confirmation popup
var _dismantle_confirm_popup: ConfirmationDialog = null
var _dismantle_confirm_instance_id: String = ""

# Loadout summary popup
var _loadout_summary_button: Button = null
var _loadout_summary_popup: PopupPanel = null
var _loadout_summary_label: Label = null


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
	if _meta_manager.has_signal("gold_changed") and not _meta_manager.gold_changed.is_connected(_on_gold_changed):
		_meta_manager.gold_changed.connect(_on_gold_changed)
	if _meta_manager.has_signal("equipment_materials_changed") and not _meta_manager.equipment_materials_changed.is_connected(_on_equipment_materials_changed):
		_meta_manager.equipment_materials_changed.connect(_on_equipment_materials_changed)
	if _meta_manager.has_signal("meta_upgrade_changed") and not _meta_manager.meta_upgrade_changed.is_connected(_on_meta_upgrade_changed):
		_meta_manager.meta_upgrade_changed.connect(_on_meta_upgrade_changed)
	if _meta_manager.has_signal("equipment_upgrade_changed") and not _meta_manager.equipment_upgrade_changed.is_connected(_on_equipment_upgrade_changed):
		_meta_manager.equipment_upgrade_changed.connect(_on_equipment_upgrade_changed)
	if _meta_manager.has_signal("inventory_changed") and not _meta_manager.inventory_changed.is_connected(_on_inventory_changed):
		_meta_manager.inventory_changed.connect(_on_inventory_changed)
	if _meta_manager.has_signal("equipment_changed") and not _meta_manager.equipment_changed.is_connected(_on_equipment_slot_changed):
		_meta_manager.equipment_changed.connect(_on_equipment_slot_changed)
	if _meta_manager.has_signal("inventory_item_upgraded") and not _meta_manager.inventory_item_upgraded.is_connected(_on_inventory_item_upgraded):
		_meta_manager.inventory_item_upgraded.connect(_on_inventory_item_upgraded)
	if _meta_manager.has_method("ensure_training_data_for_all_heroes"):
		_meta_manager.ensure_training_data_for_all_heroes(_get_hero_ids())
	if _meta_manager.has_method("ensure_equipment_data_for_all_heroes"):
		_meta_manager.ensure_equipment_data_for_all_heroes(_get_hero_ids())


func open(hero_id: String = "") -> void:
	set_selected_hero(hero_id)
	_active_tab = "equipment"
	refresh()
	_rebuild_hero_dropdown()
	show()
	if _item_action_popup != null:
		_item_action_popup.hide()
	if _equipment_tab_button != null:
		_equipment_tab_button.grab_focus()
	_show_starter_pack_popup_if_needed()


func close() -> void:
	hide()


func refresh() -> void:
	if _meta_manager == null:
		return
	if _selected_hero_id.is_empty():
		set_selected_hero("")
	if _currency_label != null:
		_currency_label.text = "Currency: %d" % _meta_manager.get_currency()
	if _gold_label != null:
		var gold := int(_meta_manager.get_gold()) if _meta_manager.has_method("get_gold") else 0
		_gold_label.text = "Gold: %d" % gold
	_update_materials_label()
	_update_goals_label()
	_rebuild_rows_if_needed()
	_update_rows()
	_refresh_equipment_panel()
	_refresh_inventory_shell()
	_update_tab_state()
	_rebuild_hero_dropdown()


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

	var hero_label := Label.new()
	hero_label.text = "  Hero:"
	hero_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hero_label.add_theme_font_size_override("font_size", 13)
	nav.add_child(hero_label)

	_hero_dropdown = OptionButton.new()
	_hero_dropdown.custom_minimum_size = Vector2(180, 42)
	_hero_dropdown.add_theme_font_size_override("font_size", 13)
	_hero_dropdown.item_selected.connect(_on_hero_dropdown_changed)
	nav.add_child(_hero_dropdown)

	var nav_spacer := Control.new()
	nav_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(nav_spacer)

	_currency_label = Label.new()
	_currency_label.text = "Currency: 0"
	_currency_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_currency_label.add_theme_font_size_override("font_size", 14)
	_currency_label.modulate = Color(0.88, 0.92, 0.96, 1.0)
	nav.add_child(_currency_label)

	_gold_label = Label.new()
	_gold_label.text = "Gold: 0"
	_gold_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_gold_label.add_theme_font_size_override("font_size", 14)
	_gold_label.modulate = Color(1.0, 0.82, 0.28, 1.0)
	nav.add_child(_gold_label)

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

	_materials_label = Label.new()
	_materials_label.text = "Materials: none"
	_materials_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_materials_label.add_theme_font_size_override("font_size", 10)
	_materials_label.modulate = Color(0.66, 0.78, 0.86, 1.0)
	main_vbox.add_child(_materials_label)

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

	_build_starter_pack_popup()
	_build_slot_popup()
	_build_dismantle_confirm_popup()
	_build_item_action_popup()
	_build_loadout_summary_popup()
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
	# Root is a plain HBoxContainer — fills height via SIZE_EXPAND_FILL set by caller.
	var content_row := HBoxContainer.new()
	content_row.add_theme_constant_override("separation", 12)
	content_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# ── Equipped Gear panel ───────────────────────────────────────────────────
	var equipped_panel := PanelContainer.new()
	equipped_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equipped_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_row.add_child(equipped_panel)

	var equipped_vbox := VBoxContainer.new()
	equipped_vbox.add_theme_constant_override("separation", 8)
	equipped_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equipped_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	equipped_panel.add_child(equipped_vbox)

	var eq_header := HBoxContainer.new()
	eq_header.add_theme_constant_override("separation", 8)
	equipped_vbox.add_child(eq_header)

	var section_title := Label.new()
	section_title.text = "Equipped Gear"
	section_title.add_theme_font_size_override("font_size", 16)
	section_title.modulate = Color(0.7, 0.85, 1.0, 1.0)
	section_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	eq_header.add_child(section_title)

	_loadout_summary_button = Button.new()
	_loadout_summary_button.text = "Loadout"
	_loadout_summary_button.custom_minimum_size = Vector2(90, 32)
	_loadout_summary_button.add_theme_font_size_override("font_size", 12)
	_loadout_summary_button.pressed.connect(_show_loadout_summary_popup)
	eq_header.add_child(_loadout_summary_button)

	# ── slot columns + central character holder ───────────────────────────────
	var slot_hbox := HBoxContainer.new()
	slot_hbox.add_theme_constant_override("separation", 8)
	slot_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	equipped_vbox.add_child(slot_hbox)

	var left_col := VBoxContainer.new()
	left_col.add_theme_constant_override("separation", 6)
	left_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	slot_hbox.add_child(left_col)
	left_col.add_child(_build_equipment_slot("core", "Core"))
	left_col.add_child(_build_equipment_slot("suit", "Suit"))
	left_col.add_child(_build_equipment_slot("emblem", "Emblem"))

	# Central character image holder
	_char_holder_panel = PanelContainer.new()
	_char_holder_panel.custom_minimum_size = Vector2(160, 0)
	_char_holder_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_char_holder_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	slot_hbox.add_child(_char_holder_panel)

	var holder_vbox := VBoxContainer.new()
	holder_vbox.add_theme_constant_override("separation", 6)
	holder_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_char_holder_panel.add_child(holder_vbox)

	_equip_hero_swatch = ColorRect.new()
	_equip_hero_swatch.custom_minimum_size = Vector2(0, 6)
	_equip_hero_swatch.color = Color(0.5, 0.5, 0.5, 1.0)
	holder_vbox.add_child(_equip_hero_swatch)

	var holder_spacer_top := Control.new()
	holder_spacer_top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	holder_vbox.add_child(holder_spacer_top)

	var char_img_lbl := Label.new()
	char_img_lbl.text = "[ Character\n  Image ]"
	char_img_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	char_img_lbl.add_theme_font_size_override("font_size", 11)
	char_img_lbl.modulate = Color(0.4, 0.45, 0.55, 1.0)
	holder_vbox.add_child(char_img_lbl)

	_char_holder_name = Label.new()
	_char_holder_name.text = "—"
	_char_holder_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_char_holder_name.add_theme_font_size_override("font_size", 14)
	holder_vbox.add_child(_char_holder_name)

	_char_holder_subtitle = Label.new()
	_char_holder_subtitle.text = ""
	_char_holder_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_char_holder_subtitle.add_theme_font_size_override("font_size", 10)
	_char_holder_subtitle.modulate = Color(0.7, 0.78, 0.9, 1.0)
	_char_holder_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	holder_vbox.add_child(_char_holder_subtitle)

	_equip_hero_status_label = Label.new()
	_equip_hero_status_label.text = ""
	_equip_hero_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_equip_hero_status_label.add_theme_font_size_override("font_size", 10)
	_equip_hero_status_label.modulate = Color(0.6, 0.9, 0.6, 1.0)
	holder_vbox.add_child(_equip_hero_status_label)

	var holder_spacer_bot := Control.new()
	holder_spacer_bot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	holder_vbox.add_child(holder_spacer_bot)

	var right_col := VBoxContainer.new()
	right_col.add_theme_constant_override("separation", 6)
	right_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	slot_hbox.add_child(right_col)
	right_col.add_child(_build_equipment_slot("gauntlets", "Gauntlets"))
	right_col.add_child(_build_equipment_slot("boots", "Boots"))
	right_col.add_child(_build_equipment_slot("artifact", "Artifact"))

	var note := Label.new()
	note.text = "Click a slot to view details. Select inventory item then Equip."
	note.add_theme_font_size_override("font_size", 10)
	note.modulate = Color(0.55, 0.6, 0.65, 1.0)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	equipped_vbox.add_child(note)

	# ── Inventory panel ───────────────────────────────────────────────────────
	var inventory_panel := _build_inventory_panel()
	inventory_panel.custom_minimum_size = Vector2(410, 0)
	inventory_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	inventory_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_row.add_child(inventory_panel)

	return content_row


func _build_inventory_panel() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	# ── header: title + capacity only ─────────────────────────────────────────
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)

	var title := Label.new()
	title.text = "Inventory"
	title.add_theme_font_size_override("font_size", 15)
	header.add_child(title)

	_inventory_capacity_label = Label.new()
	_inventory_capacity_label.text = "(0 / 60)"
	_inventory_capacity_label.add_theme_font_size_override("font_size", 12)
	_inventory_capacity_label.modulate = Color(0.72, 0.78, 0.88, 1.0)
	header.add_child(_inventory_capacity_label)

	var header_hint := Label.new()
	header_hint.text = "  Click item to manage"
	header_hint.add_theme_font_size_override("font_size", 10)
	header_hint.modulate = Color(0.5, 0.55, 0.62, 1.0)
	header_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_hint)

	# ── body: filters + grid (fills remaining space) ──────────────────────────
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(body)

	var filter_row := HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 6)
	body.add_child(filter_row)

	var slot_filter_label := Label.new()
	slot_filter_label.text = "Slot:"
	slot_filter_label.add_theme_font_size_override("font_size", 11)
	filter_row.add_child(slot_filter_label)

	var slot_option := OptionButton.new()
	slot_option.custom_minimum_size = Vector2(90, 28)
	slot_option.add_theme_font_size_override("font_size", 11)
	for slot_entry in [["All", "all"], ["Core", "core"], ["Suit", "suit"], ["Emblem", "emblem"], ["Gauntlets", "gauntlets"], ["Boots", "boots"], ["Artifact", "artifact"]]:
		slot_option.add_item(slot_entry[0])
	slot_option.item_selected.connect(_on_inventory_slot_filter_changed)
	filter_row.add_child(slot_option)

	var state_filter_label := Label.new()
	state_filter_label.text = "  State:"
	state_filter_label.add_theme_font_size_override("font_size", 11)
	filter_row.add_child(state_filter_label)

	var state_option := OptionButton.new()
	state_option.custom_minimum_size = Vector2(100, 28)
	state_option.add_theme_font_size_override("font_size", 11)
	for state_entry in [["All", "all"], ["Equipped", "equipped"], ["Unequipped", "unequipped"]]:
		state_option.add_item(state_entry[0])
	state_option.item_selected.connect(_on_inventory_state_filter_changed)
	filter_row.add_child(state_option)

	var sort_label := Label.new()
	sort_label.text = "  Sort:"
	sort_label.add_theme_font_size_override("font_size", 11)
	filter_row.add_child(sort_label)

	var sort_option := OptionButton.new()
	sort_option.custom_minimum_size = Vector2(100, 28)
	sort_option.add_theme_font_size_override("font_size", 11)
	for sort_entry in [["Default", "default"], ["Slot", "slot"], ["Lvl High", "level_high"], ["Lvl Low", "level_low"], ["Name", "name"], ["Rar High", "rarity_high"], ["Rar Low", "rarity_low"], ["Fav First", "favorite_first"], ["Newest", "newest"]]:
		sort_option.add_item(sort_entry[0])
	sort_option.item_selected.connect(_on_inventory_sort_mode_changed)
	filter_row.add_child(sort_option)

	var grid_scroll := _build_inventory_grid()
	grid_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(grid_scroll)

	return panel


func _build_equipment_slot(slot_id: String, slot_name: String) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(110, 110)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.text = "%s\n+\nEmpty" % slot_name
	btn.add_theme_font_size_override("font_size", 11)
	btn.pressed.connect(_on_equipped_slot_pressed.bind(slot_id))

	_equipment_slot_rows[slot_id] = {
		"slot_button": btn,
		# Legacy keys set to null so old code paths skip safely
		"slot_name": null,
		"display_name": null,
		"level": null,
		"bonus": null,
		"button": null,
		"panel": btn,
	}
	return btn


func _refresh_equipment_panel() -> void:
	var hero := _get_selected_hero_data()
	var display_name := str(hero.get("display_name", _selected_hero_id.capitalize()))
	var subtitle := str(hero.get("subtitle", str(hero.get("playstyle", ""))))
	var color: Color = hero.get("color", Color(0.5, 0.5, 0.5, 1.0))
	var unlocked: bool = hero.get("unlocked_by_default", true)

	# Legacy hero name/subtitle labels (kept for any remaining references)
	if _equip_hero_name_label != null:
		_equip_hero_name_label.text = display_name
	if _equip_hero_subtitle_label != null:
		_equip_hero_subtitle_label.text = subtitle
	# Central character holder
	if _char_holder_name != null:
		_char_holder_name.text = display_name
	if _char_holder_subtitle != null:
		_char_holder_subtitle.text = subtitle
	if _char_holder_panel != null:
		_char_holder_panel.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if _equip_hero_swatch != null:
		_equip_hero_swatch.color = color
	if _training_hero_label != null:
		_training_hero_label.text = "Hero: %s" % display_name
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
	_inventory_grid.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	scroll.add_child(_inventory_grid)
	return scroll


func _get_inventory_cell_data() -> Array:
	var cells: Array = []
	if _meta_manager != null and _meta_manager.has_method("get_inventory_items_for_hero"):
		var items: Array = _get_filtered_sorted_items()
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
			var cell_set_id := str(def.get("set_id", "")) if not def.is_empty() else ""
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
				"rarity": str(def.get("rarity", "common")) if not def.is_empty() else "common",
				"set_id": cell_set_id,
				"set_name": EquipmentFormat.set_display_name(cell_set_id),
				"locked": bool(item.get("locked", false)),
				"favorite": bool(item.get("favorite", false)),
				"created_index": int(item.get("created_index", 0)),
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
	_update_capacity_label()
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
	_select_inventory_cell(_selected_inventory_cell_index, false)


func _build_inventory_cell(cell_data: Dictionary, index: int) -> Control:
	var button := Button.new()
	button.custom_minimum_size = Vector2(72, 72)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 9)
	button.clip_text = true
	button.pressed.connect(_on_inventory_cell_pressed.bind(index))
	if bool(cell_data.get("occupied", false)):
		var display_name := str(cell_data.get("display_name", "Item"))
		var slot_id := str(cell_data.get("slot_id", ""))
		var level := int(cell_data.get("level", 0))
		var max_level := int(cell_data.get("max_level", 0))
		var is_equipped := bool(cell_data.get("is_equipped", false))
		var is_locked := bool(cell_data.get("locked", false))
		var is_fav := bool(cell_data.get("favorite", false))
		var rarity := str(cell_data.get("rarity", "common"))
		var slot_label := _format_slot_name(slot_id)
		var markers := ""
		if is_equipped: markers += "[E]"
		if is_locked: markers += "[L]"
		if is_fav: markers += "[*]"
		var marker_tag := (" " + markers) if not markers.is_empty() else ""
		button.text = "%s%s\n%s %s\nLv %d/%d" % [
			_get_short_item_name(display_name),
			marker_tag,
			slot_label,
			EquipmentFormat.rarity_short(rarity),
			level,
			max_level,
		]
		if is_equipped:
			button.modulate = UIStateColors.positive_color()
	else:
		button.text = "+\nEmpty"
		button.modulate = Color(0.48, 0.52, 0.58, 1.0)
	return button


func _on_inventory_cell_pressed(index: int) -> void:
	_select_inventory_cell(index, true)


func _select_inventory_cell(index: int, open_popup: bool = false) -> void:
	var cells := _get_inventory_cell_data()
	if cells.is_empty():
		_update_inventory_detail({})
		return
	_selected_inventory_cell_index = clampi(index, 0, cells.size() - 1)
	var selected_cell: Dictionary = cells[_selected_inventory_cell_index]
	var previous_instance_id := _selected_inventory_instance_id
	_selected_inventory_instance_id = str(selected_cell.get("instance_id", "")) if bool(selected_cell.get("occupied", false)) else ""
	if previous_instance_id != _selected_inventory_instance_id:
		_last_upgrade_message = ""
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
			# Unselected + in inventory: tinted by rarity
			button.modulate = EquipmentFormat.rarity_color(str(cells[int(cell_index)].get("rarity", "common")))
		else:
			# Empty cell: muted gray
			button.modulate = Color(0.48, 0.52, 0.58, 1.0)
	_update_inventory_detail(selected_cell)
	# Selection is quiet during refresh; explicit cell clicks decide popup state.
	if _item_action_popup != null:
		if open_popup and bool(selected_cell.get("occupied", false)):
			if not _item_action_popup.visible:
				_item_action_popup.popup_centered()
		elif open_popup:
			_item_action_popup.hide()


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

	# Update upgrade button
	if _inventory_upgrade_button != null:
		if not is_occupied or instance_id.is_empty():
			_inventory_upgrade_button.text = "Upgrade"
			_inventory_upgrade_button.disabled = true
			_inventory_upgrade_button.modulate = UIStateColors.muted_color()
		elif _meta_manager != null and _meta_manager.has_method("get_inventory_item_upgrade_cost_data"):
			var item_level: int = int(_meta_manager.get_inventory_item_level(_selected_hero_id, instance_id))
			var max_level_val: int = int(_meta_manager.get_inventory_item_max_level(_selected_hero_id, instance_id))
			if item_level >= max_level_val:
				_inventory_upgrade_button.text = "MAX"
				_inventory_upgrade_button.disabled = true
				_inventory_upgrade_button.modulate = UIStateColors.muted_color()
			elif _meta_manager.has_method("can_upgrade_inventory_item") and not _meta_manager.can_upgrade_inventory_item(instance_id):
				_inventory_upgrade_button.text = "Need Resources"
				_inventory_upgrade_button.disabled = true
				_inventory_upgrade_button.modulate = UIStateColors.muted_color()
			else:
				_inventory_upgrade_button.text = "Upgrade"
				_inventory_upgrade_button.disabled = false
				_inventory_upgrade_button.modulate = UIStateColors.positive_color()
		else:
			_inventory_upgrade_button.text = "Upgrade"
			_inventory_upgrade_button.disabled = true
			_inventory_upgrade_button.modulate = UIStateColors.muted_color()

	if _inventory_detail_label == null:
		return

	if not is_occupied or instance_id.is_empty():
		if _item_action_title_label != null:
			_item_action_title_label.text = "Empty Slot"
		if _inventory_detail_label != null:
			var filter_active := (_inventory_slot_filter != "all" or _inventory_state_filter != "all")
			if filter_active and _get_filtered_sorted_items().is_empty():
				_inventory_detail_label.text = "No items match current filters.\nTry changing Slot or State filter."
			else:
				_inventory_detail_label.text = "No item in this slot."
		_refresh_management_buttons("", false, false, "")
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
	if _item_action_title_label != null:
		_item_action_title_label.text = display_name
	var slot_display := _format_slot_name(slot_id)
	var rarity := str(tmpl.get("rarity", "common")) if not tmpl.is_empty() else "common"
	var is_locked := bool(item.get("locked", false))
	var is_fav := bool(item.get("favorite", false))
	var status_str := "EQUIPPED" if is_equipped else "In Inventory"
	var stat_str := _format_stat_line(stat_info)
	var desc := str(tmpl.get("description", ""))

	var compare_str := ""
	if not slot_id.is_empty() and _meta_manager != null:
		compare_str = _format_compare_section(instance_id, slot_id)

	# Build next-level stat preview
	var next_level_str := ""
	if _meta_manager != null and _meta_manager.has_method("get_inventory_item_max_level"):
		var cur_level: int = level
		var max_lv: int = int(_meta_manager.get_inventory_item_max_level(_selected_hero_id, instance_id))
		if cur_level < max_lv and not tmpl.is_empty():
			var per_level := float(tmpl.get("stat_bonus_per_level", 0.0))
			var stat_type_str := str(tmpl.get("stat_bonus_type", ""))
			if per_level > 0.0 and not stat_type_str.is_empty():
				next_level_str = "Next Level: %s" % EquipmentFormat.stat_next_text(stat_type_str, per_level, cur_level)

	# Gameplay effect note
	var gameplay_note := "Affects gameplay: YES" if is_equipped else "Affects gameplay: NO (equip to apply)"

	var upgrade_cost: Dictionary = {}
	var upgrade_block := ""
	if _meta_manager != null and _meta_manager.has_method("get_inventory_item_upgrade_cost_data"):
		upgrade_cost = _meta_manager.get_inventory_item_upgrade_cost_data(instance_id)
		if _meta_manager.has_method("get_inventory_item_upgrade_block_reason"):
			upgrade_block = str(_meta_manager.get_inventory_item_upgrade_block_reason(instance_id))

	# Dismantle info
	var dismantle_result: Dictionary = {}
	var dismantle_block := ""
	if _meta_manager != null and _meta_manager.has_method("get_inventory_item_dismantle_result"):
		dismantle_result = _meta_manager.get_inventory_item_dismantle_result(instance_id)
		dismantle_block = str(_meta_manager.get_inventory_item_dismantle_block_reason(instance_id))

	var lines := PackedStringArray()
	lines.append("=== %s ===" % display_name)
	lines.append("Slot: %s" % slot_display)
	lines.append("Rarity: %s" % EquipmentFormat.rarity_display_name(rarity))
	var popup_set_id := str(tmpl.get("set_id", "")) if not tmpl.is_empty() else ""
	for set_line in _get_compact_set_popup_lines(popup_set_id):
		lines.append(set_line)
	lines.append("Level: %d / %d" % [level, max_level])
	if not instance_id.is_empty() and _meta_manager != null and _meta_manager.has_method("get_inventory_item_power"):
		lines.append(EquipmentFormat.power_text(int(_meta_manager.get_inventory_item_power(instance_id))))
	lines.append("Status: %s" % status_str)
	lines.append("Locked: %s" % ("Yes" if is_locked else "No"))
	lines.append("Favorite: %s" % ("Yes" if is_fav else "No"))
	lines.append(gameplay_note)
	if not stat_str.is_empty():
		lines.append("")
		lines.append(stat_str)
	if not next_level_str.is_empty():
		lines.append(next_level_str)
	lines.append("")
	for resource_line in _get_upgrade_resource_lines(upgrade_cost):
		lines.append(resource_line)
	if not upgrade_block.is_empty():
		lines.append("Cannot upgrade: %s" % upgrade_block)
	if not _last_upgrade_message.is_empty() and _selected_inventory_instance_id == instance_id:
		lines.append("Last upgrade: %s" % _last_upgrade_message)
	lines.append("")
	lines.append("Dismantle reward: %s" % _format_dismantle_result(dismantle_result))
	if not dismantle_block.is_empty():
		lines.append("Cannot dismantle: %s" % dismantle_block)
	if not desc.is_empty():
		lines.append("")
		lines.append(desc)
	if not compare_str.is_empty():
		lines.append("")
		lines.append(compare_str)
	_inventory_detail_label.text = "\n".join(lines)
	_refresh_management_buttons(instance_id, is_locked, is_fav, dismantle_block)


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
	return EquipmentFormat.stat_display_name(stat_type)


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


func _format_dismantle_result(result: Dictionary) -> String:
	var parts: PackedStringArray = []
	var gold := int(result.get("gold", 0))
	if gold > 0:
		parts.append("%d Gold" % gold)
	var materials: Dictionary = result.get("materials", {}) if result.get("materials", {}) is Dictionary else {}
	var material_ids := materials.keys()
	material_ids.sort()
	for material_id in material_ids:
		var amount := int(materials.get(material_id, 0))
		if amount <= 0:
			continue
		var display := str(material_id).replace("_", " ").capitalize()
		if _meta_manager != null and _meta_manager.has_method("get_material_display_name"):
			display = str(_meta_manager.get_material_display_name(str(material_id)))
		parts.append("%d %s" % [amount, display])
	return "none" if parts.is_empty() else ", ".join(parts)


func _format_material_name(material_id: String) -> String:
	if _meta_manager != null and _meta_manager.has_method("get_material_display_name"):
		return str(_meta_manager.get_material_display_name(material_id))
	return material_id.replace("_", " ").capitalize()


func _format_upgrade_cost(cost: Dictionary) -> String:
	var parts: PackedStringArray = []
	var gold := int(cost.get("gold", 0))
	if gold > 0:
		parts.append("%d Gold" % gold)
	var materials: Dictionary = cost.get("materials", {}) if cost.get("materials", {}) is Dictionary else {}
	var material_ids := materials.keys()
	material_ids.sort()
	for material_id in material_ids:
		var amount := int(materials.get(material_id, 0))
		if amount <= 0:
			continue
		parts.append("%d %s" % [amount, _format_material_name(str(material_id))])
	return "none" if parts.is_empty() else ", ".join(parts)


func _get_upgrade_resource_lines(cost: Dictionary) -> PackedStringArray:
	var lines := PackedStringArray()
	var gold_required := int(cost.get("gold", 0))
	var gold_owned := 0
	if _meta_manager != null and _meta_manager.has_method("get_gold"):
		gold_owned = int(_meta_manager.get_gold())
	lines.append("Upgrade Cost: %s" % _format_upgrade_cost(cost))
	lines.append("Owned Gold: %d / %d" % [gold_owned, gold_required])
	if gold_owned < gold_required:
		lines.append("Missing Gold: %d" % (gold_required - gold_owned))
	var materials: Dictionary = cost.get("materials", {}) if cost.get("materials", {}) is Dictionary else {}
	var material_ids := materials.keys()
	material_ids.sort()
	for material_id in material_ids:
		var key := str(material_id)
		var required := int(materials.get(material_id, 0))
		if required <= 0:
			continue
		var owned := 0
		if _meta_manager != null and _meta_manager.has_method("get_equipment_material_amount"):
			owned = int(_meta_manager.get_equipment_material_amount(key))
		var display := _format_material_name(key)
		lines.append("Owned %s: %d / %d" % [display, owned, required])
		if owned < required:
			lines.append("Missing %s: %d" % [display, required - owned])
	return lines


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
	var equipped_instances: Dictionary = {}
	if _meta_manager != null and _meta_manager.has_method("get_equipped_items_for_hero"):
		equipped_instances = _meta_manager.get_equipped_items_for_hero(_selected_hero_id)

	for slot_id in _equipment_slot_rows:
		var row: Dictionary = _equipment_slot_rows.get(slot_id, {})
		var slot_btn := row.get("slot_button") as Button
		if slot_btn == null:
			continue

		var slot_name := _format_slot_name(str(slot_id))
		var equipped_instance_id := str(equipped_instances.get(slot_id, ""))
		var equipped_item: Dictionary = {}
		if not equipped_instance_id.is_empty() and _meta_manager != null and _meta_manager.has_method("get_inventory_item"):
			equipped_item = _meta_manager.get_inventory_item(_selected_hero_id, equipped_instance_id)

		if not equipped_item.is_empty():
			var template_id := str(equipped_item.get("template_id", ""))
			var item_def := _resolve_item_template(template_id)
			var display_name := str(item_def.get("display_name", template_id)) if not item_def.is_empty() else template_id
			var item_rarity := str(item_def.get("rarity", "common")) if not item_def.is_empty() else "common"
			var level := int(equipped_item.get("level", 0))
			slot_btn.text = "%s\n%s\nLv %d %s" % [slot_name, _get_short_item_name(display_name), level, EquipmentFormat.rarity_short(item_rarity)]
			slot_btn.modulate = UIStateColors.positive_color()
		else:
			slot_btn.text = "%s\n+\nEmpty" % slot_name
			slot_btn.modulate = Color(1.0, 1.0, 1.0, 1.0)

		# Refresh open popup if it's showing this slot
		if _slot_popup != null and _slot_popup.visible and _slot_popup_slot_id == slot_id:
			_update_slot_popup_content(slot_id)

func _get_compact_set_popup_lines(set_id: String) -> PackedStringArray:
	var lines := PackedStringArray()
	if set_id.is_empty():
		lines.append("Set: None")
		return lines
	lines.append("Set: %s" % EquipmentFormat.set_display_name(set_id))
	if _meta_manager == null or not _meta_manager.has_method("get_equipped_set_counts"):
		lines.append("Equipped pieces: 0 / 6")
		lines.append("Active bonus: None")
		lines.append("Next bonus: Unknown")
		return lines
	var counts: Dictionary = _meta_manager.get_equipped_set_counts()
	var count := int(counts.get(set_id, 0))
	lines.append("Equipped pieces: %d / 6" % count)
	var set_data: Dictionary = _meta_manager.get_equipment_set(set_id) if _meta_manager.has_method("get_equipment_set") else {}
	var bonuses: Array = set_data.get("bonuses", []) if set_data.get("bonuses", []) is Array else []
	var active_text: PackedStringArray = []
	for bonus in bonuses:
		if not bonus is Dictionary:
			continue
		var pieces := int(bonus.get("pieces", 0))
		var modifiers: Dictionary = bonus.get("modifiers", {}) if bonus.get("modifiers", {}) is Dictionary else {}
		var text := EquipmentFormat.modifiers_text(modifiers)
		if pieces <= count:
			if not text.is_empty():
				active_text.append("%d pieces - %s" % [pieces, text])
	if active_text.is_empty():
		lines.append("Active bonus: None")
	elif active_text.size() == 1:
		var single_active := str(active_text[0])
		lines.append("Active bonus: %s" % single_active.get_slice(" - ", 1))
	else:
		lines.append("Active bonuses: %s" % "; ".join(active_text))
	for bonus in bonuses:
		if not bonus is Dictionary:
			continue
		var pieces := int(bonus.get("pieces", 0))
		if pieces <= count:
			continue
		var modifiers: Dictionary = bonus.get("modifiers", {}) if bonus.get("modifiers", {}) is Dictionary else {}
		var text := EquipmentFormat.modifiers_text(modifiers)
		lines.append("Next bonus: %d pieces - %s" % [pieces, text])
		return lines
	lines.append("Next bonus: Full set active")
	return lines


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
	return EquipmentFormat.slot_display_name(slot_id)


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


func _update_materials_label() -> void:
	if _materials_label == null:
		return
	if _meta_manager == null or not _meta_manager.has_method("get_equipment_materials"):
		_materials_label.text = "Materials: none"
		return
	var materials: Dictionary = _meta_manager.get_equipment_materials()
	var parts: PackedStringArray = []
	var ids: Array[String] = []
	if _meta_manager.has_method("get_material_ids"):
		ids = _meta_manager.get_material_ids()
	else:
		ids = ["common_dust", "uncommon_dust", "rare_dust", "epic_core", "legendary_core", "mythic_core"]
	for material_id in ids:
		var amount := int(materials.get(material_id, 0))
		if amount <= 0:
			continue
		var display := material_id.replace("_", " ").capitalize()
		if _meta_manager.has_method("get_material_display_name"):
			display = str(_meta_manager.get_material_display_name(material_id))
		parts.append("%s %d" % [display, amount])
	_materials_label.text = "Materials: %s" % (" | ".join(parts) if not parts.is_empty() else "none")


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


func _on_gold_changed(_value: int) -> void:
	if visible:
		refresh()


func _on_equipment_materials_changed(_materials: Dictionary) -> void:
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
	_rebuild_hero_dropdown()


func _rebuild_hero_dropdown() -> void:
	if _hero_dropdown == null:
		return
	# Disconnect signal temporarily to avoid triggering selection during rebuild
	if _hero_dropdown.item_selected.is_connected(_on_hero_dropdown_changed):
		_hero_dropdown.item_selected.disconnect(_on_hero_dropdown_changed)
	_hero_dropdown.clear()
	for i in range(_heroes.size()):
		var hero: Dictionary = _heroes[i]
		var hero_display_name := str(hero.get("display_name", str(hero.get("id", "Hero %d" % i))))
		_hero_dropdown.add_item(hero_display_name)
	# Select current hero
	for i in range(_heroes.size()):
		var hero: Dictionary = _heroes[i]
		if str(hero.get("id", "")) == _selected_hero_id:
			_hero_dropdown.select(i)
			break
	if not _hero_dropdown.item_selected.is_connected(_on_hero_dropdown_changed):
		_hero_dropdown.item_selected.connect(_on_hero_dropdown_changed)


func _on_hero_dropdown_changed(index: int) -> void:
	if index < 0 or index >= _heroes.size():
		return
	var hero: Dictionary = _heroes[index]
	var hero_id := str(hero.get("id", ""))
	if hero_id.is_empty():
		return
	set_selected_hero(hero_id)


# ─── Slot popup ───────────────────────────────────────────────────────────────

func _build_starter_pack_popup() -> void:
	_starter_pack_popup = PopupPanel.new()
	_starter_pack_popup.min_size = Vector2i(420, 300)
	add_child(_starter_pack_popup)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_starter_pack_popup.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Starter Equipment Pack"
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	var desc := Label.new()
	desc.text = "Claim your first equipment items.\nEquip them manually from the inventory."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 12)
	desc.modulate = Color(0.82, 0.86, 0.92, 1.0)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	vbox.add_child(HSeparator.new())

	_starter_pack_items_label = Label.new()
	_starter_pack_items_label.text = (
		"Power Core  —  Core  —  Common\n" +
		"Reinforced Suit  —  Suit  —  Common\n" +
		"Awareness Emblem  —  Emblem  —  Common\n" +
		"Striker Gauntlets  —  Gauntlets  —  Common\n" +
		"Runner Boots  —  Boots  —  Common\n" +
		"Shield Artifact  —  Artifact  —  Common"
	)
	_starter_pack_items_label.add_theme_font_size_override("font_size", 12)
	_starter_pack_items_label.modulate = EquipmentFormat.rarity_color("common")
	vbox.add_child(_starter_pack_items_label)

	vbox.add_child(HSeparator.new())

	var buttons_row := HBoxContainer.new()
	buttons_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(buttons_row)

	var accept_btn := Button.new()
	accept_btn.text = "Accept"
	accept_btn.custom_minimum_size = Vector2(140, 44)
	accept_btn.add_theme_font_size_override("font_size", 14)
	accept_btn.pressed.connect(_on_starter_pack_accept_pressed)
	buttons_row.add_child(accept_btn)


func _show_starter_pack_popup_if_needed() -> void:
	if _meta_manager == null or _starter_pack_popup == null:
		return
	if not _meta_manager.has_method("can_claim_starter_equipment"):
		return
	if _meta_manager.can_claim_starter_equipment():
		if _starter_pack_items_label != null and _meta_manager.has_method("preview_starter_equipment"):
			var previews: Array = _meta_manager.preview_starter_equipment()
			if not previews.is_empty():
				var lines: PackedStringArray = []
				for tmpl in previews:
					lines.append(EquipmentFormat.item_display_line(tmpl))
				_starter_pack_items_label.text = "\n".join(lines)
		_starter_pack_popup.popup_centered()


func _on_starter_pack_accept_pressed() -> void:
	if _starter_pack_popup != null:
		_starter_pack_popup.hide()
	if _meta_manager != null and _meta_manager.has_method("claim_starter_equipment"):
		_meta_manager.claim_starter_equipment()


func _build_slot_popup() -> void:
	_slot_popup = PopupPanel.new()
	_slot_popup.min_size = Vector2i(340, 260)
	add_child(_slot_popup)

	var popup_margin := MarginContainer.new()
	popup_margin.add_theme_constant_override("margin_left", 16)
	popup_margin.add_theme_constant_override("margin_right", 16)
	popup_margin.add_theme_constant_override("margin_top", 12)
	popup_margin.add_theme_constant_override("margin_bottom", 12)
	_slot_popup.add_child(popup_margin)

	var popup_inner := VBoxContainer.new()
	popup_inner.add_theme_constant_override("separation", 6)
	popup_margin.add_child(popup_inner)

	_slot_popup_title_label = Label.new()
	_slot_popup_title_label.add_theme_font_size_override("font_size", 15)
	popup_inner.add_child(_slot_popup_title_label)

	popup_inner.add_child(HSeparator.new())

	_slot_popup_detail_label = Label.new()
	_slot_popup_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_slot_popup_detail_label.add_theme_font_size_override("font_size", 12)
	popup_inner.add_child(_slot_popup_detail_label)

	var popup_buttons := HBoxContainer.new()
	popup_buttons.add_theme_constant_override("separation", 8)
	popup_inner.add_child(popup_buttons)

	_slot_popup_unequip_button = Button.new()
	_slot_popup_unequip_button.text = "Unequip"
	_slot_popup_unequip_button.custom_minimum_size = Vector2(100, 36)
	_slot_popup_unequip_button.pressed.connect(_on_slot_popup_unequip_pressed)
	popup_buttons.add_child(_slot_popup_unequip_button)

	_slot_popup_close_button = Button.new()
	_slot_popup_close_button.text = "Close"
	_slot_popup_close_button.custom_minimum_size = Vector2(80, 36)
	_slot_popup_close_button.pressed.connect(_on_slot_popup_close_pressed)
	popup_buttons.add_child(_slot_popup_close_button)


func _on_equipped_slot_pressed(slot_id: String) -> void:
	_slot_popup_slot_id = slot_id
	_update_slot_popup_content(slot_id)
	_slot_popup.popup_centered()


func _update_slot_popup_content(slot_id: String) -> void:
	if _slot_popup_title_label == null:
		return
	var slot_display := _format_slot_name(slot_id)
	_slot_popup_title_label.text = "Slot: %s" % slot_display

	if _meta_manager == null:
		_slot_popup_detail_label.text = "No data available."
		if _slot_popup_unequip_button != null:
			_slot_popup_unequip_button.disabled = true
		return

	var instance_id := ""
	if _meta_manager.has_method("get_equipped_instance_id_for_slot"):
		instance_id = str(_meta_manager.get_equipped_instance_id_for_slot(_selected_hero_id, slot_id))

	if instance_id.is_empty():
		_slot_popup_detail_label.text = "No item equipped in this slot."
		if _slot_popup_unequip_button != null:
			_slot_popup_unequip_button.disabled = true
		return

	var item: Dictionary = {}
	if _meta_manager.has_method("get_inventory_item"):
		item = _meta_manager.get_inventory_item(_selected_hero_id, instance_id)
	if item.is_empty():
		_slot_popup_detail_label.text = "No item equipped in this slot."
		if _slot_popup_unequip_button != null:
			_slot_popup_unequip_button.disabled = true
		return

	var display_name := _get_item_display_name(instance_id)
	var level := int(item.get("level", 0))
	var max_level_val := 0
	if _meta_manager.has_method("get_inventory_item_max_level"):
		max_level_val = int(_meta_manager.get_inventory_item_max_level(_selected_hero_id, instance_id))
	var stat_info := _get_item_stat_info(instance_id)
	var stat_str := _format_stat_line(stat_info)
	var tmpl := _get_item_template_for_instance(instance_id)
	var desc := str(tmpl.get("description", ""))
	var popup_rarity := str(tmpl.get("rarity", "common")) if not tmpl.is_empty() else "common"

	var next_stat_str := ""
	if level < max_level_val and not tmpl.is_empty():
		var per_level := float(tmpl.get("stat_bonus_per_level", 0.0))
		var stat_type_str := str(tmpl.get("stat_bonus_type", ""))
		if per_level > 0.0 and not stat_type_str.is_empty():
			next_stat_str = "Next Level: %s" % EquipmentFormat.stat_next_text(stat_type_str, per_level, level)

	var lines := PackedStringArray()
	lines.append(display_name)
	lines.append("Rarity: %s" % EquipmentFormat.rarity_display_name(popup_rarity))
	var slot_set_id := str(tmpl.get("set_id", "")) if not tmpl.is_empty() else ""
	for set_line in _get_compact_set_popup_lines(slot_set_id):
		lines.append(set_line)
	lines.append("Level: %d / %d" % [level, max_level_val])
	if _meta_manager != null and _meta_manager.has_method("get_inventory_item_power"):
		lines.append(EquipmentFormat.power_text(int(_meta_manager.get_inventory_item_power(instance_id))))
	lines.append("Status: EQUIPPED")
	if not stat_str.is_empty():
		lines.append("")
		lines.append(stat_str)
	if not next_stat_str.is_empty():
		lines.append(next_stat_str)
	if not desc.is_empty():
		lines.append("")
		lines.append(desc)
	_slot_popup_detail_label.text = "\n".join(lines)

	if _slot_popup_unequip_button != null:
		_slot_popup_unequip_button.disabled = false


func _on_slot_popup_unequip_pressed() -> void:
	if _slot_popup_slot_id.is_empty() or _meta_manager == null:
		return
	if not _meta_manager.has_method("unequip_slot"):
		return
	_meta_manager.unequip_slot(_selected_hero_id, _slot_popup_slot_id)
	if _slot_popup != null:
		_slot_popup.hide()


func _on_slot_popup_close_pressed() -> void:
	if _slot_popup != null:
		_slot_popup.hide()


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


func _on_inventory_slot_filter_changed(index: int) -> void:
	var slot_values := ["all", "core", "suit", "emblem", "gauntlets", "boots", "artifact"]
	if index >= 0 and index < slot_values.size():
		_inventory_slot_filter = slot_values[index]
	_refresh_inventory_grid_with_selection_preserve()


func _on_inventory_state_filter_changed(index: int) -> void:
	var state_values := ["all", "equipped", "unequipped"]
	if index >= 0 and index < state_values.size():
		_inventory_state_filter = state_values[index]
	_refresh_inventory_grid_with_selection_preserve()


func _on_inventory_sort_mode_changed(index: int) -> void:
	var sort_values := ["default", "slot", "level_high", "level_low", "name", "rarity_high", "rarity_low", "favorite_first", "newest"]
	if index >= 0 and index < sort_values.size():
		_inventory_sort_mode = sort_values[index]
	_refresh_inventory_grid_with_selection_preserve()


func _refresh_inventory_grid_with_selection_preserve() -> void:
	var prev_instance_id := _selected_inventory_instance_id
	_refresh_inventory_grid()
	# Try to restore selection by instance_id
	var cells := _get_inventory_cell_data()
	if not prev_instance_id.is_empty():
		for i in range(cells.size()):
			var c: Dictionary = cells[i]
			if bool(c.get("occupied", false)) and str(c.get("instance_id", "")) == prev_instance_id:
				_select_inventory_cell(i, false)
				return
	# Fallback: select first occupied cell
	for i in range(cells.size()):
		if bool(cells[i].get("occupied", false)):
			_select_inventory_cell(i, false)
			return
	# No occupied cells visible
	_selected_inventory_instance_id = ""
	_update_inventory_detail({})


func _get_filtered_sorted_items() -> Array:
	if _meta_manager == null:
		return []
	var all_items: Array = _meta_manager.get_inventory_items_for_hero(_selected_hero_id) if _meta_manager.has_method("get_inventory_items_for_hero") else []
	var equipped_map: Dictionary = _meta_manager.get_equipped_items_for_hero(_selected_hero_id) if _meta_manager.has_method("get_equipped_items_for_hero") else {}
	# Build set of equipped instance_ids for quick lookup
	var equipped_ids := {}
	for slot in equipped_map:
		equipped_ids[str(equipped_map[slot])] = true

	# Filter
	var filtered: Array = []
	for item in all_items:
		if not item is Dictionary:
			continue
		var slot_id := str(item.get("slot_id", ""))
		var instance_id := str(item.get("instance_id", ""))
		var is_equipped: bool = equipped_ids.has(instance_id)
		# Slot filter
		if _inventory_slot_filter != "all" and slot_id != _inventory_slot_filter:
			continue
		# State filter
		if _inventory_state_filter == "equipped" and not is_equipped:
			continue
		if _inventory_state_filter == "unequipped" and is_equipped:
			continue
		filtered.append(item)

	# Sort
	match _inventory_sort_mode:
		"slot":
			var slot_order := ["core", "suit", "emblem", "gauntlets", "boots", "artifact"]
			filtered.sort_custom(func(a, b):
				var ai := slot_order.find(str(a.get("slot_id", "")))
				var bi := slot_order.find(str(b.get("slot_id", "")))
				if ai == -1: ai = 99
				if bi == -1: bi = 99
				return ai < bi
			)
		"level_high":
			filtered.sort_custom(func(a, b):
				return int(a.get("level", 0)) > int(b.get("level", 0))
			)
		"level_low":
			filtered.sort_custom(func(a, b):
				return int(a.get("level", 0)) < int(b.get("level", 0))
			)
		"name":
			filtered.sort_custom(func(a, b):
				var na := str(a.get("template_id", ""))
				var nb := str(b.get("template_id", ""))
				return na < nb
			)
		"rarity_high":
			filtered.sort_custom(func(a, b):
				return _get_item_rarity_order(a) > _get_item_rarity_order(b)
			)
		"rarity_low":
			filtered.sort_custom(func(a, b):
				return _get_item_rarity_order(a) < _get_item_rarity_order(b)
			)
		"favorite_first":
			filtered.sort_custom(func(a, b):
				var af := bool(a.get("favorite", false))
				var bf := bool(b.get("favorite", false))
				if af != bf:
					return af
				return false
			)
		"newest":
			filtered.sort_custom(func(a, b):
				return int(a.get("created_index", 0)) > int(b.get("created_index", 0))
			)
		# "default": keep inventory order

	return filtered


func _get_item_rarity_order(item: Dictionary) -> int:
	var template_id := str(item.get("template_id", ""))
	var tmpl := _resolve_item_template(template_id)
	var rarity := str(tmpl.get("rarity", "common")) if not tmpl.is_empty() else "common"
	return EquipmentFormat.rarity_order(rarity)


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


func _on_inventory_upgrade_pressed() -> void:
	if _selected_inventory_instance_id.is_empty() or _selected_hero_id.is_empty():
		return
	if _meta_manager == null or not _meta_manager.has_method("upgrade_inventory_item"):
		return
	var result: Dictionary = _meta_manager.upgrade_inventory_item(_selected_hero_id, _selected_inventory_instance_id)
	if bool(result.get("success", false)):
		_last_upgrade_message = ""
		_update_equipment_slots()
		_refresh_inventory_shell()
		_select_inventory_cell(_selected_inventory_cell_index, _item_action_popup != null and _item_action_popup.visible)
		if _gold_label != null and _meta_manager.has_method("get_gold"):
			_gold_label.text = "Gold: %d" % int(_meta_manager.get_gold())
		_update_materials_label()
	else:
		_last_upgrade_message = str(result.get("reason", "Upgrade failed."))
		_select_inventory_cell(_selected_inventory_cell_index, _item_action_popup != null and _item_action_popup.visible)
	# UI also refreshes via inventory_item_upgraded / inventory_changed / gold/material signals


func _refresh_management_buttons(instance_id: String, is_locked: bool, is_fav: bool, dismantle_block: String) -> void:
	var has_item := not instance_id.is_empty()
	if _inventory_lock_button != null:
		_inventory_lock_button.disabled = not has_item
		_inventory_lock_button.text = "Unlock" if (has_item and is_locked) else "Lock"
	if _inventory_favorite_button != null:
		_inventory_favorite_button.disabled = not has_item
		_inventory_favorite_button.text = "[*]Off" if (has_item and is_fav) else "[*]On"
	if _inventory_dismantle_button != null:
		_inventory_dismantle_button.disabled = not has_item or not dismantle_block.is_empty()
		if has_item and not dismantle_block.is_empty():
			_inventory_dismantle_button.modulate = UIStateColors.muted_color()
		else:
			_inventory_dismantle_button.modulate = Color.WHITE


func _update_capacity_label() -> void:
	if _inventory_capacity_label == null or _meta_manager == null:
		return
	var count := 0
	if _meta_manager.has_method("get_inventory_item_count"):
		count = int(_meta_manager.get_inventory_item_count())
	var capacity: int = 60
	if _meta_manager.has_method("get_inventory_capacity"):
		capacity = int(_meta_manager.get_inventory_capacity())
	_inventory_capacity_label.text = "(%d / %d)" % [count, capacity]
	if count > capacity:
		_inventory_capacity_label.modulate = UIStateColors.warning_color()
	else:
		_inventory_capacity_label.modulate = Color(0.72, 0.78, 0.88, 1.0)


func _on_inventory_lock_pressed() -> void:
	if _selected_inventory_instance_id.is_empty() or _meta_manager == null:
		return
	if not _meta_manager.has_method("toggle_inventory_item_locked"):
		return
	_meta_manager.toggle_inventory_item_locked(_selected_inventory_instance_id)


func _on_inventory_favorite_pressed() -> void:
	if _selected_inventory_instance_id.is_empty() or _meta_manager == null:
		return
	if not _meta_manager.has_method("toggle_inventory_item_favorite"):
		return
	_meta_manager.toggle_inventory_item_favorite(_selected_inventory_instance_id)


func _on_inventory_dismantle_pressed() -> void:
	if _selected_inventory_instance_id.is_empty() or _meta_manager == null:
		return
	if not _meta_manager.has_method("can_dismantle_inventory_item"):
		return
	if not _meta_manager.can_dismantle_inventory_item(_selected_inventory_instance_id):
		return
	var result := {}
	if _meta_manager.has_method("get_inventory_item_dismantle_result"):
		result = _meta_manager.get_inventory_item_dismantle_result(_selected_inventory_instance_id)
	var item_name := _get_item_display_name(_selected_inventory_instance_id)
	_dismantle_confirm_instance_id = _selected_inventory_instance_id
	if _dismantle_confirm_popup != null:
		var lines := PackedStringArray()
		lines.append("Dismantle %s?" % item_name)
		lines.append("")
		lines.append("You will receive:")
		lines.append("- %d Gold" % int(result.get("gold", 0)))
		var materials: Dictionary = result.get("materials", {}) if result.get("materials", {}) is Dictionary else {}
		var material_ids := materials.keys()
		material_ids.sort()
		for material_id in material_ids:
			var amount := int(materials.get(material_id, 0))
			if amount <= 0:
				continue
			var display := str(material_id).replace("_", " ").capitalize()
			if _meta_manager.has_method("get_material_display_name"):
				display = str(_meta_manager.get_material_display_name(str(material_id)))
			lines.append("- %d %s" % [amount, display])
		var item: Dictionary = {}
		if _meta_manager.has_method("get_inventory_item"):
			item = _meta_manager.get_inventory_item(_selected_hero_id, _selected_inventory_instance_id)
		if bool(item.get("favorite", false)):
			lines.append("")
			lines.append("Warning: this item is marked as Favorite.")
		_dismantle_confirm_popup.dialog_text = "\n".join(lines)
		_dismantle_confirm_popup.popup_centered()


func _on_dismantle_confirmed() -> void:
	var instance_id := _dismantle_confirm_instance_id
	_dismantle_confirm_instance_id = ""
	if instance_id.is_empty() or _meta_manager == null:
		return
	if not _meta_manager.has_method("dismantle_inventory_item"):
		return
	_meta_manager.dismantle_inventory_item(instance_id)
	# Close item action popup — item no longer exists
	if _item_action_popup != null:
		_item_action_popup.hide()
	# UI refreshes via inventory_changed + gold/material signals


func _build_dismantle_confirm_popup() -> void:
	_dismantle_confirm_popup = ConfirmationDialog.new()
	_dismantle_confirm_popup.title = "Dismantle Item"
	_dismantle_confirm_popup.min_size = Vector2i(360, 140)
	_dismantle_confirm_popup.get_ok_button().text = "Dismantle"
	_dismantle_confirm_popup.confirmed.connect(_on_dismantle_confirmed)
	add_child(_dismantle_confirm_popup)


func _build_item_action_popup() -> void:
	_item_action_popup = PopupPanel.new()
	_item_action_popup.min_size = Vector2i(380, 320)
	add_child(_item_action_popup)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_item_action_popup.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	_item_action_title_label = Label.new()
	_item_action_title_label.text = "Item"
	_item_action_title_label.add_theme_font_size_override("font_size", 16)
	_item_action_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_item_action_title_label)

	vbox.add_child(HSeparator.new())

	var detail_scroll := ScrollContainer.new()
	detail_scroll.custom_minimum_size = Vector2(0, 160)
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(detail_scroll)

	_inventory_detail_label = Label.new()
	_inventory_detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inventory_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_inventory_detail_label.add_theme_font_size_override("font_size", 11)
	_inventory_detail_label.modulate = Color(0.82, 0.86, 0.92, 1.0)
	detail_scroll.add_child(_inventory_detail_label)

	vbox.add_child(HSeparator.new())

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 8)
	row1.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(row1)

	_inventory_equip_button = Button.new()
	_inventory_equip_button.text = "Equip"
	_inventory_equip_button.disabled = true
	_inventory_equip_button.custom_minimum_size = Vector2(100, 36)
	_inventory_equip_button.pressed.connect(_on_inventory_equip_pressed)
	row1.add_child(_inventory_equip_button)

	_inventory_upgrade_button = Button.new()
	_inventory_upgrade_button.text = "Upgrade"
	_inventory_upgrade_button.disabled = true
	_inventory_upgrade_button.custom_minimum_size = Vector2(110, 36)
	_inventory_upgrade_button.pressed.connect(_on_inventory_upgrade_pressed)
	row1.add_child(_inventory_upgrade_button)

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 8)
	row2.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(row2)

	_inventory_lock_button = Button.new()
	_inventory_lock_button.text = "Lock"
	_inventory_lock_button.disabled = true
	_inventory_lock_button.custom_minimum_size = Vector2(90, 36)
	_inventory_lock_button.pressed.connect(_on_inventory_lock_pressed)
	row2.add_child(_inventory_lock_button)

	_inventory_favorite_button = Button.new()
	_inventory_favorite_button.text = "[*]On"
	_inventory_favorite_button.disabled = true
	_inventory_favorite_button.custom_minimum_size = Vector2(70, 36)
	_inventory_favorite_button.pressed.connect(_on_inventory_favorite_pressed)
	row2.add_child(_inventory_favorite_button)

	_inventory_dismantle_button = Button.new()
	_inventory_dismantle_button.text = "Dismantle"
	_inventory_dismantle_button.disabled = true
	_inventory_dismantle_button.custom_minimum_size = Vector2(110, 36)
	_inventory_dismantle_button.pressed.connect(_on_inventory_dismantle_pressed)
	row2.add_child(_inventory_dismantle_button)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(80, 36)
	close_btn.pressed.connect(func(): _item_action_popup.hide())
	row2.add_child(close_btn)


func _on_equipment_slot_panel_clicked(event: InputEvent, slot_id: String) -> void:
	if not event is InputEventMouseButton:
		return
	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return
	_on_equipped_slot_pressed(slot_id)


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
			_select_inventory_cell(i, false)
			return


func _on_inventory_changed(_hero_id: String) -> void:
	if visible:
		_refresh_equipment_panel()
		_refresh_inventory_shell()
		if _loadout_summary_popup != null and _loadout_summary_popup.visible:
			_update_loadout_summary_popup()


func _on_equipment_slot_changed(_hero_id: String, slot_id: String, _instance_id: String) -> void:
	if visible:
		_update_equipment_slots()
		_refresh_inventory_shell()
		if _slot_popup != null and _slot_popup.visible and _slot_popup_slot_id == slot_id:
			_update_slot_popup_content(slot_id)
		if _loadout_summary_popup != null and _loadout_summary_popup.visible:
			_update_loadout_summary_popup()


func _on_inventory_item_upgraded(_hero_id: String, _instance_id: String, _level: int) -> void:
	if visible:
		_update_equipment_slots()
		_refresh_inventory_shell()
		_select_inventory_cell(_selected_inventory_cell_index, _item_action_popup != null and _item_action_popup.visible)
		if _loadout_summary_popup != null and _loadout_summary_popup.visible:
			_update_loadout_summary_popup()


# ─── Loadout summary popup ────────────────────────────────────────────────────

func _build_loadout_summary_popup() -> void:
	_loadout_summary_popup = PopupPanel.new()
	_loadout_summary_popup.min_size = Vector2i(400, 340)
	add_child(_loadout_summary_popup)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	_loadout_summary_popup.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Loadout Summary"
	title.add_theme_font_size_override("font_size", 17)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(0.85, 0.95, 1.0, 1.0)
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 220)
	vbox.add_child(scroll)

	_loadout_summary_label = Label.new()
	_loadout_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_loadout_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_loadout_summary_label.add_theme_font_size_override("font_size", 12)
	_loadout_summary_label.modulate = Color(0.86, 0.90, 0.96, 1.0)
	scroll.add_child(_loadout_summary_label)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(100, 36)
	close_btn.pressed.connect(func(): _loadout_summary_popup.hide())
	vbox.add_child(close_btn)


func _show_loadout_summary_popup() -> void:
	if _loadout_summary_popup == null:
		return
	_update_loadout_summary_popup()
	_loadout_summary_popup.popup_centered()


func _update_loadout_summary_popup() -> void:
	if _loadout_summary_label == null or _meta_manager == null:
		return
	if not _meta_manager.has_method("get_loadout_summary"):
		_loadout_summary_label.text = "Not available."
		return

	var summary: Dictionary = _meta_manager.get_loadout_summary()
	var power_score := int(summary.get("power_score", 0))
	var equipped_count := int(summary.get("equipped_count", 0))
	var slot_count := int(summary.get("slot_count", 6))
	var empty_slots: Array = summary.get("empty_slots", [])
	var highest: Dictionary = summary.get("highest_item", {})
	var lowest: Dictionary = summary.get("lowest_item", {})
	var set_bonus_power := int(summary.get("set_bonus_power", 0))
	var stat_mods: Dictionary = summary.get("stat_modifiers", {})
	var active_sets: Array = summary.get("active_sets", [])

	var lines := PackedStringArray()
	lines.append("Loadout Power: %d" % power_score)
	lines.append("")
	lines.append("Equipment: %d / %d slots equipped" % [equipped_count, slot_count])

	if empty_slots.is_empty():
		lines.append("Empty Slots: none")
	else:
		var slot_names := PackedStringArray()
		for sid in empty_slots:
			slot_names.append(EquipmentFormat.slot_display_name(str(sid)))
		lines.append("Empty Slots: %s" % ", ".join(slot_names))

	lines.append("")
	lines.append("Total Stats:")
	if stat_mods.is_empty():
		lines.append("  none")
	else:
		var stat_keys := stat_mods.keys()
		stat_keys.sort()
		for stat_key in stat_keys:
			var stat_val := float(stat_mods.get(stat_key, 0.0))
			lines.append("  %s" % EquipmentFormat.stat_value_text(str(stat_key), stat_val))

	lines.append("")
	lines.append("Active Sets:")
	if active_sets.is_empty():
		lines.append("  none")
	else:
		for set_entry in active_sets:
			if not set_entry is Dictionary:
				continue
			var sname := str(set_entry.get("name", ""))
			var count := int(set_entry.get("count", 0))
			lines.append("  %s  (%d pieces)" % [sname, count])

	lines.append("")
	if highest.is_empty():
		lines.append("Strongest Item: none")
	else:
		lines.append("Strongest Item: %s  —  %s  Lv %d  (Power: %d)" % [
			str(highest.get("name", "?")),
			EquipmentFormat.slot_display_name(str(highest.get("slot_id", ""))),
			int(highest.get("level", 0)),
			int(highest.get("item_power", 0)),
		])

	if lowest.is_empty():
		lines.append("Weakest Item: none")
	else:
		lines.append("Weakest Item: %s  —  %s  Lv %d  (Power: %d)" % [
			str(lowest.get("name", "?")),
			EquipmentFormat.slot_display_name(str(lowest.get("slot_id", ""))),
			int(lowest.get("level", 0)),
			int(lowest.get("item_power", 0)),
		])

	lines.append("")
	lines.append("Set Bonus Power: %d" % set_bonus_power)

	_loadout_summary_label.text = "\n".join(lines)
