extends Object

static func apply_stage(stage: Dictionary, arena: Node) -> void:
	if stage.is_empty() or arena == null:
		return

	_apply_background_colors(stage, arena)
	_apply_run_settings(stage, arena)
	_apply_event_profile(stage, arena)


static func _apply_background_colors(stage: Dictionary, arena: Node) -> void:
	var bg_colors: Dictionary = stage.get("background_colors", {})
	if bg_colors.is_empty():
		return

	var ground := arena.get_node_or_null("Ground")
	if ground != null and bg_colors.has("ground"):
		ground.set("color", bg_colors["ground"])

	var center_guide := arena.get_node_or_null("CenterGuide")
	if center_guide != null and bg_colors.has("center_guide"):
		center_guide.set("color", bg_colors["center_guide"])

	var h_guide := arena.get_node_or_null("HorizontalGuide")
	if h_guide != null and bg_colors.has("guide_lines"):
		h_guide.set("color", bg_colors["guide_lines"])

	var v_guide := arena.get_node_or_null("VerticalGuide")
	if v_guide != null and bg_colors.has("guide_lines"):
		v_guide.set("color", bg_colors["guide_lines"])


static func _apply_run_settings(stage: Dictionary, arena: Node) -> void:
	var settings: Dictionary = stage.get("run_settings", {})
	if settings.is_empty():
		return

	var run_manager := arena.get_node_or_null("RunManager")
	if run_manager == null:
		return

	if run_manager.has_method("apply_stage_run_settings"):
		run_manager.apply_stage_run_settings(settings)
	else:
		if settings.has("target_run_time") and run_manager.has_method("apply_run_tuning"):
			var target := float(settings["target_run_time"])
			var phase := float(settings.get("final_phase_start_time", target * 0.9))
			run_manager.apply_run_tuning(target, phase)


static func _apply_event_profile(stage: Dictionary, arena: Node) -> void:
	var profile: String = str(stage.get("event_profile", ""))
	if profile.is_empty():
		return

	var event_director := arena.get_node_or_null("EventDirector")
	if event_director != null and event_director.has_method("set_event_profile"):
		event_director.set_event_profile(profile)

	var spawn_director := arena.get_node_or_null("SpawnDirector")
	if spawn_director != null and spawn_director.has_method("set_stage_profile"):
		spawn_director.set_stage_profile(profile)
