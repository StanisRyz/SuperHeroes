extends Node

signal settings_changed

const SETTINGS_PATH := "user://settings.cfg"
const SECTION := "settings"

var _settings := {
	"master_volume": 1.0,
	"music_volume": 0.8,
	"sfx_volume": 1.0,
	"mute_all": false,
	"force_mobile_controls": false,
	"screen_shake_enabled": true,
	"screen_shake_intensity": 1.0,
	"floating_text_enabled": true,
	"impact_flash_enabled": true,
}


func load_settings() -> void:
	var config := ConfigFile.new()
	var error := config.load(SETTINGS_PATH)
	if error != OK:
		return

	for key in _settings.keys():
		_settings[key] = config.get_value(SECTION, key, _settings[key])

	settings_changed.emit()


func save_settings() -> void:
	var config := ConfigFile.new()
	for key in _settings.keys():
		config.set_value(SECTION, key, _settings[key])

	config.save(SETTINGS_PATH)


func get_setting(key: String, default_value = null):
	return _settings.get(key, default_value)


func set_setting(key: String, value) -> void:
	if not _settings.has(key):
		push_warning("Unknown setting key: %s" % key)
		return

	if _settings[key] == value:
		return

	_settings[key] = value
	settings_changed.emit()
	save_settings()


func apply_to_tree(root: Node) -> void:
	if root == null:
		return

	if root.has_method("apply_settings"):
		root.apply_settings(self)

	for child in root.get_children():
		apply_to_tree(child)
