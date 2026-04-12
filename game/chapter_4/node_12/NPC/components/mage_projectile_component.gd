extends RefCounted
class_name MageProjectileComponent

var _owner: Node2D = null
var _active_projectiles: Array = []

func _init(owner: Node2D) -> void:
	_owner = owner

func prune_active_projectiles() -> void:
	_active_projectiles = _active_projectiles.filter(func(p): return p != null and is_instance_valid(p))

func has_active_projectiles() -> bool:
	prune_active_projectiles()
	return not _active_projectiles.is_empty()

func spawn_projectile(direction: Vector2, speed_scale: float, life_time: float, radius: float, tint: Color) -> void:
	_spawn_projectile_at(_owner.global_position, direction, speed_scale, life_time, radius, tint)

func spawn_projectile_from_position(spawn_position: Vector2, direction: Vector2, speed_scale: float, life_time: float, radius: float, tint: Color) -> void:
	_spawn_projectile_at(spawn_position, direction, speed_scale, life_time, radius, tint)

func spawn_delayed_burst(position: Vector2, delay: float, ring_count: int, speed_scale: float, tint: Color) -> void:
	var marker := Node2D.new()
	marker.top_level = true
	marker.global_position = position
	var guide := Polygon2D.new()
	guide.color = Color(tint.r, tint.g, tint.b, 0.4)
	guide.polygon = PackedVector2Array([
		Vector2(-6, -6),
		Vector2(6, -6),
		Vector2(6, 6),
		Vector2(-6, 6)
	])
	marker.add_child(guide)
	_owner.get_tree().current_scene.add_child(marker)
	await _owner.get_tree().create_timer(delay).timeout
	if not is_instance_valid(_owner):
		if is_instance_valid(marker):
			marker.queue_free()
		return
	for i in range(ring_count):
		var angle := TAU * float(i) / float(max(1, ring_count))
		spawn_projectile(Vector2.RIGHT.rotated(angle), speed_scale, 1.5, 8.0, tint)
	if is_instance_valid(marker):
		marker.queue_free()

func summon_falling_strike(target_position: Vector2, delay: float, radius: float, tint: Color, fall_height: float) -> void:
	var telegraph := Polygon2D.new()
	telegraph.color = Color(tint.r, tint.g, tint.b, 0.25)
	telegraph.global_position = target_position
	telegraph.polygon = PackedVector2Array([
		Vector2(-radius, -radius),
		Vector2(radius, -radius),
		Vector2(radius, radius),
		Vector2(-radius, radius)
	])
	_owner.get_tree().current_scene.add_child(telegraph)

	var falling := Polygon2D.new()
	falling.color = Color(tint.r, tint.g, tint.b, 0.95)
	falling.global_position = target_position + Vector2(0, -fall_height)
	falling.polygon = PackedVector2Array([
		Vector2(-radius * 0.7, -radius * 0.7),
		Vector2(radius * 0.7, -radius * 0.7),
		Vector2(radius * 0.7, radius * 0.7),
		Vector2(-radius * 0.7, radius * 0.7)
	])
	_owner.get_tree().current_scene.add_child(falling)

	var tween := _owner.create_tween()
	tween.tween_property(falling, "global_position", target_position, delay)
	await tween.finished

	if is_instance_valid(telegraph):
		telegraph.queue_free()

	if not is_instance_valid(_owner):
		if is_instance_valid(falling):
			falling.queue_free()
		return

	var hitbox := Area2D.new()
	hitbox.top_level = true
	hitbox.global_position = target_position
	hitbox.set("damage", _owner.attack_damage)
	hitbox.add_to_group("enemy_projectile")
	hitbox.set_meta("source_element", _owner.mage_element)

	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	hitbox.add_child(collision)

	_owner.get_tree().current_scene.add_child(hitbox)
	_track_projectile(hitbox)

	if is_instance_valid(falling):
		falling.queue_free()

	await _owner.get_tree().create_timer(0.12).timeout
	if is_instance_valid(hitbox):
		hitbox.queue_free()

func _spawn_projectile_at(spawn_position: Vector2, direction: Vector2, speed_scale: float, life_time: float, radius: float, tint: Color) -> void:
	var projectile := Area2D.new()
	projectile.top_level = true
	projectile.global_position = spawn_position
	projectile.set("damage", _owner.attack_damage)
	projectile.add_to_group("enemy_projectile")
	projectile.collision_layer = 1
	# Detect player hurtbox and player power projectiles (wind uses layer 4).
	projectile.collision_mask = 13
	projectile.set_meta("velocity", direction.normalized() * _owner.projectile_speed * speed_scale)
	projectile.set_meta("is_reflected", false)
	projectile.set_meta("owner_mage", _owner)
	projectile.set_meta("hit_radius", radius)
	projectile.set_meta("source_element", _owner.mage_element)
	projectile.set_meta("projectile_speed_base", _owner.projectile_speed)
	projectile.set_meta("windup_time", 0.28)

	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	projectile.add_child(collision)

	var poly := Polygon2D.new()
	poly.color = tint
	poly.polygon = PackedVector2Array([
		Vector2(-radius, -radius),
		Vector2(radius, -radius),
		Vector2(radius, radius),
		Vector2(-radius, radius)
	])
	projectile.add_child(poly)

	_owner.get_tree().current_scene.add_child(projectile)
	_track_projectile(projectile)

	projectile.area_entered.connect(func(area: Area2D) -> void:
		if area == null or not is_instance_valid(projectile):
			return
		var deflect_element := _get_deflect_element_from_area(area)
		if deflect_element != "":
			_reflect_projectile(projectile, poly, deflect_element, speed_scale)
			return
		if area.is_in_group("player_hurtbox") and not bool(projectile.get_meta("is_reflected")):
			projectile.queue_free()
	)

	projectile.body_entered.connect(func(body: Node2D) -> void:
		if body == null or not is_instance_valid(projectile):
			return
		var deflect_element := _get_deflect_element_from_body(body, projectile)
		if deflect_element != "":
			_reflect_projectile(projectile, poly, deflect_element, speed_scale)
	)

	_drive_projectile(projectile, life_time)

