extends Node

const UIStateColors = preload("res://scenes/ui/UIStateColors.gd")

@export var floating_text_scene: PackedScene


# --- Typed helpers ---

func spawn_damage_text(amount: int, world_position: Vector2, is_critical: bool = false) -> void:
	if is_critical:
		_spawn_text("CRIT -%d" % amount, world_position, Color(1.0, 0.3, 0.2, 1.0), 0.75)
	else:
		_spawn_text("-%d" % amount, world_position, UIStateColors.danger_color(), 0.55)


func spawn_heal_text(amount: int, world_position: Vector2) -> void:
	_spawn_text("+%d HP" % amount, world_position, UIStateColors.positive_color(), 0.65)


func spawn_powerup_text(powerup_id: String, world_position: Vector2) -> void:
	var label := _powerup_label(powerup_id)
	var color := _powerup_color(powerup_id)
	_spawn_text(label, world_position, color, 0.7)


func spawn_status_text(text: String, world_position: Vector2) -> void:
	_spawn_text(text, world_position, UIStateColors.ready_color(), 0.65)


# --- Legacy methods kept for backward-compatibility ---

func show_damage(amount: int, world_position: Vector2) -> void:
	spawn_damage_text(amount, world_position, false)


func show_pickup(text: String, world_position: Vector2) -> void:
	_spawn_text(text, world_position, UIStateColors.positive_color(), 0.65)


# --- Internal ---

func _spawn_text(text: String, world_position: Vector2, color: Color = Color.WHITE, duration: float = 0.6) -> void:
	if floating_text_scene == null:
		push_warning("FloatingTextSpawner is missing floating_text_scene.")
		return

	var text_node := floating_text_scene.instantiate()
	if not text_node is Node2D:
		push_warning("FloatingText scene root must be Node2D.")
		text_node.queue_free()
		return

	add_child(text_node)

	var label: Label = text_node.get_node_or_null("Label")
	if label != null:
		label.modulate = color

	if text_node.has_method("play"):
		text_node.play(text, world_position, duration)
	else:
		text_node.global_position = world_position


func _powerup_label(powerup_id: String) -> String:
	match powerup_id:
		"heal": return "+HP"
		"shield": return "SHIELD"
		"bomb": return "BOMB"
		"magnet_burst": return "MAGNET"
		"move_speed_boost": return "SPEED"
		"attack_speed_boost": return "HASTE"
		"evolved": return "EVOLVED"
		_: return powerup_id.to_upper()


func _powerup_color(powerup_id: String) -> Color:
	match powerup_id:
		"heal": return UIStateColors.positive_color()
		"shield": return Color(0.4, 0.7, 1.0, 1.0)
		"bomb": return UIStateColors.danger_color()
		"magnet_burst": return Color(0.8, 0.4, 1.0, 1.0)
		"move_speed_boost": return Color(0.3, 1.0, 0.9, 1.0)
		"attack_speed_boost": return Color(1.0, 0.9, 0.3, 1.0)
		"evolved": return Color(1.0, 0.85, 0.2, 1.0)
		_: return Color.WHITE
