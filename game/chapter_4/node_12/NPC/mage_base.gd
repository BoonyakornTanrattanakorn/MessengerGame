extends CharacterBody2D
class_name Chapter4MageBase

@export var mage_element: String = "earth"
@export var weakness_element: String = "fire"
@export var required_reflect_element: String = "wind"
@export var max_hp: int = 3
@export var attack_damage: int = 1
@export var attack_interval: float = 2.2
@export var projectile_speed: float = 220.0
@export var vulnerability_duration: float = 1.2
@export var attack_range: float = 1000.0

@export_group("Difficulty Tuning")
@export var timing_multiplier: float = 1.0
@export var cooldown_multiplier: float = 1.0
@export var projectile_speed_multiplier: float = 1.0
@export var attack_range_multiplier: float = 1.0
@export var incoming_damage_multiplier: float = 1.0
@export var reflected_damage_taken_multiplier: float = 1.0
@export var projectile_windup_time: float = 0.28
@export var reflected_speed_multiplier: float = 1.25
@export var turn_pass_delay: float = 0.35

var _hp: int = 0
var _attack_cooldown: float = 0.0
var _vulnerability_timer: float = 0.0
var _is_casting: bool = false
var _player_ref: Node = null
var _barrier_phase: float = 0.0
var _active_projectiles: Array = []

var _barrier_root: Node2D = null
var _barrier_ring: Line2D = null
var _barrier_fill: Polygon2D = null

var _health_root: Node2D = null
var _health_bg: Polygon2D = null
var _health_fill: Polygon2D = null

static var _turn_roster: Array = []
static var _turn_index: int = 0
static var _turn_pause: float = 0.0
static var _last_turn_frame: int = -1

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	_hp = max_hp
	add_to_group("enemy")
	_player_ref = _find_player()
	_create_health_bar_visual()
	_update_health_bar_visual()
	_create_barrier_visual()
	_register_in_turn_roster()

func _exit_tree() -> void:
	_unregister_from_turn_roster()

func _physics_process(delta: float) -> void:
	if _hp <= 0:
		return

	_active_projectiles = _active_projectiles.filter(func(p): return p != null and is_instance_valid(p))

	if _vulnerability_timer > 0.0:
		_vulnerability_timer -= delta

	if _attack_cooldown > 0.0:
		_attack_cooldown = max(0.0, _attack_cooldown - delta)

	_update_turn_state(delta)
	if not _is_my_turn():
		return

	if _is_casting:
		return

	if _attack_cooldown > 0.0:
		finish_casting(0.2)
		return

	if _player_ref == null or not is_instance_valid(_player_ref):
		_player_ref = _find_player()
		if _player_ref == null:
			return

	if global_position.distance_to(_player_ref.global_position) > attack_range * attack_range_multiplier:
		return

	_is_casting = true
	perform_attack_pattern()

func perform_attack_pattern() -> void:
	# Implement in child scripts.
	finish_casting_scaled(attack_interval)

func begin_vulnerability_window(duration_override: float = -1.0) -> void:
	var duration := vulnerability_duration if duration_override < 0.0 else duration_override
	_vulnerability_timer = max(_vulnerability_timer, scaled_time(duration))
	modulate = Color(1.0, 0.8, 0.8)

func finish_casting(next_cooldown: float = attack_interval) -> void:
	_attack_cooldown = max(0.1, scaled_cooldown(next_cooldown))
	_is_casting = false
	_pass_turn(turn_pass_delay)
	if _vulnerability_timer <= 0.0:
		modulate = Color(1, 1, 1)

func finish_casting_scaled(next_cooldown: float = attack_interval) -> void:
	finish_casting(next_cooldown)

func _process(_delta: float) -> void:
	if not _is_vulnerable() and modulate != Color(1, 1, 1):
		modulate = Color(1, 1, 1)
	_update_barrier_visual(_delta)

func take_damage(amount: int = 1, source_element: String = "") -> void:
	# Puzzle rule: direct player attacks never damage mages.
	return

