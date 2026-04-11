extends CharacterBody2D

signal gem_collected(amount)
signal health_changed(new_health)
signal player_died

const GRAVITY = 1800.0
const JUMP_FORCE = -320.0
const DOUBLE_JUMP_FORCE = -300.0
const SLIDE_DURATION = 0.6
const RUN_SPEED = 100.0

@onready var anim = $AnimatedSprite2D
@onready var stand_shape = $CollisionShape2D
@onready var slide_shape = $SlideShape

enum State { RUN, JUMP, DOUBLE_JUMP, SLIDE, HURT }
var state = State.RUN
var can_double_jump = false
var slide_timer = 0.0
var health = 3
var is_invincible = false
var invincible_timer = 0.0

func _physics_process(delta):
	velocity.x = RUN_SPEED
	apply_gravity(delta)
	handle_input(delta)
	handle_timers(delta)
	move_and_slide()
	update_animation()

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		# Cancel slide if player falls off a ledge
		if state == State.SLIDE:
			stop_slide()
			state = State.JUMP
	else:
		if state == State.JUMP or state == State.DOUBLE_JUMP:
			state = State.RUN
		can_double_jump = false

func handle_input(delta):
	if state == State.HURT:
		return

	# Jump / Double Jump
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or state == State.SLIDE:
			jump()
		elif can_double_jump:
			double_jump()

	# Slide — start when pressed
	if Input.is_action_just_pressed("slide") and is_on_floor():
		start_slide()

	# Stop slide when released
	if Input.is_action_just_released("slide") and state == State.SLIDE:
		stop_slide()
		state = State.RUN

func jump():
	velocity.y = JUMP_FORCE
	state = State.JUMP
	can_double_jump = true
	stop_slide()

func double_jump():
	velocity.y = DOUBLE_JUMP_FORCE
	state = State.DOUBLE_JUMP
	can_double_jump = false

func start_slide():
	state = State.SLIDE
	slide_timer = SLIDE_DURATION
	stand_shape.disabled = true
	slide_shape.disabled = false

func stop_slide():
	stand_shape.disabled = false
	slide_shape.disabled = true

func handle_timers(delta):
	if is_invincible:
		invincible_timer -= delta
		# Flash effect
		modulate.a = 0.5 if fmod(invincible_timer, 0.2) < 0.1 else 1.0
		if invincible_timer <= 0:
			is_invincible = false
			modulate.a = 1.0

func take_damage():
	if is_invincible or state == State.HURT:
		return
	health -= 1
	emit_signal("health_changed", health)
	if health <= 0:
		die()
		return
	state = State.HURT
	is_invincible = true
	invincible_timer = 2.0
	# Bounce back slightly
	velocity.y = -300
	await get_tree().create_timer(0.4).timeout
	if state == State.HURT:
		state = State.RUN

func collect_gem():
	emit_signal("gem_collected", 1)

func die():
	set_physics_process(false)
	emit_signal("player_died")

func update_animation():
	match state:
		State.RUN:
			anim.play("run")
		State.JUMP:
			anim.play("jump")
		State.DOUBLE_JUMP:
			anim.play("double_jump")
		State.SLIDE:
			anim.play("slide")
		State.HURT:
			anim.play("hurt")
