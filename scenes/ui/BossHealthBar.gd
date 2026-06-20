extends CanvasLayer

var _tracked_enemy: Node = null
var _phase_label: Label = null

@onready var _vbox: VBoxContainer = $VBox
@onready var _name_label: Label = $VBox/NameLabel
@onready var _hp_bar: ProgressBar = $VBox/HPBar
@onready var _hp_text: Label = $VBox/HPText


func _ready() -> void:
	_phase_label = Label.new()
	_phase_label.name = "PhaseLabel"
	_phase_label.visible = false
	_phase_label.add_theme_font_size_override("font_size", 11)
	_vbox.add_child(_phase_label)


func track_enemy(enemy: Node) -> void:
	if _tracked_enemy:
		_disconnect_enemy(_tracked_enemy)
	_tracked_enemy = enemy
	if enemy == null:
		clear()
		return
	if enemy.has_signal("health_changed"):
		enemy.health_changed.connect(_on_health_changed)
	if enemy.has_signal("tree_exited"):
		enemy.tree_exited.connect(clear)
	var display: String = str(enemy.get("display_name")) if enemy.get("display_name") != null else "Final Boss"
	_name_label.text = display
	var max_hp: int = int(enemy.get("max_health")) if enemy.get("max_health") != null else 1
	var cur_hp: int = int(enemy.get("current_health")) if enemy.get("current_health") != null else max_hp
	_hp_bar.max_value = max_hp
	_hp_bar.value = cur_hp
	_hp_text.text = "%d / %d" % [cur_hp, max_hp]
	show_phase(1)
	_vbox.visible = true


func clear() -> void:
	if _tracked_enemy:
		_disconnect_enemy(_tracked_enemy)
		_tracked_enemy = null
	_vbox.visible = false
	if _phase_label != null:
		_phase_label.visible = false


func show_phase(phase: int) -> void:
	if _phase_label == null:
		return
	match phase:
		1: _phase_label.text = "Phase 1"
		2: _phase_label.text = "Phase 2 — Enraged"
		3: _phase_label.text = "Phase 3 — Desperation"
		_: _phase_label.text = ""
	match phase:
		2: _phase_label.modulate = Color(1.0, 0.7, 0.1)
		3: _phase_label.modulate = Color(1.0, 0.3, 0.1)
		_: _phase_label.modulate = Color.WHITE
	_phase_label.visible = _phase_label.text != ""


func _disconnect_enemy(enemy: Node) -> void:
	if enemy.has_signal("health_changed") and enemy.health_changed.is_connected(_on_health_changed):
		enemy.health_changed.disconnect(_on_health_changed)
	if enemy.has_signal("tree_exited") and enemy.tree_exited.is_connected(clear):
		enemy.tree_exited.disconnect(clear)


func _on_health_changed(current: int, maximum: int) -> void:
	_hp_bar.max_value = maximum
	_hp_bar.value = current
	_hp_text.text = "%d / %d" % [current, maximum]
