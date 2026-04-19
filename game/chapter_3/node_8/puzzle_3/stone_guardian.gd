extends CharacterBody2D

signal guardian_defeated

var hp: int = 10
var max_hp: int = 10
var player: Node2D = null
var speed: float = 60.0

var shoot_timer: float = 0.0
const SHOOT_INTERVAL: float = 2.5

var stun_timer: float = 0.0
const STUN_DURATION: float = 0.4

var is_dead: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@export var dead_texture: Texture2D

func _ready() -> void:
	add_to_group("enemy")
	player = get_tree().get_first_node_in_group("player")
	set_physics_process(false)

func take_damage(amount: int, source: String = "") -> void:
	if is_dead:
		return
	hp -= amount
	stun_timer = STUN_DURATION
	modulate = Color(0.3, 0.7, 1.0)
	if hp <= 0:
		_die()

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if stun_timer > 0.0:
		stun_timer -= delta
		if stun_timer <= 0.0:
			modulate = Color.WHITE
		return

	_chase_player()

	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot_timer = SHOOT_INTERVAL
		_shoot_sand()

func _chase_player() -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
	var dir := (player.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()

func _shoot_sand() -> void:
	if not is_instance_valid(player):
		return
	var ball := preload("res://game/chapter_3/node_8/puzzle_3/sand_ball.gd").new()
	ball.direction = (player.global_position - global_position).normalized()
	ball.global_position = global_position

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	shape.shape = circle
	ball.add_child(shape)

	var s := Sprite2D.new()
	s.texture = load("res://assets/sprites/golem_boss/mana_ball.png")
	s.modulate = Color(0.85, 0.65, 0.3)
	s.scale = Vector2(0.33, 0.33)
	ball.add_child(s)

	get_tree().current_scene.add_child(ball)

func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	modulate = Color.WHITE
	if sprite and dead_texture:
		sprite.texture = dead_texture
	guardian_defeated.emit()
	await get_tree().create_timer(1.0).timeout
	queue_free()
