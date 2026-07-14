class_name CrossbowmanVisual3D
extends KnightVisual

## Lightweight Stage 2.1 visual: shared animated character rig plus an existing KayKit crossbow attachment.

func _ready() -> void:
	var skeleton: Skeleton3D = initialize_kaykit_visual(knight_model)
	if skeleton == null:
		push_warning("CrossbowmanVisual3D: no Skeleton3D was found on the imported character model.")
		return
	attach_equipment(skeleton, RIGHT_HAND_BONE, sword_visual_scene, "CrossbowAttachment")
