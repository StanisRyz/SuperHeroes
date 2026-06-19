extends CanvasLayer

signal closed

var settings_manager: Node
var audio_manager: Node
var _is_syncing := false

@onready var master_slider: HSlider = get_node_or_null("Root/Panel/VBoxContainer/MasterRow/MasterSlider")
@onready var music_slider: HSlider = get_node_or_null("Root/Panel/VBoxContainer/MusicRow/MusicSlider")
@onready var sfx_slider: HSlider = get_node_or_null("Root/Panel/VBoxContainer/SfxRow/SfxSlider")
@onready var mute_checkbox: CheckBox = get_node_or_null("Root/Panel/VBoxContainer/MuteCheckbox")
@onready var mobile_checkbox: CheckBox = get_node_or_null("Root/Panel/VBoxContainer/MobileCheckbox")
@onready var shake_checkbox: CheckBox = get_node_or_null("Root/Panel/VBoxContainer/ShakeCheckbox")
@onready var back_button: Button = get_node_or_null("Root/Panel/VBoxContainer/BackButton")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

	if master_slider != null:
		master_slider.value_changed.connect(_on_master_volume_changed)
	if music_slider != null:
		music_slider.value_changed.connect(_on_music_volume_changed)
	if sfx_slider != null:
		sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	if mute_checkbox != null:
		mute_checkbox.toggled.connect(_on_mute_toggled)
	if mobile_checkbox != null:
		mobile_checkbox.toggled.connect(_on_mobile_toggled)
	if shake_checkbox != null:
		shake_checkbox.toggled.connect(_on_shake_toggled)
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)


func setup(new_settings_manager: Node, new_audio_manager: Node = null) -> void:
	settings_manager = new_settings_manager
	audio_manager = new_audio_manager

	if settings_manager != null and settings_manager.has_signal("settings_changed") and not settings_manager.settings_changed.is_connected(_sync_from_settings):
		settings_manager.settings_changed.connect(_sync_from_settings)

	_sync_from_settings()


func open() -> void:
	_sync_from_settings()
	show()
	if back_button != null:
		back_button.grab_focus()


func close() -> void:
	hide()
	closed.emit()


func _sync_from_settings() -> void:
	if settings_manager == null:
		return

	_is_syncing = true
	if master_slider != null:
		master_slider.value = float(settings_manager.get_setting("master_volume", 1.0))
	if music_slider != null:
		music_slider.value = float(settings_manager.get_setting("music_volume", 0.8))
	if sfx_slider != null:
		sfx_slider.value = float(settings_manager.get_setting("sfx_volume", 1.0))
	if mute_checkbox != null:
		mute_checkbox.button_pressed = bool(settings_manager.get_setting("mute_all", false))
	if mobile_checkbox != null:
		mobile_checkbox.button_pressed = bool(settings_manager.get_setting("force_mobile_controls", false))
	if shake_checkbox != null:
		shake_checkbox.button_pressed = bool(settings_manager.get_setting("screen_shake_enabled", true))
	_is_syncing = false


func _set_setting(key: String, value) -> void:
	if _is_syncing or settings_manager == null:
		return

	settings_manager.set_setting(key, value)
	if audio_manager != null and audio_manager.has_method("apply_settings"):
		audio_manager.apply_settings()


func _on_master_volume_changed(value: float) -> void:
	_set_setting("master_volume", value)


func _on_music_volume_changed(value: float) -> void:
	_set_setting("music_volume", value)


func _on_sfx_volume_changed(value: float) -> void:
	_set_setting("sfx_volume", value)


func _on_mute_toggled(enabled: bool) -> void:
	_set_setting("mute_all", enabled)


func _on_mobile_toggled(enabled: bool) -> void:
	_set_setting("force_mobile_controls", enabled)


func _on_shake_toggled(enabled: bool) -> void:
	_set_setting("screen_shake_enabled", enabled)


func _on_back_pressed() -> void:
	if audio_manager != null and audio_manager.has_method("play_ui_click"):
		audio_manager.play_ui_click()
	close()
