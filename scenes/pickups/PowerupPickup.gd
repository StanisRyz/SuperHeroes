extends Area2D

@export var powerup_id: String = "heal"
@export var pickup_radius: float = 18.0
@export var magnet_radius: float = 120.0
@export var magnet_speed: float = 420.0

var target_player: Node2D
var powerup_manager: Node
var picked_up: bool = false

@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	var circle := collision_shape.shape as CircleShape2D if collision_shape != null else null
	if circle != null:
		circle.radius = pickup_radius


func setup(new_powerup_id: String, new_powerup_manager: Node) -> void:
	powerup_id = new_powerup_id
	powerup_manager = new_powerup_manager


func _physics_process(delta: float) -> void:
	if picked_up:
		return

	_update_target_player()
	if not is_instance_valid(target_player):
		return

	var offset := target_player.global_position - global_position
	if offset.is_zero_approx():
		return

	global_position += offset.normalized() * magnet_speed * delta


func _on_body_entered(body: Node2D) -> void:
	if picked_up:
		return
	if not body.is_in_group("player"):
		return

	picked_up = true
	if powerup_manager != null and powerup_manager.has_method("apply_powerup"):
		powerup_manager.apply_powerup(powerup_id, global_position)
	queue_free()


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
