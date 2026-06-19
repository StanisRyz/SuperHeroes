extends CanvasLayer

var _tracked_enemy: Node = null

@onready var _name_label: Label = $VBox/NameLabel
@onready var _hp_bar: ProgressBar = $VBox/HPBar
@onready var _hp_text: Label = $VBox/HPText

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
	_name_label.text = enemy.get("display_name") if enemy.get("display_name") else "Miniboss"
	var max_hp = enemy.get("max_health") if enemy.get("max_health") else 1
	var cur_hp = enemy.get("current_health") if enemy.get("current_health") else max_hp
	_hp_bar.max_value = max_hp
	_hp_bar.value = cur_hp
	_hp_text.text = "%d / %d" % [cur_hp, max_hp]
	$VBox.visible = true

func clear() -> void:
	if _tracked_enemy:
		_disconnect_enemy(_tracked_enemy)
		_tracked_enemy = null
	$VBox.visible = false

func _disconnect_enemy(enemy: Node) -> void:
	if enemy.has_signal("health_changed") and enemy.health_changed.is_connected(_on_health_changed):
		enemy.health_changed.disconnect(_on_health_changed)
	if enemy.has_signal("tree_exited") and enemy.tree_exited.is_connected(clear):
		enemy.tree_exited.disconnect(clear)

func _on_health_changed(current: int, maximum: int) -> void:
	_hp_bar.max_value = maximum
	_hp_bar.value = current
	_hp_text.text = "%d / %d" % [current, maximum]
