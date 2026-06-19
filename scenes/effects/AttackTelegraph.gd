extends Node2D


func play_circle(world_position: Vector2, radius: float, duration: float) -> void:
	global_position = world_position
	var line := _make_ring(radius, Color(1.0, 0.85, 0.1, 0.85))
	add_child(line)
	_animate_and_free(line, duration)


func play_line(from_position: Vector2, to_position: Vector2, width: float, duration: float) -> void:
	global_position = Vector2.ZERO
	var line := Line2D.new()
	line.add_point(from_position)
	line.add_point(to_position)
	line.width = clampf(width, 2.0, 64.0)
	line.default_color = Color(1.0, 0.45, 0.1, 0.8)
	add_child(line)
	_animate_and_free(line, duration)


func _make_ring(radius: float, color: Color) -> Line2D:
	var line := Line2D.new()
	var segment_count := 32
	var points := PackedVector2Array()
	for i in range(segment_count + 1):
		var angle := TAU * float(i) / float(segment_count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	line.points = points
	line.width = 5.0
	line.default_color = color
	return line


func _animate_and_free(visual: CanvasItem, duration: float) -> void:
	visual.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(visual, "modulate:a", 0.9, 0.1)
	var mid := maxf(duration - 0.3, 0.05)
	var pulse_half := mid * 0.25
	tween.tween_property(visual, "modulate:a", 0.2, pulse_half)
	tween.tween_property(visual, "modulate:a", 0.9, pulse_half)
	tween.tween_property(visual, "modulate:a", 0.2, pulse_half)
	tween.tween_property(visual, "modulate:a", 0.9, pulse_half)
	tween.tween_property(visual, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
