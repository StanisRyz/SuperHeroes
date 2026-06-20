extends CanvasLayer

signal evolution_chosen(evolution_id: String)

const TYPE_COLORS := {
	"attack": Color(1.0, 0.62, 0.32, 1.0),
	"active": Color(0.54, 0.74, 1.0, 1.0),
	"passive": Color(0.42, 0.9, 0.62, 1.0),
}

var _option_cards: Array[PanelContainer] = []
var _option_labels: Array[RichTextLabel] = []
var _option_buttons: Array[Button] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	layer = 22
	_build_ui()
	hide()


func show_evolutions(options: Array) -> void:
	for index in range(_option_cards.size()):
		_option_cards[index].hide()
		_option_buttons[index].set_meta("evolution_id", "")

	for index in mini(options.size(), _option_cards.size()):
		var triple: Dictionary = options[index]
		var target_type := str(triple.get("target_type", "active"))
		var button := _option_buttons[index]
		_option_labels[index].text = _format_card(triple)
		button.text = "Choose %s" % str(triple.get("title", "Evolution"))
		button.set_meta("evolution_id", str(triple.get("evolution_id", "")))
		_option_cards[index].modulate = TYPE_COLORS.get(target_type, Color.WHITE)
		_option_cards[index].show()
	show()


func _format_card(triple: Dictionary) -> String:
	var title := str(triple.get("title", "Evolution"))
	var target_type := str(triple.get("target_type", "active"))
	var target_id := str(triple.get("target_id", triple.get("target_active_skill_id", "")))
	var type_label := "%s EVOLUTION" % target_type.to_upper()
	var description := str(triple.get("description", ""))
	var line_parts: PackedStringArray = []
	var lines: Array = triple.get("required_lines", [])

	for line_data: Dictionary in lines:
		var category := _format_title(str(line_data.get("category", "")))
		var line_title := str(line_data.get("title", line_data.get("id", "")))
		var cur := int(line_data.get("current_level", 0))
		var max_lvl := int(line_data.get("max_level", 1))
		var state := "MAXED" if bool(line_data.get("maxed", false)) else ("SELECTED" if bool(line_data.get("selected", false)) else "MISSING")
		line_parts.append("%s: %s  %d/%d  %s" % [category, line_title, cur, max_lvl, state])

	var lines_str := ""
	if not line_parts.is_empty():
		lines_str = "\n[font_size=14][color=#cfd6e6]Required lines:[/color]\n- %s[/font_size]" % "\n- ".join(line_parts)

	return "[center][b][color=#ffd75c]%s[/color][/b]\n[font_size=23][b]%s[/b][/font_size]\n[color=#aeb9ce]%s target: %s[/color][/center]\n%s%s" % [
		type_label,
		title,
		_format_title(target_type),
		_format_title(target_id),
		description,
		lines_str,
	]


func _format_title(value: String) -> String:
	var words := value.replace("_", " ").split(" ", false)
	for index in range(words.size()):
		words[index] = str(words[index]).capitalize()
	return " ".join(words)


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.07, 0.88)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(overlay)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.08
	panel.anchor_top = 0.06
	panel.anchor_right = 0.92
	panel.anchor_bottom = 0.94
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var title_label := Label.new()
	title_label.text = "OVERDRIVE READY"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 26)
	title_label.modulate = Color(1.0, 0.88, 0.18, 1.0)
	box.add_child(title_label)

	var subtitle := Label.new()
	subtitle.text = "Choose one evolution to transform an attack, active skill, or passive for this run."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(subtitle)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)

	var options_box := VBoxContainer.new()
	options_box.add_theme_constant_override("separation", 10)
	options_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(options_box)

	for _index in range(3):
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(0.0, 168.0)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.hide()
		options_box.add_child(card)

		var card_margin := MarginContainer.new()
		card_margin.add_theme_constant_override("margin_left", 12)
		card_margin.add_theme_constant_override("margin_top", 10)
		card_margin.add_theme_constant_override("margin_right", 12)
		card_margin.add_theme_constant_override("margin_bottom", 10)
		card.add_child(card_margin)

		var card_box := VBoxContainer.new()
		card_box.add_theme_constant_override("separation", 8)
		card_margin.add_child(card_box)

		var label := RichTextLabel.new()
		label.bbcode_enabled = true
		label.fit_content = true
		label.scroll_active = false
		label.custom_minimum_size = Vector2(0.0, 108.0)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_box.add_child(label)

		var button := Button.new()
		button.custom_minimum_size = Vector2(0.0, 38.0)
		button.pressed.connect(_on_option_pressed.bind(button))
		card_box.add_child(button)

		_option_cards.append(card)
		_option_labels.append(label)
		_option_buttons.append(button)


func _on_option_pressed(button: Button) -> void:
	var evolution_id := str(button.get_meta("evolution_id", ""))
	if evolution_id.is_empty():
		return
	hide()
	evolution_chosen.emit(evolution_id)
