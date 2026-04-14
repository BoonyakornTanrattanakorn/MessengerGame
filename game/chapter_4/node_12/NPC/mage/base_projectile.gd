extends Area2D
class_name Node12MageBaseProjectile

@export var windup_time: float = 0.0
@export var base_speed: float = 300.0
@export var despawn_radius: float = 1000.0

var damage: float = 1
var source_element: String = ""
var owner_mage: Node = null
var launch_direction: Vector2 = Vector2.RIGHT

var _velocity: Vector2 = Vector2.ZERO
var _is_reflected: bool = false
var _reflected_element: String = ""
var _telegraphing: bool = true

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("enemy_projectile")
	collision_layer = 1
	# Detect player hurtbox and reflector bodies.
	collision_mask = 13

	_velocity = launch_direction.normalized() * base_speed
	set_telegraph(true)

	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func set_telegraph(enabled: bool) -> void:
	_telegraphing = enabled
	if _sprite != null:
		_sprite.modulate = _get_telegraph_tint() if enabled else Color(1, 1, 1, 1)

func shoot() -> void:
	set_telegraph(false)

func aim_at(target_position: Vector2) -> void:
	if _is_reflected:
		return
	var aim_dir := _get_aim_direction(target_position)
	if aim_dir.length_squared() <= 0.0001:
		return
	set_launch_direction(aim_dir.normalized())

func set_launch_direction(direction: Vector2) -> void:
	if _is_reflected:
		return
	if direction.length_squared() <= 0.0001:
		return
	launch_direction = direction.normalized()
	_velocity = launch_direction * base_speed
	rotation = launch_direction.angle()

func _physics_process(delta: float) -> void:
	if windup_time > 0.0 and not _is_reflected:
		windup_time = max(0.0, windup_time - delta)
		return
	if _telegraphing and not _is_reflected:
		return

	if not _is_reflected:
		_update_guidance(delta)
	elif owner_mage != null and is_instance_valid(owner_mage):
		var to_owner = owner_mage.global_position - global_position
		if to_owner.length_squared() > 0.0001:
			var reflected_speed = max(base_speed * 1.25, _velocity.length())
			launch_direction = to_owner.normalized()
			_velocity = launch_direction * reflected_speed
			rotation = launch_direction.angle()

	var start_pos := global_position
	var end_pos := start_pos + _velocity * delta
	if _check_swept_hits(start_pos, end_pos):
		return
	global_position = end_pos

	if _is_reflected and owner_mage != null and is_instance_valid(owner_mage):
		var hit_radius := 14.0
		if _collision != null and _collision.shape is CircleShape2D:
			hit_radius = (_collision.shape as CircleShape2D).radius + 12.0
		if global_position.distance_to(owner_mage.global_position) <= hit_radius:
			if owner_mage.has_method("receive_reflected_hit"):
				owner_mage.call("receive_reflected_hit", damage, _reflected_element)
			queue_free()
			return

	if owner_mage == null or global_position.distance_to(owner_mage.global_position) >= despawn_radius:
		queue_free()

func _check_swept_hits(start_pos: Vector2, end_pos: Vector2) -> bool:
	var radius := _get_hit_radius()
	var travel := end_pos - start_pos
	var distance := travel.length()
	if distance <= 0.0001:
		return false

	var step_size = max(1.0, radius * 0.75)
	var steps = max(1, int(ceil(distance / step_size)))

	for i in range(1, steps + 1):
		var t := float(i) / float(steps)
		var sample_pos := start_pos.lerp(end_pos, t)
		if _handle_shape_hits_at(sample_pos, radius):
			return true
	return false

func _handle_shape_hits_at(sample_pos: Vector2, radius: float) -> bool:
	var shape_query := PhysicsShapeQueryParameters2D.new()
	var hit_shape := CircleShape2D.new()
	hit_shape.radius = radius
	shape_query.shape = hit_shape
	shape_query.transform = Transform2D(0.0, sample_pos)
	shape_query.collision_mask = collision_mask
	shape_query.collide_with_areas = true
	shape_query.collide_with_bodies = true
	shape_query.exclude = [get_rid()]

	var space_state := get_world_2d().direct_space_state
	var results := space_state.intersect_shape(shape_query, 8)
	for result in results:
		if not result.has("collider"):
			continue
		var collider = result["collider"]
		if collider == null:
			continue

		if collider is Area2D:
			var area := collider as Area2D
			if area.is_in_group("player_hurtbox") and not _is_reflected:
				_apply_damage_to_hurtbox(area)
				queue_free()
				return true

		if collider is Node2D:
			var body := collider as Node2D
			if not _is_reflected and _can_reflect_from_body(body):
				_reflect_to_owner(_get_reflect_element())
				return true

	return false

func _get_hit_radius() -> float:
	if _collision != null and _collision.shape is CircleShape2D:
		return (_collision.shape as CircleShape2D).radius
	return 4.0

func _apply_damage_to_hurtbox(area: Area2D) -> void:
	if area == null:
		return
	var target := area.get_parent()
	if target == null:
		return

	var hp_component = target.get("health_component")
	if hp_component != null and hp_component.has_method("take_damage"):
		hp_component.take_damage(damage)

func _on_area_entered(area: Area2D) -> void:
	if area == null:
		return
	if area.is_in_group("player_hurtbox") and not _is_reflected:
		_apply_damage_to_hurtbox(area)
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body == null:
		return
	if _is_reflected:
		return
	if not _can_reflect_from_body(body):
		return

	_reflect_to_owner(_get_reflect_element())

func _reflect_to_owner(element: String) -> void:
	_is_reflected = true
	_reflected_element = element
	_telegraphing = false
	remove_from_group("enemy_projectile")

	if _sprite != null:
		_sprite.modulate = _get_reflected_tint()

	if owner_mage != null and is_instance_valid(owner_mage):
		launch_direction = (owner_mage.global_position - global_position).normalized()
		_velocity = launch_direction * base_speed * 1.25
		rotation = launch_direction.angle()
	else:
		_velocity = -_velocity * 1.2
		if _velocity.length_squared() > 0.0001:
			launch_direction = _velocity.normalized()
			rotation = launch_direction.angle()

func _get_aim_direction(target_position: Vector2) -> Vector2:
	return target_position - global_position

func _update_guidance(_delta: float) -> void:
	pass

func _can_reflect_from_body(body: Node2D) -> bool:
	if body == null:
		return false
	if source_element == "":
		return false
	var reflector_group := "%s_reflector" % source_element
	return body.is_in_group(reflector_group)

func _get_reflect_element() -> String:
	return source_element

func _get_telegraph_tint() -> Color:
	return Color(1.0, 0.83, 0.62, 0.75)

func _get_reflected_tint() -> Color:
	return Color(0.75, 0.6, 0.4, 1.0)
