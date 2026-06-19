extends CanvasLayer

signal upgrade_selected(upgrade_id: String)

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
			continue

		var option := options[index]
		button.text = _format_option_text(option)
		button.set_meta("upgrade_id", option.get("id", ""))
		button.show()

	show()


func setup_audio_manager(new_audio_manager: Node) -> void:
	audio_manager = new_audio_manager


func _format_option_text(option: Dictionary) -> String:
	var rarity := str(option.get("rarity", "common")).to_upper()
	var title := str(option.get("title", "Upgrade"))
	var level := int(option.get("level", 0))
	var max_level := int(option.get("max_level", 1))
	var description := str(option.get("description", ""))

	return "[%s] %s\nLevel %d -> %d / %d\n%s" % [
		rarity,
		title,
		level,
		mini(level + 1, max_level),
		max_level,
		description
	]


func _on_option_pressed(index: int) -> void:
	var button := option_buttons[index]
	var upgrade_id := str(button.get_meta("upgrade_id", ""))
	if upgrade_id.is_empty():
		return

	if audio_manager != null and audio_manager.has_method("play_ui_click"):
		audio_manager.play_ui_click()
	upgrade_selected.emit(upgrade_id)
	hide()
