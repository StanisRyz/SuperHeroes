class_name KnightVisual
extends CharacterVisualController

## KayKit Knight presentation layer. It owns model setup, animation import, and equipment attachments.

const KAYKIT_LIBRARY_NAME: StringName = &"kaykit"
const RIGHT_HAND_BONE: StringName = &"handslot.r"
const LEFT_HAND_BONE: StringName = &"handslot.l"

@export_category("Imported KayKit scenes")
@export var movement_animation_source: PackedScene
@export var general_animation_source: PackedScene
@export var sword_visual_scene: PackedScene
@export var shield_visual_scene: PackedScene
@export_category("Resolved imported nodes")
@export var animation_player_path: NodePath
@export var skeleton_path: NodePath

@onready var knight_model: Node3D = $ModelOffset/KnightModel


func _ready() -> void:
	var animation_player: AnimationPlayer = _resolve_animation_player()
	if animation_player == null:
		animation_player = AnimationPlayer.new()
		animation_player.name = "AnimationPlayer"
		knight_model.add_child(animation_player)
	_import_kaykit_animations(animation_player)
	configure_animation_player(animation_player)
	var skeleton: Skeleton3D = _resolve_skeleton()
	if skeleton == null:
		push_warning("KnightVisual: no Skeleton3D was found on the imported Knight model.")
		return
	_attach_equipment(skeleton, RIGHT_HAND_BONE, sword_visual_scene, "SwordAttachment")
	_attach_equipment(skeleton, LEFT_HAND_BONE, shield_visual_scene, "ShieldAttachment")


func _resolve_animation_player() -> AnimationPlayer:
	if animation_player_path != NodePath():
		return get_node_or_null(animation_player_path) as AnimationPlayer
	return _find_first_animation_player(knight_model)


func _resolve_skeleton() -> Skeleton3D:
	if skeleton_path != NodePath():
		return get_node_or_null(skeleton_path) as Skeleton3D
	return _find_first_skeleton(knight_model)


func _import_kaykit_animations(target_player: AnimationPlayer) -> void:
	var library: AnimationLibrary = AnimationLibrary.new()
	_add_animations_from_source(library, movement_animation_source)
	_add_animations_from_source(library, general_animation_source)
	if library.get_animation_list().is_empty():
		push_warning("KnightVisual: KayKit animation scenes provided no animations.")
		return
	if target_player.has_animation_library(KAYKIT_LIBRARY_NAME):
		target_player.remove_animation_library(KAYKIT_LIBRARY_NAME)
	target_player.add_animation_library(KAYKIT_LIBRARY_NAME, library)


func _add_animations_from_source(library: AnimationLibrary, source_scene: PackedScene) -> void:
	if source_scene == null:
		return
	var source_root: Node = source_scene.instantiate()
	var source_player: AnimationPlayer = _find_first_animation_player(source_root)
	if source_player != null:
		for source_animation_name: StringName in source_player.get_animation_list():
			var animation: Animation = source_player.get_animation(source_animation_name)
			if animation == null:
				continue
			var clip_name: StringName = StringName(String(source_animation_name).get_file())
			if library.has_animation(clip_name):
				continue
			var imported_animation: Animation = animation.duplicate(true)
			if clip_name == &"Idle_A" or clip_name == &"Running_A":
				imported_animation.loop_mode = Animation.LOOP_LINEAR
			library.add_animation(clip_name, imported_animation)
	source_root.queue_free()


func _attach_equipment(skeleton: Skeleton3D, bone_name: StringName, visual_scene: PackedScene, attachment_name: StringName) -> void:
	if visual_scene == null or skeleton.find_bone(bone_name) < 0:
		push_warning("KnightVisual: missing equipment visual or hand bone %s." % bone_name)
		return
	var attachment: BoneAttachment3D = BoneAttachment3D.new()
	attachment.name = attachment_name
	attachment.bone_name = bone_name
	skeleton.add_child(attachment)
	attachment.add_child(visual_scene.instantiate())


func _find_first_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child: Node in root.get_children():
		var result: AnimationPlayer = _find_first_animation_player(child)
		if result != null:
			return result
	return null


func _find_first_skeleton(root: Node) -> Skeleton3D:
	if root is Skeleton3D:
		return root as Skeleton3D
	for child: Node in root.get_children():
		var result: Skeleton3D = _find_first_skeleton(child)
		if result != null:
			return result
	return null
