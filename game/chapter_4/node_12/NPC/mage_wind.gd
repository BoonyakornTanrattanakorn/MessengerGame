extends Chapter4MageBase

const TELEGRAPH_COLOR := Color(0.6, 0.9, 1.0, 0.3)
const BOLT_COLOR := Color(0.0, 0.796, 0.0, 1.0)

func _ready() -> void:
	mage_element = "wind"
	required_reflect_element = "wind"
	projectile_speed = 200.0
	super._ready()

func perform_attack_pattern() -> void:
	begin_vulnerability_window(1.15 + 1.3)

	match randi() % 3:
		0:
			await _pattern_cross_lanes(1.15)
		1:
			await _pattern_rotating_fan(1.15)
		_:
			await _pattern_gate_barrage(1.15)

	await get_tree().create_timer(0.2).timeout
	finish_casting(2.2)

func _pattern_gate_barrage(windup: float) -> void:
	# Circular barrage with one random safe wedge (dash through the gate).
	var center := predict_player_position(0.3)
	var safe_lane := randi() % 8
	var markers: Array = []
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var pos := center + Vector2.RIGHT.rotated(angle) * 120.0
		if i == safe_lane:
			continue
		markers.append(_spawn_marker(pos, 9.0))

	await get_tree().create_timer(windup).timeout
	for i in range(8):
		if i == safe_lane:
			continue
		var angle := TAU * float(i) / 8.0
		var dir := (center + Vector2.RIGHT.rotated(angle) * 120.0 - global_position).normalized()
		spawn_projectile(dir, 1.2, 1.65, 7.0, BOLT_COLOR)
		await get_tree().create_timer(0.04).timeout

	_cleanup_markers(markers)

func _pattern_cross_lanes(windup: float) -> void:
	# Cross-lane burst: encourages horizontal/vertical dash timing.
	var center := predict_player_position(0.35)
	var positions: Array[Vector2] = []
	for y in [-96.0, -64.0, -32.0, 0.0, 32.0, 64.0, 96.0]:
		positions.append(center + Vector2(0, y))
	for x in [-96.0, -64.0, -32.0, 32.0, 64.0, 96.0]:
		positions.append(center + Vector2(x, 0))

	var markers := _spawn_markers(positions, 12.0)
	await get_tree().create_timer(windup).timeout

	for i in range(positions.size()):
		if i % 2 == 0:
			var dir := (positions[i] - global_position).normalized()
			spawn_projectile(dir, 1.25, 1.6, 7.0, BOLT_COLOR)
	await get_tree().create_timer(0.12).timeout
	for i in range(positions.size()):
		if i % 2 == 1:
			var dir := (positions[i] - global_position).normalized()
			spawn_projectile(dir, 1.25, 1.6, 7.0, BOLT_COLOR)

	_cleanup_markers(markers)

func _pattern_rotating_fan(windup: float) -> void:
	# Rotating fan: two angular sweeps with a small safe wedge to dash into.
	var dir := get_direction_to_player()
	var markers: Array = []
	for offset in [-0.65, -0.35, -0.1, 0.1, 0.35, 0.65]:
		markers.append(_spawn_marker(global_position + dir.rotated(offset) * 140.0, 10.0))

	await get_tree().create_timer(windup).timeout
	for offset in [-0.65, -0.35, -0.1, 0.1, 0.35, 0.65]:
		spawn_projectile(dir.rotated(offset), 1.2, 1.45, 7.0, BOLT_COLOR)
		await get_tree().create_timer(0.05).timeout

	await get_tree().create_timer(0.15).timeout
	dir = get_direction_to_player()
	for offset in [0.65, 0.35, 0.1, -0.1, -0.35, -0.65]:
		spawn_projectile(dir.rotated(offset), 1.15, 1.35, 7.0, BOLT_COLOR)
		await get_tree().create_timer(0.05).timeout

	_cleanup_markers(markers)

func _spawn_markers(positions: Array[Vector2], radius: float) -> Array:
	var spawned: Array = []
	for pos in positions:
		spawned.append(_spawn_marker(pos, radius))
	return spawned

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

func _cleanup_markers(markers: Array) -> void:
	for marker in markers:
		if is_instance_valid(marker):
			marker.queue_free()
