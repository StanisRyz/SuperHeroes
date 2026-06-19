extends RefCounted

static func ready_color() -> Color:
	return Color(0.3, 1.0, 0.35, 1.0)

static func cooldown_color() -> Color:
	return Color(0.58, 0.58, 0.58, 1.0)

static func warning_color() -> Color:
	return Color(1.0, 0.72, 0.12, 1.0)

static func danger_color() -> Color:
	return Color(1.0, 0.22, 0.22, 1.0)

static func muted_color() -> Color:
	return Color(0.52, 0.52, 0.52, 1.0)

static func positive_color() -> Color:
	return Color(0.4, 1.0, 0.5, 1.0)

static func boss_color() -> Color:
	return Color(1.0, 0.48, 0.1, 1.0)

static func final_phase_color() -> Color:
	return Color(1.0, 0.3, 0.95, 1.0)
