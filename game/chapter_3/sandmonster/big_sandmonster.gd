extends "res://game/chapter_3/sandmonster/sandmonster.gd"

const ATTACK_RANGE: float = 80.0
const ATTACK_DAMAGE: int = 2
const ATTACK_COOLDOWN: float = 2.0

var attacking: bool = false
var attack_timer: float = 0.0

func _ready():
	hp = 15
	move_speed = 40.0
	super._ready()

func _physics_process(delta):
	if state == State.DUST:
		return

	if attack_timer > 0.0:
		attack_timer -= delta

	if state == State.DRIED:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if player != null and attack_timer <= 0.0:
		var dist = global_position.distance_to(player.global_position)
		if dist <= ATTACK_RANGE:
			_start_attack()
			return

	super._physics_process(delta)

func _start_attack():
	attacking = true
	velocity = Vector2.ZERO
	animated_sprite.play("attack")
	await animated_sprite.animation_finished
	_do_attack_hit()

func _do_attack_hit():
	if player != null and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= ATTACK_RANGE:
			if player.has_node("HealthComponent"):
				player.get_node("HealthComponent").take_damage(ATTACK_DAMAGE)
			elif player.has_method("take_damage"):
				player.take_damage(ATTACK_DAMAGE)
	attacking = false
	attack_timer = ATTACK_COOLDOWN
	if state == State.NORMAL:
		animated_sprite.play("normal")
