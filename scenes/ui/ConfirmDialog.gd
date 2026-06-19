extends CanvasLayer

signal confirmed(action_id: String)
signal cancelled(action_id: String)

var _action_id: String = ""

@onready var title_label: Label = get_node_or_null("Root/Panel/Margin/VBoxContainer/TitleLabel")
@onready var message_label: Label = get_node_or_null("Root/Panel/Margin/VBoxContainer/MessageLabel")
@onready var confirm_button: Button = get_node_or_null("Root/Panel/Margin/VBoxContainer/ButtonRow/ConfirmButton")
@onready var cancel_button: Button = get_node_or_null("Root/Panel/Margin/VBoxContainer/ButtonRow/CancelButton")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

	if confirm_button != null and not confirm_button.pressed.is_connected(_on_confirm_pressed):
		confirm_button.pressed.connect(_on_confirm_pressed)
	if cancel_button != null and not cancel_button.pressed.is_connected(_on_cancel_pressed):
		cancel_button.pressed.connect(_on_cancel_pressed)


func open(action_id: String, title: String, message: String, confirm_text: String = "Confirm", cancel_text: String = "Cancel") -> void:
	if visible and _action_id == action_id:
		return

	_action_id = action_id
	if title_label != null:
		title_label.text = title
	if message_label != null:
		message_label.text = message
	if confirm_button != null:
		confirm_button.text = confirm_text
		confirm_button.disabled = false
	if cancel_button != null:
		cancel_button.text = cancel_text
		cancel_button.disabled = false

	show()
	if cancel_button != null:
		cancel_button.grab_focus()


func close() -> void:
	hide()


func cancel() -> void:
	if not visible:
		return
	var cancelled_action := _action_id
	close()
	cancelled.emit(cancelled_action)


func is_open() -> bool:
	return visible


func get_action_id() -> String:
	return _action_id


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
			cancel()
			get_viewport().set_input_as_handled()


func _on_confirm_pressed() -> void:
	if not visible:
		return
	var confirmed_action := _action_id
	close()
	confirmed.emit(confirmed_action)


func _on_cancel_pressed() -> void:
	cancel()
