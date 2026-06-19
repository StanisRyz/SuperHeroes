extends CanvasLayer

var _tween: Tween = null

@onready var _label: Label = $Panel/Label

func show_announcement(text: String, duration: float = 2.0) -> void:
	_label.text = text
	$Panel.modulate.a = 0.0
	$Panel.visible = true
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property($Panel, "modulate:a", 1.0, 0.3)
	_tween.tween_interval(duration - 0.6)
	_tween.tween_property($Panel, "modulate:a", 0.0, 0.3)
	_tween.tween_callback(func(): $Panel.visible = false)
