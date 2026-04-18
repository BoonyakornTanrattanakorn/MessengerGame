extends CharacterBody2D

@export var move_speed: float = 45
@export var chase_range: float = 260
@export var max_hp: int = 10

var _hp: int = 1
var _player: Node2D

func _ready() -> void:
	_hp = max(1, max_hp)
	add_to_group("enemy")
	_player = _find_player()
	_apply_dead_state()
	set_physics_process(not is_dead())


func _physics_process(_delta: float) -> void:
	if is_dead():
		velocity = Vector2.ZERO
		return

	if _player == null or not is_instance_valid(_player):
		_player = _find_player()
		if _player == null:
			velocity = Vector2.ZERO
			_update_animation(velocity)
			move_and_slide()
			return

	var to_player := _player.global_position - global_position
	if to_player.length() > chase_range:
		velocity = Vector2.ZERO
	else:
		velocity = to_player.normalized() * move_speed

	_update_animation(velocity)
	move_and_slide()


func mark_dead() -> void:
	GameState.chap4_node11_ice_ghost_dead = true
	_hp = 0
	_apply_dead_state()


func revive() -> void:
	GameState.chap4_node11_ice_ghost_dead = false
	_hp = max(1, max_hp)
	show()
	set_process(true)
	set_physics_process(true)
	set_process_input(true)
	set_process_unhandled_input(true)
	set_process_unhandled_key_input(true)

	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape != null:
		collision_shape.disabled = false


func is_dead() -> bool:
	return GameState.chap4_node11_ice_ghost_dead


func take_damage(amount: int, source_element: String = "") -> void:
	if is_dead():
		return
	if not _is_fire_source(source_element):
		return
	if amount <= 0:
		return

	_hp -= amount
	if _hp <= 0:
		mark_dead()


func _is_fire_source(source_element: String) -> bool:
	return source_element == "fire" or source_element == "fire_small" or source_element == "fire_heavy"


func _apply_dead_state() -> void:
	if not GameState.chap4_node11_ice_ghost_dead:
		return

	hide()
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	set_process_unhandled_input(false)
	set_process_unhandled_key_input(false)

	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape != null:
		collision_shape.disabled = true


func _find_player() -> Node2D:
	var root := get_tree().current_scene
	if root == null:
		return null

	var player_by_name := root.find_child("Player", true, false)
	if player_by_name is Node2D:
		return player_by_name as Node2D

	var player_lower := root.find_child("player", true, false)
	if player_lower is Node2D:
		return player_lower as Node2D

	return null


func _update_animation(direction: Vector2) -> void:
	var sprite := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		return

	if direction.length_squared() < 0.001:
		sprite.stop()
		return

	if abs(direction.x) > abs(direction.y):
		sprite.play("right" if direction.x > 0.0 else "left")
	else:
		sprite.play("down" if direction.y > 0.0 else "up")
