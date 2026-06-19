extends CanvasLayer

@onready var label: Label = $DebugLabel

func _ready() -> void:
	hide()
	if label != null:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_debug_enabled(enabled: bool) -> void:
	if enabled:
		show()
	else:
		hide()


func flash_debug_toggle_feedback() -> void:
	if label == null:
		return
	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 0.3, 0.1)
	tween.tween_property(label, "modulate:a", 1.0, 0.15)
