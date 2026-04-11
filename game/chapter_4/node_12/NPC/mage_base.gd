extends CharacterBody2D
class_name Chapter4MageBase

@export var mage_element: String = "earth"
@export var weakness_element: String = "fire"
@export var max_hp: int = 3
@export var attack_damage: int = 1
@export var attack_interval: float = 2.2
@export var projectile_speed: float = 220.0
@export var vulnerability_duration: float = 1.2
@export var attack_range: float = 380.0

var _hp: int = 0
var _attack_cooldown: float = 0.0
var _vulnerability_timer: float = 0.0
var _is_casting: bool = false
var _player_ref: Node = null

static var _turn_roster: Array = []
static var _turn_index: int = 0
static var _turn_pause: float = 0.0
static var _last_turn_frame: int = -1

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	_hp = max_hp
	add_to_group("enemy")
	_player_ref = _find_player()
	_register_in_turn_roster()

func _exit_tree() -> void:
	_unregister_from_turn_roster()

func _physics_process(delta: float) -> void:
	if _hp <= 0:
		return

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

	if global_position.distance_to(_player_ref.global_position) > attack_range:
		return

	_is_casting = true
	perform_attack_pattern()

func perform_attack_pattern() -> void:
	# Implement in child scripts.
	finish_casting(attack_interval)

func begin_vulnerability_window(duration_override: float = -1.0) -> void:
	var duration := vulnerability_duration if duration_override < 0.0 else duration_override
	_vulnerability_timer = max(_vulnerability_timer, duration)
	modulate = Color(1.0, 0.8, 0.8)

func finish_casting(next_cooldown: float = attack_interval) -> void:
	_attack_cooldown = max(0.1, next_cooldown)
	_is_casting = false
	_pass_turn(0.35)
	if _vulnerability_timer <= 0.0:
		modulate = Color(1, 1, 1)

func _process(_delta: float) -> void:
	if _vulnerability_timer <= 0.0 and modulate != Color(1, 1, 1):
		modulate = Color(1, 1, 1)

func take_damage(amount: int = 1, source_element: String = "") -> void:
	if _hp <= 0:
		return

	var inferred_element := source_element
	if inferred_element == "":
		var player = _find_player()
		if player and player.has_method("get"):
			inferred_element = str(player.get("playerAttribute"))

	if inferred_element != weakness_element:
		return

	if _vulnerability_timer <= 0.0:
		return

	_hp -= max(1, amount)
	if _hp <= 0:
		die()

func receive_reflected_hit(amount: int = 1, source_element: String = "wind") -> void:
	if _hp <= 0:
		return
	begin_vulnerability_window(0.8)
	_hp -= max(1, amount)
	if _hp <= 0:
		die()

func die() -> void:
	_hp = 0
	_unregister_from_turn_roster()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	await tween.finished
	queue_free()

func spawn_projectile(direction: Vector2, speed_scale: float = 1.0, life_time: float = 2.2, radius: float = 9.0, tint: Color = Color(1, 1, 1)) -> void:
	var projectile := Area2D.new()
	projectile.top_level = true
	projectile.global_position = global_position
	projectile.set("damage", attack_damage)
	projectile.add_to_group("enemy_projectile")
	projectile.collision_layer = 1
	projectile.collision_mask = 9
	projectile.set_meta("velocity", direction.normalized() * projectile_speed * speed_scale)
	projectile.set_meta("is_reflected", false)
	projectile.set_meta("owner_mage", self)
	projectile.set_meta("hit_radius", radius)

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

	projectile.area_entered.connect(func(area: Area2D) -> void:
		if area == null or not is_instance_valid(projectile):
			return
		if area.is_in_group("wind_wave"):
			if not bool(projectile.get_meta("is_reflected")):
				projectile.set_meta("is_reflected", true)
				projectile.set_meta("velocity", -Vector2(projectile.get_meta("velocity")) * 1.2)
				projectile.remove_from_group("enemy_projectile")
				poly.color = Color(0.75, 1.0, 0.75, 1.0)
			return
		if area.is_in_group("player_hurtbox") and not bool(projectile.get_meta("is_reflected")):
			projectile.queue_free()
	)

	_drive_projectile(projectile, life_time)

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
		var vel: Vector2 = projectile.get_meta("velocity")
		projectile.global_position += vel * delta

		if bool(projectile.get_meta("is_reflected")):
			for body in get_tree().get_nodes_in_group("enemy"):
				if body == null or not is_instance_valid(body) or body == self:
					continue
				if projectile.global_position.distance_to(body.global_position) <= float(projectile.get_meta("hit_radius")) + 12.0:
					if body.has_method("receive_reflected_hit"):
						body.receive_reflected_hit(1, "wind")
					elif body.has_method("take_damage"):
						body.take_damage(1, "wind")
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
