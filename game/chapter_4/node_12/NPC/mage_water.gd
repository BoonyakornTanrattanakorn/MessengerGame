extends Chapter4MageBase

const TELEGRAPH_COLOR := Color(0.35, 0.75, 1.0, 0.28)
const WAVE_COLOR := Color(0.3, 0.65, 1.0, 1.0)

func _ready() -> void:
	mage_element = "water"
	weakness_element = "wind"
	required_reflect_element = "water"
	attack_interval = 2.7
	vulnerability_duration = 1.75
	projectile_speed = 210.0
	super._ready()

func perform_attack_pattern() -> void:
	var windup := 1.1
	begin_vulnerability_window(windup + 1.3)

	match randi() % 3:
		0:
			await _pattern_tide_wall(windup)
		1:
			await _pattern_rain_grid(windup)
		_:
			await _pattern_orbit_lances(windup)

	await get_tree().create_timer(0.18).timeout
	finish_casting(2.25)

func _pattern_orbit_lances(windup: float) -> void:
	# Orbiting rain with one rotating safe lane.
	var center := predict_player_position(0.35)
	var base_safe := randi() % 10
	var markers: Array = []
	for i in range(10):
		if i == base_safe:
			continue
		var a := TAU * float(i) / 10.0
		markers.append(_spawn_marker(center + Vector2.RIGHT.rotated(a) * 72.0, 8.0))

	await get_tree().create_timer(windup).timeout
	for wave in range(2):
		var safe_idx := (base_safe + wave * 2) % 10
		for i in range(10):
			if i == safe_idx:
				continue
			var a := TAU * float(i) / 10.0
			await summon_falling_strike(center + Vector2.RIGHT.rotated(a) * 72.0, 0.08, 8.0, WAVE_COLOR, 90.0)
		await get_tree().create_timer(0.18).timeout

	_cleanup_markers(markers)

func _spawn_marker(pos: Vector2, radius: float) -> Polygon2D:
	var marker := Polygon2D.new()
	marker.global_position = pos
	marker.color = TELEGRAPH_COLOR
	marker.polygon = PackedVector2Array([
		Vector2(-radius, -radius),
		Vector2(radius, -radius),
		Vector2(radius, radius),
		Vector2(-radius, radius)
	])
	get_tree().current_scene.add_child(marker)
	return marker

func _pattern_tide_wall(windup: float) -> void:
	# Two sweeping walls aimed around predicted player path.
	var center := predict_player_position(0.45)
	var upper: Array[Vector2] = []
	var lower: Array[Vector2] = []
	for x in [-96.0, -64.0, -32.0, 0.0, 32.0, 64.0, 96.0]:
		upper.append(center + Vector2(x, -38.0))
		lower.append(center + Vector2(x, 38.0))

	var markers := _spawn_markers(upper + lower, 11.0)
	await get_tree().create_timer(windup).timeout

	for pos in upper:
		var dir := (pos - global_position).normalized()
		spawn_projectile(dir, 1.0, 1.8, 8.0, WAVE_COLOR)
	await get_tree().create_timer(0.16).timeout
	for pos in lower:
		var dir2 := (pos - global_position).normalized()
		spawn_projectile(dir2, 1.0, 1.8, 8.0, WAVE_COLOR)

	_cleanup_markers(markers)

func _pattern_rain_grid(windup: float) -> void:
	# Grid rain from above then a precise aimed water lance.
	var center := predict_player_position(0.35)
	var points: Array[Vector2] = []
	for y in [-1, 0, 1]:
		for x in [-1, 0, 1]:
			points.append(center + Vector2(x * 34.0, y * 34.0))

	var markers := _spawn_markers(points, 10.0)
	await get_tree().create_timer(windup).timeout

	for p in points:
		await summon_falling_strike(p, 0.12, 9.5, Color(0.35, 0.75, 1.0, 1.0), 95.0)

	# Targeted lance after player reacts to the grid.
	var dir := get_direction_to_player().rotated(randf_range(-0.08, 0.08))
	spawn_projectile(dir, 1.15, 1.6, 8.0, WAVE_COLOR)

	_cleanup_markers(markers)

func _spawn_markers(positions: Array[Vector2], radius: float) -> Array:
	var spawned: Array = []
	for pos in positions:
		var marker := Polygon2D.new()
		marker.global_position = pos
		marker.color = TELEGRAPH_COLOR
		marker.polygon = PackedVector2Array([
			Vector2(-radius, -radius),
			Vector2(radius, -radius),
			Vector2(radius, radius),
			Vector2(-radius, radius)
		])
		get_tree().current_scene.add_child(marker)
		spawned.append(marker)
	return spawned

func _cleanup_markers(markers: Array) -> void:
	for marker in markers:
		if is_instance_valid(marker):
			marker.queue_free()
