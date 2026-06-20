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
	var rarity := str(option.get("rarity", "common")).to_upper()
	var archetype := str(option.get("archetype", ""))
	var is_synergy := bool(option.get("is_synergy", false))
	var is_build_defining := bool(option.get("is_build_defining", false))
	var is_passive := bool(option.get("is_passive", false))
	var title := str(option.get("title", "Upgrade"))
	var level := int(option.get("level", 0))
	var max_level := int(option.get("max_level", 1))
	var description := str(option.get("description", ""))

	var rarity_line := "[%s]" % rarity
	if not archetype.is_empty():
		rarity_line = "[%s]  [%s]" % [rarity, archetype.to_upper()]

	var markers := ""
	if is_passive:
		markers = "  PASSIVE"
	if is_synergy:
		markers = "  ★ SYNERGY"
	if is_build_defining:
		markers = "%s  ◆ BUILD DEFINING" % markers

	var level_line := "Lv %d  →  %d / %d" % [level, mini(level + 1, max_level), max_level]

	return "%s\n%s%s\n%s\n%s" % [title, rarity_line, markers, level_line, description]


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
