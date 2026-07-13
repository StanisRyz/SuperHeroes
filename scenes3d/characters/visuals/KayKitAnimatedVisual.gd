class_name KayKitAnimatedVisual
extends CharacterVisualController

## Shared KayKit rig discovery and cached animation-library loading for presentation-only visuals.

const KAYKIT_LIBRARY_NAME: StringName = &"kaykit"
static var _animation_library_cache: Dictionary = {}

@export_category("Imported KayKit scenes")
@export var movement_animation_source: PackedScene
@export var general_animation_source: PackedScene
@export_category("Resolved imported nodes")
@export var animation_player_path: NodePath
@export var skeleton_path: NodePath


func initialize_kaykit_visual(model_root: Node3D) -> Skeleton3D:
	var animation_player: AnimationPlayer = _resolve_animation_player(model_root)
	if animation_player == null:
		animation_player = AnimationPlayer.new()
		animation_player.name = "AnimationPlayer"
		model_root.add_child(animation_player)
	var library: AnimationLibrary = _get_cached_animation_library()
	if library != null:
		if animation_player.has_animation_library(KAYKIT_LIBRARY_NAME):
			animation_player.remove_animation_library(KAYKIT_LIBRARY_NAME)
		animation_player.add_animation_library(KAYKIT_LIBRARY_NAME, library)
	configure_animation_player(animation_player)
	return _resolve_skeleton(model_root)


func attach_equipment(skeleton: Skeleton3D, bone_name: StringName, visual_scene: PackedScene, attachment_name: StringName) -> void:
	if visual_scene == null or skeleton == null or skeleton.find_bone(bone_name) < 0:
		push_warning("KayKitAnimatedVisual: missing equipment visual or bone %s." % bone_name)
		return
	var attachment := BoneAttachment3D.new()
	attachment.name = attachment_name
	attachment.bone_name = bone_name
	skeleton.add_child(attachment)
	attachment.add_child(visual_scene.instantiate())


func _resolve_animation_player(model_root: Node3D) -> AnimationPlayer:
	if animation_player_path != NodePath():
		return get_node_or_null(animation_player_path) as AnimationPlayer
	return _find_first_animation_player(model_root)


func _resolve_skeleton(model_root: Node3D) -> Skeleton3D:
	if skeleton_path != NodePath():
		return get_node_or_null(skeleton_path) as Skeleton3D
	return _find_first_skeleton(model_root)


func _get_cached_animation_library() -> AnimationLibrary:
	var cache_key: String = "%s|%s|%s|%s" % [
		movement_animation_source.resource_path if movement_animation_source != null else "",
		general_animation_source.resource_path if general_animation_source != null else "",
		idle_animation,
		run_animation,
	]
	if _animation_library_cache.has(cache_key):
		return _animation_library_cache[cache_key] as AnimationLibrary
	var library := AnimationLibrary.new()
	_add_animations_from_source(library, movement_animation_source)
	_add_animations_from_source(library, general_animation_source)
	if library.get_animation_list().is_empty():
		push_warning("KayKitAnimatedVisual: animation sources provided no clips.")
		return null
	_animation_library_cache[cache_key] = library
	return library


func _add_animations_from_source(library: AnimationLibrary, source_scene: PackedScene) -> void:
	if source_scene == null:
		return
	var source_root: Node = source_scene.instantiate()
	var source_player: AnimationPlayer = _find_first_animation_player(source_root)
	if source_player != null:
		for source_animation_name: StringName in source_player.get_animation_list():
			var source_animation: Animation = source_player.get_animation(source_animation_name)
			if source_animation == null:
				continue
			var clip_name: StringName = StringName(String(source_animation_name).get_file())
			if library.has_animation(clip_name):
				continue
			var imported_animation: Animation = source_animation.duplicate(true)
			if clip_name == StringName(String(idle_animation).get_file()) or clip_name == StringName(String(run_animation).get_file()):
				imported_animation.loop_mode = Animation.LOOP_LINEAR
			library.add_animation(clip_name, imported_animation)
	source_root.queue_free()


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