func receive_reflected_hit(amount: int = 1, source_element: String = "wind") -> void:
	if _hp <= 0:
		return
	if not _is_vulnerable():
		return
	if required_reflect_element != "" and source_element != required_reflect_element:
		return
	_hp -= _scale_int(amount, reflected_damage_taken_multiplier)
	_update_health_bar_visual()
	if _hp <= 0:
		die()

func die() -> void:
	_hp = 0
	_update_health_bar_visual()
	_unregister_from_turn_roster()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	await tween.finished
	queue_free()

func spawn_projectile(direction: Vector2, speed_scale: float = 1.0, life_time: float = 2.2, radius: float = 9.0, tint: Color = Color(1, 1, 1)) -> void:
	var projectile := Area2D.new()
	projectile.top_level = true
	projectile.global_position = global_position
	projectile.set("damage", _scale_int(attack_damage, incoming_damage_multiplier))
	projectile.add_to_group("enemy_projectile")
	projectile.collision_layer = 1
	projectile.collision_mask = 9
	projectile.set_meta("velocity", direction.normalized() * projectile_speed * projectile_speed_multiplier * speed_scale)
	projectile.set_meta("is_reflected", false)
	projectile.set_meta("owner_mage", self)
	projectile.set_meta("hit_radius", radius)
	projectile.set_meta("source_element", mage_element)
	projectile.set_meta("windup_time", scaled_time(projectile_windup_time))

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

	get_tree().current_scene.add_child(projectile)
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

	_drive_projectile(projectile, scaled_time(life_time))

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
	get_tree().current_scene.add_child(marker)
	await get_tree().create_timer(delay).timeout
	if not is_instance_valid(self):
		if is_instance_valid(marker):
			marker.queue_free()
		return
	for i in range(ring_count):
		var angle := TAU * float(i) / float(max(1, ring_count))
		spawn_projectile(Vector2.RIGHT.rotated(angle), speed_scale, 1.5, 8.0, tint)
	if is_instance_valid(marker):
		marker.queue_free()

func summon_falling_strike(target_position: Vector2, delay: float = 0.7, radius: float = 14.0, tint: Color = Color(1, 1, 1), fall_height: float = 120.0) -> void:
	var telegraph := Polygon2D.new()
	telegraph.color = Color(tint.r, tint.g, tint.b, 0.25)
	telegraph.global_position = target_position
	telegraph.polygon = PackedVector2Array([
		Vector2(-radius, -radius),
		Vector2(radius, -radius),
		Vector2(radius, radius),
		Vector2(-radius, radius)
	])
	get_tree().current_scene.add_child(telegraph)

	var falling := Polygon2D.new()
	falling.color = Color(tint.r, tint.g, tint.b, 0.95)
	falling.global_position = target_position + Vector2(0, -fall_height)
	falling.polygon = PackedVector2Array([
		Vector2(-radius * 0.7, -radius * 0.7),
		Vector2(radius * 0.7, -radius * 0.7),
		Vector2(radius * 0.7, radius * 0.7),
		Vector2(-radius * 0.7, radius * 0.7)
	])
	get_tree().current_scene.add_child(falling)

	var tween := create_tween()
	tween.tween_property(falling, "global_position", target_position, delay)
	await tween.finished

	if is_instance_valid(telegraph):
		telegraph.queue_free()

	if not is_instance_valid(self):
		if is_instance_valid(falling):
			falling.queue_free()
		return

	var hitbox := Area2D.new()
	hitbox.top_level = true
	hitbox.global_position = target_position
	hitbox.set("damage", _scale_int(attack_damage, incoming_damage_multiplier))
	hitbox.add_to_group("enemy_projectile")
	hitbox.set_meta("source_element", mage_element)

	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	hitbox.add_child(collision)

	get_tree().current_scene.add_child(hitbox)
	_track_projectile(hitbox)

	if is_instance_valid(falling):
		falling.queue_free()

	await get_tree().create_timer(0.12).timeout
	if is_instance_valid(hitbox):
		hitbox.queue_free()

func predict_player_position(lead_time: float = 0.45) -> Vector2:
	if _player_ref == null or not is_instance_valid(_player_ref):
		_player_ref = _find_player()
	if _player_ref == null:
		return global_position + Vector2(0, 64)

	var velocity := Vector2.ZERO
	if "velocity" in _player_ref:
		velocity = _player_ref.velocity
	return _player_ref.global_position + velocity * lead_time

