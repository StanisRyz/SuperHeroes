extends Area2D

@export var experience_value: int = 1
@export var pickup_radius: float = 16.0
@export var magnet_radius: float = 140.0
@export var magnet_speed: float = 420.0

var target_player: Node2D
var audio_manager: Node
var _picked_up := false

@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	var circle := collision_shape.shape as CircleShape2D if collision_shape != null else null
	if circle != null:
		circle.radius = pickup_radius


func _physics_process(delta: float) -> void:
	if _picked_up:
		return

	_update_target_player()
	if not is_instance_valid(target_player):
		return

	var offset := target_player.global_position - global_position
	if offset.is_zero_approx():
		return

	global_position += offset.normalized() * magnet_speed * delta


func _on_body_entered(body: Node2D) -> void:
	if _picked_up or not body.has_method("add_experience"):
		return

	_picked_up = true
	if audio_manager != null and audio_manager.has_method("play_pickup"):
		audio_manager.play_pickup()
	body.add_experience(experience_value)
	queue_free()


func setup_audio_manager(new_audio_manager: Node) -> void:
	audio_manager = new_audio_manager


func _update_target_player() -> void:
	if _is_valid_magnet_target(target_player):
		return

	target_player = null
	for node in get_tree().get_nodes_in_group("player"):
		if not _is_valid_magnet_target(node):
			continue

		var player_node := node as Node2D
		if player_node != null and global_position.distance_to(player_node.global_position) <= magnet_radius:
			target_player = player_node
			return


func _is_valid_magnet_target(node: Node) -> bool:
	return (
		node is Node2D
		and is_instance_valid(node)
		and not node.is_queued_for_deletion()
		and (not node.has_method("is_dead") or not node.is_dead())
	)
