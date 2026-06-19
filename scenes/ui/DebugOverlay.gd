extends CanvasLayer

@onready var label: Label = $DebugLabel

func _ready() -> void:
	hide()
	if label != null:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_debug_enabled(enabled: bool) -> void:
	visible = enabled
