extends Chapter4MageBase

const TELEGRAPH_COLOR := Color(0.6, 0.9, 1.0, 0.3)
const BOLT_COLOR := Color(0.65, 0.9, 1.0, 1.0)

@export_group("Wind Pattern Tuning")
@export var pattern_windup: float = 1.15
@export var vulnerability_recovery: float = 1.3
@export var end_lag: float = 0.2
@export var next_attack_cooldown: float = 2.2
@export var gate_radius: float = 120.0
@export var fan_radius: float = 140.0
@export var volley_delay: float = 0.05
@export var gate_barrage_delay: float = 0.04
@export var lane_phase_gap: float = 0.12
@export var second_fan_delay: float = 0.15

func _ready() -> void:
	mage_element = "wind"
	required_reflect_element = "wind"
	attack_interval = 2.5
	vulnerability_duration = 1.7
	projectile_speed = 300.0
	super._ready()

func perform_attack_pattern() -> void:
	begin_vulnerability_window(pattern_windup + vulnerability_recovery)

	match randi() % 3:
		0:
			await _pattern_cross_lanes(pattern_windup)
		1:
			await _pattern_rotating_fan(pattern_windup)
		_:
			await _pattern_gate_barrage(pattern_windup)

	await wait_scaled(end_lag)
	finish_casting_scaled(next_attack_cooldown)

func _pattern_gate_barrage(windup: float) -> void:
	# Circular barrage with one random safe wedge (dash through the gate).
	var center := predict_player_position(0.3)
	var safe_lane := randi() % 8
	var markers: Array = []
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var pos := center + Vector2.RIGHT.rotated(angle) * gate_radius
		if i == safe_lane:
			continue
		markers.append(_spawn_marker(pos, 9.0))

	await wait_scaled(windup)
	for i in range(8):
		if i == safe_lane:
			continue
		var angle := TAU * float(i) / 8.0
		var dir := (center + Vector2.RIGHT.rotated(angle) * gate_radius - global_position).normalized()
		spawn_projectile(dir, 1.2, 1.65, 7.0, BOLT_COLOR)
		await wait_scaled(gate_barrage_delay)

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
	await wait_scaled(windup)

	for i in range(positions.size()):
		if i % 2 == 0:
			var dir := (positions[i] - global_position).normalized()
			spawn_projectile(dir, 1.25, 1.6, 7.0, BOLT_COLOR)
	await wait_scaled(lane_phase_gap)
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
		markers.append(_spawn_marker(global_position + dir.rotated(offset) * fan_radius, 10.0))

	await wait_scaled(windup)
	for offset in [-0.65, -0.35, -0.1, 0.1, 0.35, 0.65]:
		spawn_projectile(dir.rotated(offset), 1.2, 1.45, 7.0, BOLT_COLOR)
		await wait_scaled(volley_delay)

	await wait_scaled(second_fan_delay)
	dir = get_direction_to_player()
	for offset in [0.65, 0.35, 0.1, -0.1, -0.35, -0.65]:
		spawn_projectile(dir.rotated(offset), 1.15, 1.35, 7.0, BOLT_COLOR)
		await wait_scaled(volley_delay)

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
