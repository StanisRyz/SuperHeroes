extends Area2D

@export var speed: float = 520.0
@export var max_lifetime: float = 2.0
@export var hit_radius: float = 10.0
@export var hit_spark_scene: PackedScene

var damage: int
var target: Node2D
var direction := Vector2.RIGHT
var audio_manager: Node
var _lifetime := 0.0
var _has_hit := false

@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	var circle := collision_shape.shape as CircleShape2D if collision_shape != null else null
	if circle != null:
		circle.radius = hit_radius


func setup(origin: Vector2, new_target: Node2D, new_damage: int) -> void:
	global_position = origin
	target = new_target
	damage = new_damage

	if is_instance_valid(target):
		var offset := target.global_position - global_position
		if not offset.is_zero_approx():
			direction = offset.normalized()


func setup_audio_manager(new_audio_manager: Node) -> void:
	audio_manager = new_audio_manager


func _physics_process(delta: float) -> void:
	_lifetime += delta
	if _lifetime >= max_lifetime:
		queue_free()
		return

	if is_instance_valid(target):
		var offset := target.global_position - global_position
		if not offset.is_zero_approx():
			direction = offset.normalized()

	if not direction.is_zero_approx():
		global_position += direction.normalized() * speed * delta
		rotation = direction.angle()


func _on_body_entered(body: Node2D) -> void:
	if _has_hit or not _is_valid_enemy(body):
		return

	_has_hit = true
	body.take_damage(damage)
	if audio_manager != null and audio_manager.has_method("play_projectile_hit"):
		audio_manager.play_projectile_hit()
	_spawn_hit_spark(body.global_position)
	queue_free()


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
