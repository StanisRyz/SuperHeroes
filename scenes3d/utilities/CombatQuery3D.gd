class_name CombatQuery3D
extends RefCounted

static func nearest_living_enemy(container: Node3D, origin: Vector3, maximum_range: float = INF) -> Enemy3D:
	var result: Enemy3D = null
	var best := maximum_range
	for enemy: Enemy3D in _living_enemies(container):
		var offset := enemy.global_position - origin
		offset.y = 0.0
		if offset.length() <= best:
			best = offset.length()
			result = enemy
	return result


static func nearest_living_enemy_excluding(container: Node3D, origin: Vector3, maximum_range: float, excluded_instance_ids: Dictionary) -> Enemy3D:
	var result: Enemy3D = null
	var best_distance := maximum_range
	for enemy: Enemy3D in _living_enemies(container):
		if excluded_instance_ids.has(enemy.get_instance_id()):
			continue
		var offset := enemy.global_position - origin
		offset.y = 0.0
		var distance := offset.length()
		if distance <= best_distance:
			best_distance = distance
			result = enemy
	return result

static func enemies_in_radius(container: Node3D, origin: Vector3, radius: float) -> Array[Enemy3D]:
	var result: Array[Enemy3D] = []
	for enemy: Enemy3D in _living_enemies(container):
		var offset := enemy.global_position - origin
		offset.y = 0.0
		if offset.length() <= radius:
			result.append(enemy)
	return result

static func enemies_in_cone(container: Node3D, origin: Vector3, direction: Vector3, maximum_range: float, angle_degrees: float) -> Array[Enemy3D]:
	var result: Array[Enemy3D] = []
	var forward := direction.normalized()
	var minimum_dot := cos(deg_to_rad(angle_degrees * 0.5))
	for enemy: Enemy3D in _living_enemies(container):
		var offset := enemy.global_position - origin
		offset.y = 0.0
		if offset.is_zero_approx() or offset.length() > maximum_range:
			continue
		if forward.dot(offset.normalized()) >= minimum_dot:
			result.append(enemy)
	return result

static func _living_enemies(container: Node3D) -> Array[Enemy3D]:
	var result: Array[Enemy3D] = []
	if container == null:
		return result
	for child: Node in container.get_children():
		if child is Enemy3D:
			var enemy := child as Enemy3D
			if is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and not enemy.is_dead():
				result.append(enemy)
	return result