func get_direction_to_player() -> Vector2:
	if _player_ref == null or not is_instance_valid(_player_ref):
		_player_ref = _find_player()
	if _player_ref == null:
		return Vector2.DOWN
	return (_player_ref.global_position - global_position).normalized()

func _register_in_turn_roster() -> void:
	if _turn_roster.has(self):
		return
	_turn_roster.append(self)

func _unregister_from_turn_roster() -> void:
	var idx := _turn_roster.find(self)
	if idx == -1:
		return
	_turn_roster.remove_at(idx)
	if _turn_roster.is_empty():
		_turn_index = 0
		_turn_pause = 0.0
		return
	if idx < _turn_index:
		_turn_index -= 1
	_turn_index %= _turn_roster.size()

func _update_turn_state(delta: float) -> void:
	var frame := Engine.get_physics_frames()
	if frame == _last_turn_frame:
		return
	_last_turn_frame = frame

	_turn_roster = _turn_roster.filter(func(m): return m != null and is_instance_valid(m) and m._hp > 0)
	if _turn_roster.is_empty():
		_turn_index = 0
		_turn_pause = 0.0
		return

	_turn_index %= _turn_roster.size()
	_turn_pause = max(0.0, _turn_pause - delta)

func _is_my_turn() -> bool:
	if _turn_roster.is_empty() or _turn_pause > 0.0:
		return false
	if _turn_index < 0 or _turn_index >= _turn_roster.size():
		return false
	return _turn_roster[_turn_index] == self

func _pass_turn(delay: float = 0.35) -> void:
	if _turn_roster.is_empty():
		return
	var my_index := _turn_roster.find(self)
	if my_index == -1:
		return
	_turn_index = (my_index + 1) % _turn_roster.size()
	_turn_pause = max(0.0, delay)

func _drive_projectile(projectile: Area2D, life_time: float) -> void:
	call_deferred("_drive_projectile_async", projectile, life_time)

func _drive_projectile_async(projectile: Area2D, life_time: float) -> void:
	while life_time > 0.0 and is_instance_valid(projectile):
		await get_tree().process_frame
		if not is_instance_valid(projectile):
			return
		var delta := get_process_delta_time()
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

func _find_player() -> Node:
	var root := get_tree().current_scene
	if root == null:
		return null
	var by_name := root.find_child("Player", true, false)
	if by_name != null:
		return by_name
	return root.find_child("player", true, false)

func _get_deflect_element_from_area(area: Area2D) -> String:
	if area.is_in_group("wind_wave") or area.is_in_group("wind_reflector"):
		return "wind"
	if area.is_in_group("fire_reflector"):
		return "fire"
	if area.is_in_group("water_reflector"):
		return "water"
	return ""

func _get_deflect_element_from_body(body: Node2D, projectile: Area2D) -> String:
	if body.is_in_group("earth_reflector"):
		var source_element := str(projectile.get_meta("source_element"))
		if source_element != "earth":
			return ""
		return "earth"
	return ""

func _reflect_projectile(projectile: Area2D, poly: Polygon2D, element: String, speed_scale: float) -> void:
	if bool(projectile.get_meta("is_reflected")):
		return
	if element == "earth":
		var source_element := str(projectile.get_meta("source_element"))
		if source_element != "earth":
			return
	projectile.set_meta("is_reflected", true)
	projectile.set_meta("reflected_element", element)
	projectile.set_meta("windup_time", 0.0)
	var owner = projectile.get_meta("owner_mage")
	var new_velocity := -Vector2(projectile.get_meta("velocity")) * 1.2
	if owner != null and is_instance_valid(owner):
		new_velocity = (owner.global_position - projectile.global_position).normalized() * projectile_speed * projectile_speed_multiplier * speed_scale * reflected_speed_multiplier
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

func _has_active_projectiles() -> bool:
	_active_projectiles = _active_projectiles.filter(func(p): return p != null and is_instance_valid(p))
	return not _active_projectiles.is_empty()

func _is_vulnerable() -> bool:
	return _vulnerability_timer > 0.0 or _has_active_projectiles()

