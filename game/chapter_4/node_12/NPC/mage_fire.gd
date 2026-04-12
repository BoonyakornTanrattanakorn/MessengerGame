extends Chapter4MageBase

const FIRE_COLOR := Color(1.0, 0.35, 0.15, 1.0)

func _ready() -> void:
	mage_element = "fire"
	required_reflect_element = "fire"
	projectile_speed = 150.0
	super._ready()

func perform_attack_pattern() -> void:
	begin_vulnerability_window(1.2 + 1.35)

	match randi() % 3:
		0:
			await _pattern_meteor_stripes(1.2)
		1:
			await _pattern_ring_collapse(1.2)
		_:
			await _pattern_checker_blast(1.2)

	# Finisher: tight aimed fan for pressure.
	var base_dir := get_direction_to_player()
	for offset in [-0.2, 0.0, 0.2]:
		spawn_projectile(base_dir.rotated(offset), 1.05, 1.4, 8.0, FIRE_COLOR)

	await get_tree().create_timer(0.2).timeout
	finish_casting(2.3)

func _pattern_checker_blast(windup: float) -> void:
	# Checkerboard impact: first one color, then inverse cells.
	var center := predict_player_position(0.4)
	var cells: Array[Vector2] = []
	for y in range(-2, 3):
		for x in range(-2, 3):
			cells.append(center + Vector2(x * 28.0, y * 28.0))

	var telegraphs: Array = []
	for p in cells:
		telegraphs.append(_spawn_fire_marker(p, 9.0))

	await get_tree().create_timer(windup).timeout
	for y in range(-2, 3):
		for x in range(-2, 3):
			if (x + y) % 2 != 0:
				continue
			summon_falling_strike(center + Vector2(x * 28.0, y * 28.0), 0.09, 8.5, FIRE_COLOR, 95.0)
	await get_tree().create_timer(0.14).timeout
	for y in range(-2, 3):
		for x in range(-2, 3):
			if (x + y) % 2 == 0:
				continue
			summon_falling_strike(center + Vector2(x * 28.0, y * 28.0), 0.08, 8.5, FIRE_COLOR, 95.0)

	_cleanup_fire_markers(telegraphs)

func _pattern_meteor_stripes(windup: float) -> void:
	# Alternating vertical meteor lines around predicted player position.
	var center := predict_player_position(0.45)
	var columns := [-54.0, -18.0, 18.0, 54.0]
	var points: Array[Vector2] = []
	for x_off in columns:
		for y_off in [-78.0, -39.0, 0.0, 39.0, 78.0]:
			points.append(center + Vector2(x_off, y_off))

	var telegraphs: Array = []
	for p in points:
		telegraphs.append(_spawn_fire_marker(p, 12.0))

	await get_tree().create_timer(windup).timeout
	for i in range(points.size()):
		if i % 2 == 0:
			await summon_falling_strike(points[i], 0.18, 11.0, FIRE_COLOR, 110.0)
	for i in range(points.size()):
		if i % 2 == 1:
			await summon_falling_strike(points[i], 0.16, 11.0, FIRE_COLOR, 110.0)

	_cleanup_fire_markers(telegraphs)

func _pattern_ring_collapse(windup: float) -> void:
	# Outer ring then inner ring collapse toward player predicted center.
	var center := predict_player_position(0.35)
	var telegraphs: Array = []
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		telegraphs.append(_spawn_fire_marker(center + Vector2.RIGHT.rotated(angle) * 70.0, 11.0))
	for i in range(6):
		var angle2 := TAU * float(i) / 6.0
		telegraphs.append(_spawn_fire_marker(center + Vector2.RIGHT.rotated(angle2) * 36.0, 10.0))

	await get_tree().create_timer(windup).timeout
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		await summon_falling_strike(center + Vector2.RIGHT.rotated(angle) * 70.0, 0.14, 10.0, FIRE_COLOR, 105.0)
	for i in range(6):
		var angle2 := TAU * float(i) / 6.0
		await summon_falling_strike(center + Vector2.RIGHT.rotated(angle2) * 36.0, 0.12, 10.0, FIRE_COLOR, 95.0)

	_cleanup_fire_markers(telegraphs)

func _spawn_fire_marker(pos: Vector2, radius: float) -> Polygon2D:
	var marker := Polygon2D.new()
	marker.global_position = pos
	marker.color = Color(1.0, 0.5, 0.3, 0.3)
	marker.polygon = PackedVector2Array([
		Vector2(-radius, -radius),
		Vector2(radius, -radius),
		Vector2(radius, radius),
		Vector2(-radius, radius)
	])
	get_tree().current_scene.add_child(marker)
	return marker

func _cleanup_fire_markers(markers: Array) -> void:
	for marker in markers:
		if is_instance_valid(marker):
			marker.queue_free()
