class_name EnemyVariant3DAdapter
extends RefCounted

## Keeps SpawnDirector dictionaries authoritative while making their pixel speeds explicit 3D world speeds.

const PIXELS_PER_WORLD_UNIT: float = 40.0

static func adapt_variant(variant: Dictionary) -> Dictionary:
	var adapted: Dictionary = variant.duplicate(true)
	var legacy_speed: float = float(variant.get("speed", 120.0))
	adapted["world_speed"] = float(variant.get("world_speed", legacy_speed / PIXELS_PER_WORLD_UNIT))
	var source_behavior_id: String = str(variant.get("behavior_id", "chase"))
	adapted["source_behavior_id"] = source_behavior_id
	adapted["behavior_id"] = "chase"
	if source_behavior_id != "chase":
		adapted["unsupported_behavior_id"] = source_behavior_id
	return adapted
