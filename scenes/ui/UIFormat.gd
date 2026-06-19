extends RefCounted

static func format_time(seconds: float) -> String:
	var total_seconds := int(floor(seconds))
	var minutes := int(total_seconds / 60.0)
	var remaining_seconds := total_seconds % 60
	return "%d:%02d" % [minutes, remaining_seconds]


static func format_cooldown(seconds: float) -> String:
	if seconds <= 0.0:
		return "Ready"
	if seconds < 10.0:
		return "%.1fs" % seconds
	return "%ds" % int(seconds)


static func format_percent(value: float) -> String:
	return "%.0f%%" % (value * 100.0)


static func format_list(values: Array, empty_text: String = "None") -> String:
	if values.is_empty():
		return empty_text
	var parts: Array[String] = []
	for v in values:
		parts.append(str(v))
	return ", ".join(parts)


static func format_title_id(id: String) -> String:
	return id.replace("_", " ").capitalize()
