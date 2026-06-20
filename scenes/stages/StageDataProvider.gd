extends Node

var _stages: Array[Dictionary] = [
	{
		"id": "city_rooftop",
		"display_name": "City Rooftop",
		"subtitle": "Urban high-ground combat",
		"description": "Fight across dark rain-slicked rooftops above a glowing city. Face balanced enemy waves and a powerful guardian at the end.",
		"difficulty_label": "Normal",
		"threat_summary": "Balanced rooftop waves with steady pressure from the default event schedule.",
		"stage_goal": "Survive 10:00, push through the final pressure, then defeat the Titan Guardian.",
		"recommended_playstyle": "Flexible builds and mixed upgrades work well for first clears.",
		"enemy_pressure": "Balanced pursuit",
		"boss_preview": "Titan Guardian - sturdy final duel.",
		"objective_type": "survival",
		"objective_data": {},
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
		"description": "Navigate a flickering neon lab swarming with advanced units. Ranged support enemies and a crystalline overlord await. Keep the Lab Reactor alive to survive long enough for the final duel.",
		"difficulty_label": "Hard",
		"threat_summary": "Ranged support pressure and lab-controlled enemy surges targeting both you and the Reactor.",
		"stage_goal": "Defend the Lab Reactor for 10:00, then defeat the Prism Overlord. The run ends in defeat if the Reactor is destroyed.",
		"recommended_playstyle": "Stay near the Reactor. Mobility, line control, and priority targeting help stabilize the lab.",
		"enemy_pressure": "Ranged support",
		"boss_preview": "Prism Overlord - projectile-heavy final duel.",
		"objective_type": "defense",
		"objective_data": {
			"target_hp": 300,
			"target_display_name": "Lab Reactor",
			"damage_per_enemy_per_second": 15.0,
		},
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
		"description": "Survive the swarms of the scorched wasteland. Three Dark Portals feed endless enemy waves — destroy them all to stop the siege and draw out the Molten Colossus.",
		"difficulty_label": "Hard",
		"threat_summary": "Swarm and exploder pressure closes space quickly while Dark Portals anchor the assault.",
		"stage_goal": "Destroy all 3 Dark Portals to trigger the final boss encounter, then defeat the Molten Colossus.",
		"recommended_playstyle": "Area damage and durable builds. Hunt portals between enemy waves; close control prevents being overwhelmed.",
		"enemy_pressure": "Swarm / exploder",
		"boss_preview": "Molten Colossus - heavy pressure final duel.",
		"objective_type": "destroy_structures",
		"objective_data": {
			"portal_count": 3,
			"portal_hp": 150,
			"portal_display_name": "Dark Portal",
		},
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