func _drive_projectile(projectile: Area2D, life_time: float) -> void:
	if _owner == null or not is_instance_valid(_owner):
		return
	_owner.call_deferred("_drive_projectile_async_component", projectile, life_time)

func drive_projectile_async(projectile: Area2D, life_time: float) -> void:
	while life_time > 0.0 and is_instance_valid(projectile):
		await projectile.get_tree().process_frame
		if not is_instance_valid(projectile):
			return
		var delta := projectile.get_process_delta_time()
		life_time -= delta
		var windup_time := float(projectile.get_meta("windup_time"))
		if windup_time > 0.0 and not bool(projectile.get_meta("is_reflected")):
			projectile.set_meta("windup_time", max(0.0, windup_time - delta))
			continue
		var vel: Vector2 = projectile.get_meta("velocity")
		projectile.global_position += vel * delta

		if bool(projectile.get_meta("is_reflected")):
			var owner = projectile.get_meta("owner_mage")
			if owner != null and is_instance_valid(owner):
				if projectile.global_position.distance_to(owner.global_position) <= float(projectile.get_meta("hit_radius")) + 12.0:
					if owner.has_method("receive_reflected_hit"):
						var reflected_element := str(projectile.get_meta("reflected_element"))
						owner.receive_reflected_hit(1, reflected_element)
					projectile.queue_free()
					return

	if is_instance_valid(projectile):
		projectile.queue_free()

func _get_deflect_element_from_area(area: Area2D) -> String:
	if area.is_in_group("wind_wave") or area.is_in_group("wind_reflector"):
		return "wind"
	if area.is_in_group("fire_reflector"):
		return "fire"
	if area.is_in_group("water_reflector"):
		return "water"
	return ""

func _get_deflect_element_from_body(body: Node2D, projectile: Area2D) -> String:
	if body != null and is_instance_valid(body):
		var dash_owner := body
		if not ("is_dashing" in dash_owner) and dash_owner.get_parent() != null:
			dash_owner = dash_owner.get_parent()
		if "is_dashing" in dash_owner and "playerAttribute" in dash_owner:
			if bool(dash_owner.is_dashing) and str(dash_owner.playerAttribute) == "wind":
				return "wind"
	if body.is_in_group("earth_reflector"):
		var source_element := str(projectile.get_meta("source_element"))
		if source_element != "earth":
			return ""
		return "earth"
	return ""

func _reflect_projectile(projectile: Area2D, poly: Polygon2D, element: String, speed_scale: float) -> void:
	if bool(projectile.get_meta("is_reflected")):
		return
	var source_element := str(projectile.get_meta("source_element"))
	if source_element != "" and element != source_element:
		return
	projectile.set_meta("is_reflected", true)
	projectile.set_meta("reflected_element", element)
	projectile.set_meta("windup_time", 0.0)
	var owner = projectile.get_meta("owner_mage")
	var new_velocity := -Vector2(projectile.get_meta("velocity")) * 1.2
	var base_projectile_speed := 100.0
	if projectile.has_meta("projectile_speed_base"):
		base_projectile_speed = float(projectile.get_meta("projectile_speed_base"))
	elif _owner != null and is_instance_valid(_owner):
		base_projectile_speed = _owner.projectile_speed
	if owner != null and is_instance_valid(owner):
		new_velocity = (owner.global_position - projectile.global_position).normalized() * base_projectile_speed * speed_scale * 1.25
	projectile.set_meta("velocity", new_velocity)
	projectile.remove_from_group("enemy_projectile")

	match element:
		"wind":
			poly.color = Color(0.75, 1.0, 0.75, 1.0)
		"fire":
			poly.color = Color(1.0, 0.65, 0.35, 1.0)
		"water":
			poly.color = Color(0.55, 0.8, 1.0, 1.0)
		"earth":
			poly.color = Color(0.75, 0.6, 0.4, 1.0)
		_:
			poly.color = Color(1, 1, 1, 1)

func _track_projectile(projectile: Node) -> void:
	_active_projectiles.append(projectile)