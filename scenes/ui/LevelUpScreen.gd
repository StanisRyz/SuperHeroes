extends CanvasLayer

signal upgrade_selected(upgrade_id: String)

const UIStateColors = preload("res://scenes/ui/UIStateColors.gd")

var audio_manager: Node

@onready var option_buttons: Array[Button] = [
	$Root/Panel/VBoxContainer/OptionButton1,
	$Root/Panel/VBoxContainer/OptionButton2,
	$Root/Panel/VBoxContainer/OptionButton3
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	hide()
	for index in option_buttons.size():
		option_buttons[index].pressed.connect(_on_option_pressed.bind(index))


func show_options(options: Array[Dictionary]) -> void:
	for index in option_buttons.size():
		var button := option_buttons[index]
		if index >= options.size():
			button.hide()
			button.set_meta("upgrade_id", "")
			button.modulate = Color.WHITE
			continue

		var option := options[index]
		button.text = _format_option_text(option)
		button.set_meta("upgrade_id", option.get("id", ""))
		button.modulate = _get_rarity_modulate(str(option.get("rarity", "common")))
		button.show()

	show()


func setup_audio_manager(new_audio_manager: Node) -> void:
	audio_manager = new_audio_manager


func _format_option_text(option: Dictionary) -> String:
	var lines: PackedStringArray = []
	lines.append(str(option.get("title", "Upgrade")).to_upper())
	lines.append("[%s] [%s]" % [str(option.get("rarity", "common")).to_upper(), str(option.get("category", "")).to_upper()])
	lines.append("Level %d -> %d/%d" % [int(option.get("level", 0)), int(option.get("next_level", 1)), int(option.get("max_level", 5))])
	lines.append(str(option.get("effect_comparison", option.get("next_effect_summary", ""))))
	var evolution_title := str(option.get("evolution_title", ""))
	if not evolution_title.is_empty():
		lines.append("Related evolution: %s" % evolution_title)
		lines.append("Progress: %d/15 -> %d/15" % [int(option.get("current_progress", 0)), int(option.get("projected_progress", 0))])
		var requirements: PackedStringArray = []
		for line: Dictionary in option.get("related_lines", []):
			if str(line.get("upgrade_id", "")) != str(option.get("id", "")):
				requirements.append("%s %d/%d" % [str(line.get("title", "")), int(line.get("current_level", 0)), int(line.get("required_level", 5))])
		if not requirements.is_empty(): lines.append("Requirements: " + " | ".join(requirements))
	if bool(option.get("is_new_line", false)): lines.append("NEW LINE")
	if bool(option.get("completes_line", false)): lines.append("COMPLETES LINE")
	if bool(option.get("completes_evolution", false)): lines.append("COMPLETES EVOLUTION")
	return "\n".join(lines)


func _get_rarity_modulate(rarity: String) -> Color:
	match rarity.to_lower():
		"rare":
			return Color(0.75, 0.88, 1.0, 1.0)
		"epic":
			return Color(0.9, 0.75, 1.0, 1.0)
		"legendary":
			return Color(1.0, 0.92, 0.55, 1.0)
		_:
			return Color.WHITE


func _on_option_pressed(index: int) -> void:
	var button := option_buttons[index]
	var upgrade_id := str(button.get_meta("upgrade_id", ""))
	if upgrade_id.is_empty():
		return

	if audio_manager != null and audio_manager.has_method("play_ui_click"):
		audio_manager.play_ui_click()
	hide()
	upgrade_selected.emit(upgrade_id)
