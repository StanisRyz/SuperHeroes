extends CanvasLayer

signal upgrade_selected(upgrade_id: String)

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
		button.text = "%s\n%s" % [option.get("title", "Upgrade"), option.get("description", "")]
		button.set_meta("upgrade_id", option.get("id", ""))
		button.show()

	show()


func _on_option_pressed(index: int) -> void:
	var button := option_buttons[index]
	var upgrade_id := str(button.get_meta("upgrade_id", ""))
	if upgrade_id.is_empty():
		return

	upgrade_selected.emit(upgrade_id)
	hide()
