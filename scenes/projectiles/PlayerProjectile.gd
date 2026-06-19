extends Area2D

@export var speed: float = 520.0
@export var max_lifetime: float = 2.0
@export var hit_radius: float = 10.0
@export var hit_spark_scene: PackedScene
@export var explosion_burst_scene: PackedScene
@export var debug_hits: bool = false

var damage: int
var target: Node2D
var direction := Vector2.RIGHT
var audio_manager: Node
var pierce_remaining: int = 0
var size_multiplier: float = 1.0
var explosion_radius: float = 0.0
var explosion_damage_multiplier: float = 0.6
var homing_enabled: bool = true
var attack_id: int = -1
var projectile_index: int = 0
var _lifetime := 0.0
# Per projectile instance only: prevents one projectile from damaging the same enemy twice,
# but separate projectiles can still damage the same enemy independently.
var _hit_enemies: Array[Node] = []

@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	var circle := collision_shape.shape as CircleShape2D if collision_shape != null else null
	if circle != null:
		circle.radius = hit_radius


func setup(origin: Vector2, new_target: Node2D, new_damage: int, extra_data: Dictionary = {}) -> void:
	global_position = origin
	target = new_target
	damage = new_damage
	if extra_data.has("speed"):
		speed = float(extra_data["speed"])
	if extra_data.has("pierce"):
		pierce_remaining = maxi(int(extra_data["pierce"]), 0)
	if extra_data.has("size_multiplier"):
		size_multiplier = maxf(float(extra_data["size_multiplier"]), 0.2)
	if extra_data.has("explosion_radius"):
		explosion_radius = maxf(float(extra_data["explosion_radius"]), 0.0)
	if extra_data.has("explosion_damage_multiplier"):
		explosion_damage_multiplier = maxf(float(extra_data["explosion_damage_multiplier"]), 0.0)
	if extra_data.has("homing_enabled"):
		homing_enabled = bool(extra_data["homing_enabled"])
	if extra_data.has("attack_id"):
		attack_id = int(extra_data["attack_id"])
	if extra_data.has("projectile_index"):
		projectile_index = int(extra_data["projectile_index"])

	if is_instance_valid(target):
		var offset := target.global_position - global_position
		if not offset.is_zero_approx():
			direction = offset.normalized()
	if extra_data.has("direction"):
		var extra_direction: Vector2 = extra_data["direction"]
		if not extra_direction.is_zero_approx():
			direction = extra_direction.normalized()

	_apply_size_multiplier()


func setup_audio_manager(new_audio_manager: Node) -> void:
	audio_manager = new_audio_manager


func _physics_process(delta: float) -> void:
	_lifetime += delta
	if _lifetime >= max_lifetime:
		queue_free()
		return

	if homing_enabled and is_instance_valid(target):
		var offset := target.global_position - global_position
		if not offset.is_zero_approx():
			direction = offset.normalized()

	if not direction.is_zero_approx():
		global_position += direction.normalized() * speed * delta
		rotation = direction.angle()


func _on_body_entered(body: Node2D) -> void:
	if not _try_hit_enemy(body):
		return

	if _should_destroy_after_hit():
		queue_free()
	else:
		pierce_remaining -= 1


func _try_hit_enemy(enemy: Node2D) -> bool:
	if not _is_valid_enemy(enemy) or _hit_enemies.has(enemy):
		return false

	_register_enemy_hit(enemy)
	enemy.take_damage(damage)
	if debug_hits:
		print("PlayerProjectile hit attack_id=%d projectile_index=%d enemy=%s damage=%d" % [
			attack_id,
			projectile_index,
			enemy.name,
			damage,
		])
	_spawn_hit_spark(enemy.global_position)
	_apply_explosion(enemy)
	if audio_manager != null and audio_manager.has_method("play_projectile_hit"):
		audio_manager.play_projectile_hit()

	return true


func _register_enemy_hit(enemy: Node2D) -> void:
	_hit_enemies.append(enemy)


func _should_destroy_after_hit() -> bool:
	return pierce_remaining <= 0


func _spawn_hit_spark(world_position: Vector2) -> void:
	if hit_spark_scene == null:
		return

	var spark_node := hit_spark_scene.instantiate()
	if not spark_node is Node2D:
		push_warning("HitSpark scene root must be Node2D.")
		spark_node.queue_free()
		return

	var spark := spark_node as Node2D
	var effect_parent := get_parent()
	if effect_parent == null:
		spark.queue_free()
		return

	effect_parent.add_child(spark)
	if spark.has_method("play"):
		spark.play(world_position)
	else:
		spark.global_position = world_position


func _is_valid_enemy(body: Node) -> bool:
	return (
		body is Node2D
		and is_instance_valid(body)
		and not body.is_queued_for_deletion()
		and body.has_method("take_damage")
		and (body.is_in_group("enemies") or body.has_method("die"))
	)


func _apply_size_multiplier() -> void:
	scale = Vector2.ONE * size_multiplier
	var circle := collision_shape.shape as CircleShape2D if collision_shape != null else null
	if circle != null:
		circle.radius = hit_radius


func _apply_explosion(direct_enemy: Node2D) -> void:
	if explosion_radius <= 0.0:
		return

	var secondary_damage := maxi(roundi(float(damage) * explosion_damage_multiplier), 1)
	for node in get_tree().get_nodes_in_group("enemies"):
		if node == direct_enemy or _hit_enemies.has(node) or not _is_valid_enemy(node):
			continue

		var enemy := node as Node2D
		if enemy != null and direct_enemy.global_position.distance_to(enemy.global_position) <= explosion_radius:
			_hit_enemies.append(enemy)
			enemy.take_damage(secondary_damage)

	_spawn_explosion_burst(direct_enemy.global_position)


func _spawn_explosion_burst(world_position: Vector2) -> void:
	if explosion_burst_scene == null:
		return

	var burst_node := explosion_burst_scene.instantiate()
	if not burst_node is Node2D:
		push_warning("ExplosionBurst scene root must be Node2D.")
		burst_node.queue_free()
		return

	var burst := burst_node as Node2D
	var effect_parent := get_parent()
	if effect_parent == null:
		burst.queue_free()
		return

	effect_parent.add_child(burst)
	if burst.has_method("play"):
		burst.play(world_position, explosion_radius)
	else:
		burst.global_position = world_position
