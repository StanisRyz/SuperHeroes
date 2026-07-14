class_name CrossbowmanVisual3D
extends KayKitAnimatedVisual

## Presentation-only ranged hero profile. Gameplay-facing code uses CharacterVisualController's neutral contract.

const RIGHT_HAND_BONE: StringName = &"handslot.r"

@export var crossbow_visual_scene: PackedScene
@export var charged_shot_animation: StringName = &"kaykit/Ranged_2H_Aiming"
@export var volley_animation: StringName = &"kaykit/Ranged_2H_Shooting"
@export var crossbow_position := Vector3.ZERO
@export var crossbow_rotation_degrees := Vector3.ZERO
@export var muzzle_position := Vector3(0.0, 0.0, -0.72)

@onready var ranger_model: Node3D = $ModelOffset/RangerModel
var _crossbow_attachment: BoneAttachment3D

func _ready() -> void:
	var skeleton := initialize_kaykit_visual(ranger_model)
	if skeleton == null:
		push_warning("CrossbowmanVisual3D: no Skeleton3D was found on Ranger.")
		return
	_crossbow_attachment = _attach_crossbow(skeleton)

func play_charged_shot() -> bool:
	return play_action("charged_crossbow_shot", charged_shot_animation, 0.62)

func play_volley() -> bool:
	return play_action("crossbow_volley", volley_animation, 0.55)

func get_muzzle() -> Marker3D:
	return _crossbow_attachment.get_node_or_null("Muzzle") as Marker3D if _crossbow_attachment != null else null

func _attach_crossbow(skeleton: Skeleton3D) -> BoneAttachment3D:
	if crossbow_visual_scene == null or skeleton.find_bone(RIGHT_HAND_BONE) < 0:
		push_warning("CrossbowmanVisual3D: missing crossbow scene or %s bone." % RIGHT_HAND_BONE)
		return null
	var attachment := BoneAttachment3D.new()
	attachment.name = "CrossbowAttachment"
	attachment.bone_name = RIGHT_HAND_BONE
	skeleton.add_child(attachment)
	var crossbow := crossbow_visual_scene.instantiate() as Node3D
	attachment.add_child(crossbow)
	crossbow.position = crossbow_position
	crossbow.rotation_degrees = crossbow_rotation_degrees
	var muzzle := Marker3D.new()
	muzzle.name = "Muzzle"
	muzzle.position = muzzle_position
	crossbow.add_child(muzzle)
	return attachment
