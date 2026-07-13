class_name KnightVisual
extends KayKitAnimatedVisual

## KayKit Knight presentation layer. It owns model setup, animation import, and equipment attachments.

const RIGHT_HAND_BONE: StringName = &"handslot.r"
const LEFT_HAND_BONE: StringName = &"handslot.l"

@export var sword_visual_scene: PackedScene
@export var shield_visual_scene: PackedScene
@export var rage_wave_animation: StringName = &"kaykit/Melee_2H_Attack_Spinning"
@export var shield_bash_animation: StringName = &"kaykit/Melee_Block_Attack"
@export var crushing_leap_animation: StringName = &"kaykit/Melee_1H_Attack_Jump_Chop"

@onready var knight_model: Node3D = $ModelOffset/KnightModel


func _ready() -> void:
	var skeleton: Skeleton3D = initialize_kaykit_visual(knight_model)
	if skeleton == null:
		push_warning("KnightVisual: no Skeleton3D was found on the imported Knight model.")
		return
	attach_equipment(skeleton, RIGHT_HAND_BONE, sword_visual_scene, "SwordAttachment")
	attach_equipment(skeleton, LEFT_HAND_BONE, shield_visual_scene, "ShieldAttachment")


func play_ability(ability_id: String) -> bool:
	match ability_id:
		"rage_wave": return play_action(ability_id, rage_wave_animation, 0.5)
		"shield_bash": return play_action(ability_id, shield_bash_animation, 0.45)
		"crushing_leap": return play_action(ability_id, crushing_leap_animation, 0.35)
	return false
