extends Node

signal preferences_loaded
signal preferences_saved
signal last_choices_changed(hero_id: String, stage_id: String)

const SAVE_PATH := "user://superheroes_user_preferences.json"
const SAVE_VERSION := 1

var _data: Dictionary = {}


func load_preferences() -> void:
	_data = _get_defaults()
	if not FileAccess.file_exists(SAVE_PATH):
		preferences_loaded.emit()
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("UserPreferencesManager: cannot open preferences file. Using defaults.")
		preferences_loaded.emit()
		return

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(text) != OK:
		push_warning("UserPreferencesManager: corrupt preferences file. Using defaults.")
		preferences_loaded.emit()
		return

	var parsed = json.get_data()
	if not parsed is Dictionary:
		push_warning("UserPreferencesManager: unexpected preferences format. Using defaults.")
		preferences_loaded.emit()
		return

	_merge_with_defaults(parsed)
	preferences_loaded.emit()


func save_preferences() -> void:
	if _data.is_empty():
		_data = _get_defaults()

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("UserPreferencesManager: cannot write preferences file.")
		return

	file.store_string(JSON.stringify(_data, "\t"))
	file.close()
	preferences_saved.emit()


func reset_preferences() -> void:
	_data = _get_defaults()
	save_preferences()
	last_choices_changed.emit(get_last_hero_id(), get_last_stage_id())


func get_last_hero_id() -> String:
	return str(_data.get("last_hero_id", ""))


func set_last_hero_id(hero_id: String) -> void:
	if _data.is_empty():
		_data = _get_defaults()
	if get_last_hero_id() == hero_id:
		return
	_data["last_hero_id"] = hero_id
	save_preferences()
	last_choices_changed.emit(get_last_hero_id(), get_last_stage_id())


func get_last_stage_id() -> String:
	return str(_data.get("last_stage_id", ""))


func set_last_stage_id(stage_id: String) -> void:
	if _data.is_empty():
		_data = _get_defaults()
	if get_last_stage_id() == stage_id:
		return
	_data["last_stage_id"] = stage_id
	save_preferences()
	last_choices_changed.emit(get_last_hero_id(), get_last_stage_id())


func set_last_choices(hero_id: String, stage_id: String) -> void:
	if _data.is_empty():
		_data = _get_defaults()
	var changed := get_last_hero_id() != hero_id or get_last_stage_id() != stage_id
	_data["last_hero_id"] = hero_id
	_data["last_stage_id"] = stage_id
	if changed:
		save_preferences()
		last_choices_changed.emit(get_last_hero_id(), get_last_stage_id())


func get_preferences_summary() -> Dictionary:
	if _data.is_empty():
		_data = _get_defaults()
	return _data.duplicate(true)


func _get_defaults() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"last_hero_id": "",
		"last_stage_id": "",
		"last_opened_menu": "",
		"show_help_on_first_run": false,
	}


func _merge_with_defaults(parsed: Dictionary) -> void:
	var defaults := _get_defaults()
	_data = defaults.duplicate(true)
	for key in parsed:
		if _data.has(key):
			_data[key] = parsed[key]
	_data["version"] = SAVE_VERSION
	_data["last_hero_id"] = str(_data.get("last_hero_id", ""))
	_data["last_stage_id"] = str(_data.get("last_stage_id", ""))
	_data["last_opened_menu"] = str(_data.get("last_opened_menu", ""))
	_data["show_help_on_first_run"] = bool(_data.get("show_help_on_first_run", false))
