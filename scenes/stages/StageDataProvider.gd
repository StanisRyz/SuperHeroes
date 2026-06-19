extends Node

var _stages: Array[Dictionary] = [
	{
		"id": "city_rooftop",
		"display_name": "City Rooftop",
		"subtitle": "Urban high-ground combat",
		"description": "Fight across dark rain-slicked rooftops above a glowing city. Face balanced enemy waves and a powerful guardian at the end.",
		"difficulty_label": "Normal",
		"background_colors": {
			"ground": Color(0.08, 0.10, 0.14, 1.0),
			"center_guide": Color(0.15, 0.20, 0.28, 1.0),
			"guide_lines": Color(0.12, 0.16, 0.22, 1.0),
		},
		"run_settings": {
			"target_run_time": 600.0,
			"final_phase_start_time": 540.0,
		},
		"event_profile": "balanced",
		"final_boss_id": "titan_guardian",
		"unlocked_by_default": true,
	},
	{
		"id": "neon_lab",
		"display_name": "Neon Lab",
		"subtitle": "High-tech research facility",
		"description": "Navigate a flickering neon lab swarming with advanced units. Ranged support enemies and a crystalline overlord await.",
		"difficulty_label": "Hard",
		"background_colors": {
			"ground": Color(0.04, 0.06, 0.14, 1.0),
			"center_guide": Color(0.08, 0.10, 0.30, 1.0),
			"guide_lines": Color(0.10, 0.06, 0.22, 1.0),
		},
		"run_settings": {
			"target_run_time": 600.0,
			"final_phase_start_time": 540.0,
		},
		"event_profile": "ranged_support",
		"final_boss_id": "prism_overlord",
		"unlocked_by_default": true,
	},
	{
		"id": "wasteland_gate",
		"display_name": "Wasteland Gate",
		"subtitle": "Scorched frontier under siege",
		"description": "Survive the swarms of the scorched wasteland. Exploders and hordes close in before the molten colossus rises.",
		"difficulty_label": "Hard",
		"background_colors": {
			"ground": Color(0.16, 0.08, 0.04, 1.0),
			"center_guide": Color(0.28, 0.12, 0.04, 1.0),
			"guide_lines": Color(0.22, 0.10, 0.04, 1.0),
		},
		"run_settings": {
			"target_run_time": 600.0,
			"final_phase_start_time": 540.0,
		},
		"event_profile": "swarm_exploder",
		"final_boss_id": "molten_colossus",
		"unlocked_by_default": true,
	},
]


func get_all_stages() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for stage in _stages:
		result.append(stage.duplicate(true))
	return result


func get_stage(stage_id: String) -> Dictionary:
	for stage in _stages:
		if str(stage.get("id", "")) == stage_id:
			return stage.duplicate(true)
	return {}


func get_default_stage() -> Dictionary:
	if not _stages.is_empty():
		return _stages[0].duplicate(true)
	return {}


func is_valid_stage(stage_id: String) -> bool:
	return not get_stage(stage_id).is_empty()
