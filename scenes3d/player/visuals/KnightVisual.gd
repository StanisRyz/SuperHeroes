class_name KnightVisual
extends KayKitAnimatedVisual

## KayKit Knight presentation layer. It owns model setup, animation import, and equipment attachments.

const RIGHT_HAND_BONE: StringName = &"handslot.r"
const LEFT_HAND_BONE: StringName = &"handslot.l"

@export var sword_visual_scene: PackedScene
@export var shield_visual_scene: PackedScene

@onready var knight_model: Node3D = $ModelOffset/KnightModel


func _ready() -> void:
	var skeleton: Skeleton3D = initialize_kaykit_visual(knight_model)
	if skeleton == null:
		push_warning("KnightVisual: no Skeleton3D was found on the imported Knight model.")
		return
	attach_equipment(skeleton, RIGHT_HAND_BONE, sword_visual_scene, "SwordAttachment")
	attach_equipment(skeleton, LEFT_HAND_BONE, shield_visual_scene, "ShieldAttachment")
