extends Chapter4MageBase

const TELEGRAPH_COLOR := Color(0.8, 0.6, 0.35, 0.35)
const IMPACT_COLOR := Color(0.55, 0.35, 0.2, 1.0)

func _ready() -> void:
	mage_element = "earth"
	required_reflect_element = "earth"
	attack_interval = 2.8
	vulnerability_duration = 1.9
	projectile_speed = 230.0
	super._ready()

func perform_attack_pattern() -> void:
	# Earth mage enters a ritual: long telegraph, then structured impact pattern.
	var center := predict_player_position(0.4)
	var pattern_id := randi() % 4
	var positions := _build_pattern_positions(pattern_id, center)
	positions.shuffle()

	# Attack window starts during charge-up and lasts through recovery.
	begin_vulnerability_window(1.25 + 1.1)

	var telegraphs := _spawn_telegraphs(positions, 16.0)
	await get_tree().create_timer(1.25).timeout

	# Two-stage impact rewards quick dash repositioning.
	for i in range(positions.size()):
		if i % 2 == 0:
			_spawn_impact(positions[i], 16.0)
	await get_tree().create_timer(0.22).timeout
	for i in range(positions.size()):
		if i % 2 == 1:
			_spawn_impact(positions[i], 16.0)

	for marker in telegraphs:
		if is_instance_valid(marker):
			marker.queue_free()

	# Closing aimed shot catches greedy punish attempts.
	var base_dir := get_direction_to_player()
	for offset in [-0.16, 0.0, 0.16]:
		spawn_projectile(base_dir.rotated(offset), 1.0, 2.1, 9.0, Color(0.62, 0.42, 0.24, 1.0))

	await get_tree().create_timer(0.25).timeout
	finish_casting(2.35)

func _build_pattern_positions(pattern_id: int, center: Vector2) -> Array[Vector2]:
	match pattern_id:
		0:
			return _pattern_circle(center)
		1:
			return _pattern_grid(center)
		2:
			return _pattern_vertical_stripe(center)
		_:
			return _pattern_horizontal_stripe(center)

func _pattern_circle(center: Vector2) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		out.append(center + Vector2.RIGHT.rotated(angle) * 56.0)
	return out

func _pattern_grid(center: Vector2) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for y in range(-1, 2):
		for x in range(-1, 2):
			out.append(center + Vector2(x * 38.0, y * 38.0))
	return out

func _pattern_vertical_stripe(center: Vector2) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for x_off in [-44.0, 0.0, 44.0]:
		for y_off in [-84.0, -42.0, 0.0, 42.0, 84.0]:
			out.append(center + Vector2(x_off, y_off))
	return out

func _pattern_horizontal_stripe(center: Vector2) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for y_off in [-44.0, 0.0, 44.0]:
		for x_off in [-84.0, -42.0, 0.0, 42.0, 84.0]:
			out.append(center + Vector2(x_off, y_off))
	return out

func _spawn_telegraphs(positions: Array[Vector2], radius: float) -> Array:
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

func _spawn_impact(pos: Vector2, radius: float) -> void:
	var flash := Polygon2D.new()
	flash.global_position = pos
	flash.color = IMPACT_COLOR
	flash.polygon = PackedVector2Array([
		Vector2(-radius * 0.7, -radius * 0.7),
		Vector2(radius * 0.7, -radius * 0.7),
		Vector2(radius * 0.7, radius * 0.7),
		Vector2(-radius * 0.7, radius * 0.7)
	])
	get_tree().current_scene.add_child(flash)

	var hitbox := Area2D.new()
	hitbox.top_level = true
	hitbox.global_position = pos
	hitbox.set("damage", attack_damage)
	hitbox.add_to_group("enemy_projectile")

	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	hitbox.add_child(collision)
	get_tree().current_scene.add_child(hitbox)

	call_deferred("_cleanup_impact", hitbox, flash)

func _cleanup_impact(hitbox: Area2D, flash: Polygon2D) -> void:
	await get_tree().create_timer(0.12).timeout
	if is_instance_valid(hitbox):
		hitbox.queue_free()
	if is_instance_valid(flash):
		flash.queue_free()
