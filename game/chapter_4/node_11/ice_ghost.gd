extends CharacterBody2D

@export var move_speed: float = 45
@export var chase_range: float = 200
@export var attack_range: float = 160
@export var attack_windup: float = 0.35
@export var attack_cooldown: float = 1.4
@export var spike_scene: PackedScene = preload("res://game/chapter_4/node_11/ice_spikes.tscn")
@export var spike_speed: float = 220.0
@export var spike_spawn_offset: float = 18.0
@export var max_hp: int = 10

var _hp: int = 1
var _player: Node2D
var _attack_timer: float = 0.0
var _attack_ready_timer: float = 0.0
var _attack_direction: Vector2 = Vector2.LEFT
var _dialogue_active: bool = false

func _ready() -> void:
	_hp = max(1, max_hp)
	add_to_group("enemy")
	_player = _find_player()
	if DialogueManager != null:
		if not DialogueManager.dialogue_started.is_connected(_on_dialogue_started):
			DialogueManager.dialogue_started.connect(_on_dialogue_started)
		if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
			DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	_apply_dead_state()
	set_physics_process(not is_dead())


func _physics_process(_delta: float) -> void:
	if is_dead():
		velocity = Vector2.ZERO
		return

	if _dialogue_active:
		# Cancel queued attacks and stay still while dialogue is on screen.
		_attack_timer = 0.0
		velocity = Vector2.ZERO
		_update_animation(velocity)
		move_and_slide()
		return

	if _attack_ready_timer > 0.0:
		_attack_ready_timer = max(0.0, _attack_ready_timer - _delta)

	if _attack_timer > 0.0:
		_attack_timer = max(0.0, _attack_timer - _delta)
		velocity = Vector2.ZERO
		_update_animation(velocity)
		move_and_slide()
		if _attack_timer <= 0.0:
			_fire_spike(_attack_direction)
		return

	if _player == null or not is_instance_valid(_player):
		_player = _find_player()
		if _player == null:
			velocity = Vector2.ZERO
			_update_animation(velocity)
			move_and_slide()
			return

	var to_player := _player.global_position - global_position
	var distance_to_player := to_player.length()
	if distance_to_player <= attack_range and _attack_ready_timer <= 0.0:
		_attack_direction = to_player.normalized() if distance_to_player > 0.0001 else Vector2.LEFT
		_attack_timer = attack_windup
		_attack_ready_timer = attack_cooldown
		velocity = Vector2.ZERO
		_update_animation(velocity)
		move_and_slide()
		return

	if distance_to_player > chase_range:
		velocity = Vector2.ZERO
	else:
		velocity = to_player.normalized() * move_speed

	_update_animation(velocity)
	move_and_slide()


func mark_dead() -> void:
	GameState.chap4_node11_ice_ghost_dead = true
	GameState.save()
	SaveManager.save_game()
	_hp = 0
	_apply_dead_state()


func revive() -> void:
	GameState.chap4_node11_ice_ghost_dead = false
	_hp = max(1, max_hp)
	_attack_timer = 0.0
	_attack_ready_timer = 0.0
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
	return source_element == "fire" or source_element == "fire_small" or source_element == "fire_heavys"


func _apply_dead_state() -> void:
	if not GameState.chap4_node11_ice_ghost_dead:
		return

	queue_free()


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


func _fire_spike(direction: Vector2) -> void:
	if spike_scene == null:
		return

	var scene_root := get_tree().current_scene
	if scene_root == null:
		return

	var projectile_instance := spike_scene.instantiate()
	if projectile_instance == null or not (projectile_instance is Area2D):
		return

	var spike := projectile_instance as Area2D
	scene_root.add_child(spike)

	var fire_direction := direction.normalized() if direction.length_squared() > 0.0001 else Vector2.LEFT
	spike.global_position = global_position + fire_direction * spike_spawn_offset
	spike.rotation = fire_direction.angle()
	spike.set("direction", fire_direction)
	spike.set("speed", spike_speed)
	spike.set("damage", 1)
	spike.set("source_element", "ice")


func _on_dialogue_started(_resource = null) -> void:
	_dialogue_active = true


func _on_dialogue_ended(_resource = null) -> void:
	_dialogue_active = false
