class_name SkeletonWarriorVisual
extends KayKitAnimatedVisual

## Presentation-only KayKit Skeleton Warrior visual and weapon attachment.

const RIGHT_HAND_BONE: StringName = &"handslot.r"

@export var blade_visual_scene: PackedScene

@onready var skeleton_model: Node3D = $ModelOffset/SkeletonModel


func _ready() -> void:
	var skeleton: Skeleton3D = initialize_kaykit_visual(skeleton_model)
	if skeleton == null:
		push_warning("SkeletonWarriorVisual: no Skeleton3D was found on Skeleton_Warrior.")
		return
	attach_equipment(skeleton, RIGHT_HAND_BONE, blade_visual_scene, "BladeAttachment")
