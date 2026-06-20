extends StaticBody2D

signal portal_destroyed(portal: Node)
signal health_changed(current_hp: int, max_hp: int)

@export var max_health: int = 150
@export var display_name: String = "Dark Portal"

var current_health: int = 150
var _destroyed: bool = false
var _label: Label = null
var _body_poly: Polygon2D = null
var _pulse_time: float = 0.0


func _ready() -> void:
	current_health = max_health
	collision_layer = 2  # enemies layer — detected by player autoattack and projectiles
	collision_mask = 0   # portal does not physically detect others
	add_to_group("enemies")  # projectile hit guards use this group


func setup(hp: int, disp_name: String) -> void:
	max_health = hp
	current_health = hp
	display_name = disp_name
	_build_visuals()


func _build_visuals() -> void:
	for child in get_children():
		child.queue_free()
	_label = null
	_body_poly = null

	# Octagonal portal shape
	_body_poly = Polygon2D.new()
	_body_poly.name = "BodyPoly"
	_body_poly.polygon = PackedVector2Array([
		Vector2(0, -36),
		Vector2(25, -25),
		Vector2(36, 0),
		Vector2(25, 25),
		Vector2(0, 36),
		Vector2(-25, 25),
		Vector2(-36, 0),
		Vector2(-25, -25),
	])
	_body_poly.color = Color(0.55, 0.05, 0.80, 0.92)
	add_child(_body_poly)

	# Inner glow ring
	var inner := Polygon2D.new()
	inner.name = "InnerPoly"
	inner.polygon = PackedVector2Array([
		Vector2(0, -18),
		Vector2(13, -13),
		Vector2(18, 0),
		Vector2(13, 13),
		Vector2(0, 18),
		Vector2(-13, 13),
		Vector2(-18, 0),
		Vector2(-13, -13),
	])
	inner.color = Color(0.85, 0.3, 1.0, 0.85)
	add_child(inner)

	# HP label
	_label = Label.new()
	_label.name = "HpLabel"
	_label.position = Vector2(-42, -62)
	_label.add_theme_font_size_override("font_size", 13)
	_label.modulate = Color(0.9, 0.5, 1.0)
	add_child(_label)
	_refresh_label()

	# Physics collision shape
	var shape_node := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 34.0
	shape_node.shape = circle
	add_child(shape_node)


func _process(delta: float) -> void:
	if _destroyed:
		return
	_pulse_time += delta * 2.0
	if _body_poly != null and is_instance_valid(_body_poly):
		var pulse := 0.06 * sin(_pulse_time)
		_body_poly.color = Color(
			clampf(0.55 + pulse, 0.0, 1.0),
			clampf(0.05, 0.0, 1.0),
			clampf(0.80 + pulse * 0.5, 0.0, 1.0),
			0.92
		)


func take_damage(amount: int) -> void:
	if _destroyed or amount <= 0:
		return
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	_refresh_label()
	if current_health <= 0:
		_destroyed = true
		_on_portal_destroyed()


func _on_portal_destroyed() -> void:
	_refresh_label()
	if _body_poly != null and is_instance_valid(_body_poly):
		_body_poly.color = Color(0.25, 0.05, 0.30, 0.5)
	set_process(false)
	portal_destroyed.emit(self)


func _refresh_label() -> void:
	if _label == null or not is_instance_valid(_label):
		return
	if _destroyed or current_health <= 0:
		_label.text = "%s\nDESTROYED" % display_name
		_label.modulate = Color(0.5, 0.5, 0.5)
		return
	var ratio := float(current_health) / float(max_health) if max_health > 0 else 1.0
	_label.text = "%s\n%d / %d HP" % [display_name, current_health, max_health]
	if ratio <= 0.30:
		_label.modulate = Color(1.0, 0.35, 0.35)
	elif ratio <= 0.60:
		_label.modulate = Color(1.0, 0.82, 0.3)
	else:
		_label.modulate = Color(0.9, 0.5, 1.0)