func _create_barrier_visual() -> void:
	_barrier_root = Node2D.new()
	_barrier_root.name = "InvincibleBarrier"
	_barrier_root.visible = true
	add_child(_barrier_root)

	_barrier_fill = Polygon2D.new()
	_barrier_fill.color = Color(0.55, 0.85, 1.0, 0.13)
	_barrier_fill.polygon = _build_circle_points(26.0, 28)
	_barrier_root.add_child(_barrier_fill)

	_barrier_ring = Line2D.new()
	_barrier_ring.width = 2.5
	_barrier_ring.default_color = Color(0.65, 0.95, 1.0, 0.8)
	_barrier_ring.closed = true
	_barrier_ring.points = _build_circle_points(28.0, 28)
	_barrier_root.add_child(_barrier_ring)

func _build_circle_points(radius: float, point_count: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(point_count):
		var t := TAU * float(i) / float(point_count)
		pts.append(Vector2(cos(t), sin(t)) * radius)
	return pts

func _update_barrier_visual(delta: float) -> void:
	if _barrier_root == null:
		return

	# Barrier is visible when mage is invincible (outside attack window).
	var invincible := (not _is_vulnerable()) and _hp > 0
	_barrier_root.visible = invincible
	if not invincible:
		return

	_barrier_phase += delta * 3.0
	_barrier_root.rotation = sin(_barrier_phase * 0.35) * 0.08
	var pulse := 0.85 + 0.15 * (0.5 + 0.5 * sin(_barrier_phase * 2.0))
	_barrier_root.scale = Vector2.ONE * pulse

	if _barrier_ring != null:
		_barrier_ring.default_color = Color(0.65, 0.95, 1.0, 0.65 + 0.2 * (0.5 + 0.5 * sin(_barrier_phase * 2.4)))
	if _barrier_fill != null:
		_barrier_fill.color = Color(0.55, 0.85, 1.0, 0.08 + 0.08 * (0.5 + 0.5 * sin(_barrier_phase * 1.8)))

func _create_health_bar_visual() -> void:
	_health_root = Node2D.new()
	_health_root.name = "HealthBar"
	_health_root.position = Vector2(0, -34)
	add_child(_health_root)

	var bar_w := 34.0
	var bar_h := 5.0

	_health_bg = Polygon2D.new()
	_health_bg.color = Color(0.1, 0.1, 0.1, 0.85)
	_health_bg.polygon = PackedVector2Array([
		Vector2(-bar_w * 0.5 - 1.0, -bar_h * 0.5 - 1.0),
		Vector2(bar_w * 0.5 + 1.0, -bar_h * 0.5 - 1.0),
		Vector2(bar_w * 0.5 + 1.0, bar_h * 0.5 + 1.0),
		Vector2(-bar_w * 0.5 - 1.0, bar_h * 0.5 + 1.0)
	])
	_health_root.add_child(_health_bg)

	_health_fill = Polygon2D.new()
	_health_fill.color = Color(0.95, 0.25, 0.25, 0.95)
	_health_root.add_child(_health_fill)

func _update_health_bar_visual() -> void:
	if _health_root == null or _health_fill == null:
		return

	if _hp <= 0:
		_health_root.visible = false
		return

	_health_root.visible = true
	var bar_w := 34.0
	var bar_h := 5.0
	var ratio = clamp(float(_hp) / float(max(1, max_hp)), 0.0, 1.0)
	var left := -bar_w * 0.5
	var right = left + bar_w * ratio

	_health_fill.polygon = PackedVector2Array([
		Vector2(left, -bar_h * 0.5),
		Vector2(right, -bar_h * 0.5),
		Vector2(right, bar_h * 0.5),
		Vector2(left, bar_h * 0.5)
	])

func scaled_time(seconds: float) -> float:
	return max(0.01, seconds * timing_multiplier)

func scaled_cooldown(seconds: float) -> float:
	return max(0.05, seconds * cooldown_multiplier)

func wait_scaled(seconds: float) -> void:
	await get_tree().create_timer(scaled_time(seconds)).timeout

func _scale_int(value: int, factor: float) -> int:
	return max(1, int(round(float(max(1, value)) * factor)))
