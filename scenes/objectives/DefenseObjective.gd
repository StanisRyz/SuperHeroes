extends Node2D

signal health_changed(current_hp: int, max_hp: int)
signal objective_destroyed

@export var max_health: int = 300
@export var display_name: String = "Lab Reactor"
@export var damage_per_enemy_per_second: float = 15.0
@export var contact_radius: float = 48.0

var current_health: int = 300
var _enemies_in_contact: Array = []
var _damage_accumulator: float = 0.0
var _destroyed: bool = false
var _label: Label = null
var _body_poly: Polygon2D = null


func _ready() -> void:
	current_health = max_health


func setup(hp: int, disp_name: String, dmg_rate: float = 15.0) -> void:
	max_health = hp
	current_health = hp
	display_name = disp_name
	damage_per_enemy_per_second = dmg_rate
	_build_visuals()


func _build_visuals() -> void:
	for child in get_children():
		child.queue_free()
	_label = null
	_body_poly = null

	# Outer shell
	_body_poly = Polygon2D.new()
	_body_poly.name = "BodyPoly"
	_body_poly.polygon = PackedVector2Array([
		Vector2(-30, -30), Vector2(30, -30),
		Vector2(30, 30), Vector2(-30, 30),
	])
	_body_poly.color = Color(0.15, 0.55, 0.95, 0.92)
	add_child(_body_poly)

	# Inner core
	var core := Polygon2D.new()
	core.name = "CorePoly"
	core.polygon = PackedVector2Array([
		Vector2(-14, -14), Vector2(14, -14),
		Vector2(14, 14), Vector2(-14, 14),
	])
	core.color = Color(0.75, 0.92, 1.0, 0.95)
	add_child(core)

	# HP label
	_label = Label.new()
	_label.name = "HpLabel"
	_label.position = Vector2(-44, -62)
	_label.add_theme_font_size_override("font_size", 13)
	_label.modulate = Color(0.7, 0.92, 1.0)
	add_child(_label)
	_refresh_label()

	# Enemy contact area
	var contact_area := Area2D.new()
	contact_area.name = "ContactArea"
	contact_area.collision_layer = 0
	contact_area.collision_mask = 2  # enemies layer
	contact_area.body_entered.connect(_on_enemy_entered)
	contact_area.body_exited.connect(_on_enemy_exited)
	add_child(contact_area)

	var shape_node := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = contact_radius
	shape_node.shape = circle
	contact_area.add_child(shape_node)


func _process(delta: float) -> void:
	if _destroyed:
		return

	_enemies_in_contact = _enemies_in_contact.filter(
		func(e: Node) -> bool: return is_instance_valid(e) and not e.get("is_final_boss")
	)

	if not _enemies_in_contact.is_empty():
		_damage_accumulator += damage_per_enemy_per_second * float(_enemies_in_contact.size()) * delta
		if _damage_accumulator >= 1.0:
			var dmg := int(_damage_accumulator)
			_damage_accumulator -= float(dmg)
			_apply_damage(dmg)


func _apply_damage(amount: int) -> void:
	if _destroyed:
		return
	current_health = max(0, current_health - amount)
	_refresh_label()
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		_destroyed = true
		_refresh_label()
		objective_destroyed.emit()


func _refresh_label() -> void:
	if _label == null or not is_instance_valid(_label):
		return
	if _destroyed or current_health <= 0:
		_label.text = "%s\nDESTROYED" % display_name
		_label.modulate = Color(1.0, 0.2, 0.2)
		if _body_poly != null and is_instance_valid(_body_poly):
			_body_poly.color = Color(0.35, 0.10, 0.10, 0.75)
		return
	var ratio := float(current_health) / float(max_health) if max_health > 0 else 1.0
	_label.text = "%s\n%d / %d HP" % [display_name, current_health, max_health]
	if ratio <= 0.30:
		_label.modulate = Color(1.0, 0.35, 0.1)
		if _body_poly != null and is_instance_valid(_body_poly):
			_body_poly.color = Color(0.55, 0.20, 0.10, 0.9)
	elif ratio <= 0.60:
		_label.modulate = Color(1.0, 0.82, 0.2)
		if _body_poly != null and is_instance_valid(_body_poly):
			_body_poly.color = Color(0.45, 0.45, 0.15, 0.9)
	else:
		_label.modulate = Color(0.7, 0.92, 1.0)
		if _body_poly != null and is_instance_valid(_body_poly):
			_body_poly.color = Color(0.15, 0.55, 0.95, 0.92)


func _on_enemy_entered(body: Node) -> void:
	if body != null and not body.get("is_final_boss") and body not in _enemies_in_contact:
		_enemies_in_contact.append(body)


func _on_enemy_exited(body: Node) -> void:
	_enemies_in_contact.erase(body)
