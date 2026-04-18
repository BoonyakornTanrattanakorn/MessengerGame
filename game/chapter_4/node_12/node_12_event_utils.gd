extends RefCounted


static func register_fast_forward_balloon(fast_forward_balloons: Array[Node], balloon: Node) -> Array[Node]:
	if balloon == null:
		return fast_forward_balloons
	if fast_forward_balloons.has(balloon):
		return fast_forward_balloons
	fast_forward_balloons.append(balloon)
	return fast_forward_balloons


static func apply_fast_forward_to_dialogues(fast_forward_balloons: Array[Node], hold_ctrl_dialogue_speed_multiplier: float, is_fast: bool) -> Array[Node]:
	var still_valid: Array[Node] = []

	for balloon in fast_forward_balloons:
		if balloon == null or not is_instance_valid(balloon):
			continue
		still_valid.append(balloon)

		var dialogue_label: Node = balloon.find_child("DialogueLabel", true, false)
		if dialogue_label == null:
			continue
		if not dialogue_label.has_method("set"):
			continue

		if is_fast:
			dialogue_label.set("seconds_per_step", 0.02 / maxf(1.0, hold_ctrl_dialogue_speed_multiplier))
			dialogue_label.set("seconds_per_pause_step", 0.30 / maxf(1.0, hold_ctrl_dialogue_speed_multiplier))
		else:
			dialogue_label.set("seconds_per_step", 0.02)
			dialogue_label.set("seconds_per_pause_step", 0.30)

	return still_valid


static func is_fast_forward_pressed() -> bool:
	return Input.is_key_pressed(KEY_CTRL)


static func get_path_end_direction(path: Path2D, fallback_direction: Vector2, lookback_distance: float = 8.0) -> Vector2:
	if path == null or path.curve == null:
		return fallback_direction

	var path_length := path.curve.get_baked_length()
	if path_length <= 0.0:
		return fallback_direction

	var final_local_pos := path.curve.sample_baked(path_length, true)
	var final_world_pos := path.to_global(final_local_pos)
	var lookback := minf(path_length, lookback_distance)
	var pre_final_local_pos := path.curve.sample_baked(path_length - lookback, true)
	var pre_final_world_pos := path.to_global(pre_final_local_pos)
	var final_direction := (final_world_pos - pre_final_world_pos).normalized()
	if final_direction.length_squared() > 0.0001:
		return final_direction

	return fallback_direction


static func walk_entity_along_path(
	owner: Node,
	entity: Node2D,
	path: Path2D,
	move_speed: float,
	fast_forward_speed_multiplier: float,
	base_anim_speed_scale: float = 0.75
) -> Vector2:
	if owner == null or entity == null:
		return Vector2.DOWN
	if path == null or path.curve == null:
		owner.push_warning("Path is missing. Skipping path walk.")
		return Vector2.DOWN

	var curve := path.curve
	if curve.get_point_count() < 2:
		owner.push_warning("Path has too few points. Skipping path walk.")
		return Vector2.DOWN

	var path_length := curve.get_baked_length()
	if path_length <= 0.0:
		owner.push_warning("Path has zero baked length. Skipping path walk.")
		return Vector2.DOWN

	var original_speed := 0.0
	if entity.get("speed") != null:
		original_speed = float(entity.get("speed"))
	entity.set("speed", move_speed)

	var anim_sprite: AnimatedSprite2D = null
	var original_anim_speed := 1.0
	var sprite_candidate = entity.get("animated_sprite")
	if sprite_candidate is AnimatedSprite2D:
		anim_sprite = sprite_candidate
		original_anim_speed = anim_sprite.speed_scale
		anim_sprite.speed_scale = base_anim_speed_scale

	var initial_local_pos := curve.sample_baked(0.0, true)
	var initial_world_pos := path.to_global(initial_local_pos)
	entity.global_position = initial_world_pos

	var last_world_pos := initial_world_pos
	var last_direction := Vector2.DOWN
	var duration := path_length / maxf(1.0, move_speed)
	var tween := owner.create_tween()
	tween.tween_method(func(progress: float) -> void:
		var distance_along := progress * path_length
		var local_pos := curve.sample_baked(distance_along, true)
		var world_pos := path.to_global(local_pos)

		var direction := (world_pos - last_world_pos).normalized()
		if direction.length_squared() > 0.0001:
			last_direction = direction
			_set_entity_facing(entity, direction)
			if anim_sprite:
				var facing_suffix := _get_facing_suffix(entity, direction)
				if not facing_suffix.is_empty():
					var walk_anim := "walk " + facing_suffix
					if anim_sprite.animation != walk_anim:
						anim_sprite.play(walk_anim)

		entity.global_position = world_pos
		last_world_pos = world_pos
	, 0.0, 1.0, duration)

	while tween.is_running():
		var speed_multiplier := fast_forward_speed_multiplier if is_fast_forward_pressed() else 1.0
		tween.set_speed_scale(speed_multiplier)
		if anim_sprite:
			anim_sprite.speed_scale = base_anim_speed_scale * speed_multiplier
		await owner.get_tree().process_frame

	var final_local_pos := curve.sample_baked(path_length, true)
	var final_world_pos := path.to_global(final_local_pos)
	last_direction = get_path_end_direction(path, last_direction)

	entity.global_position = final_world_pos
	entity.set("velocity", Vector2.ZERO)
	entity.set("speed", original_speed)
	_set_entity_facing(entity, last_direction)

	if anim_sprite:
		anim_sprite.speed_scale = original_anim_speed
		var idle_suffix := _get_facing_suffix(entity, last_direction)
		if not idle_suffix.is_empty():
			anim_sprite.play("idle " + idle_suffix)

	return last_direction


static func _set_entity_facing(entity: Node, direction: Vector2) -> void:
	if entity.has_method("set_facing_direction"):
		entity.call("set_facing_direction", direction)


static func _get_facing_suffix(entity: Node, direction: Vector2) -> String:
	if entity.has_method("_facing_suffix"):
		return String(entity.call("_facing_suffix", direction))
	return ""
