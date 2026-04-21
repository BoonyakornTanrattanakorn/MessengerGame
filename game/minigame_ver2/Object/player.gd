extends CharacterBody2D
signal gem_collected(amount)
signal health_changed(new_health)
signal player_died

const GRAVITY = 1800.0
const JUMP_FORCE = -320.0
const DOUBLE_JUMP_FORCE = -300.0
const SLIDE_DURATION = 0.6
const RUN_SPEED = 100.0
const COYOTE_TIME = 0.15
const AIR_DIVE_FORCE = 600.0

@onready var anim = $AnimatedSprite2D
@onready var stand_shape = $CollisionShape2D
@onready var slide_shape = $SlideShape

enum State { RUN, JUMP, DOUBLE_JUMP, SLIDE, HURT, AIR_DIVE }
var state = State.RUN
var prev_state = State.RUN
var can_double_jump = false
var slide_timer = 0.0
var health = 3
var is_invincible = false
var invincible_timer = 0.0
var coyote_timer = 0.0
var coyote_used = false

signal shard_changed(amount)
var max_health = 3
var health_shards = 0

func _ready():
	add_to_group("player")

func _physics_process(delta):
	velocity.x = RUN_SPEED
	apply_gravity(delta)
	handle_coyote(delta)
	handle_input(delta)
	handle_timers(delta)
	move_and_slide()
	update_animation()

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		# Cancel ground slide if we walk off a ledge
		if state == State.SLIDE:
			stop_slide()
			state = State.JUMP
	else:
		# Landing — reset state
		if state == State.JUMP or state == State.DOUBLE_JUMP or state == State.AIR_DIVE:
			state = State.RUN
		# If holding slide on landing, go into slide immediately
		elif state == State.AIR_DIVE:
			start_slide()
		can_double_jump = false
		coyote_used = false

func handle_coyote(delta):
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		if coyote_timer > 0:
			coyote_timer -= delta

func handle_input(delta):
	if state == State.HURT:
		return

	# --- Jump ---
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or state == State.SLIDE:
			jump()
		elif coyote_timer > 0 and not coyote_used:
			coyote_jump()
		elif can_double_jump:
			double_jump()

	# --- Slide / Air dive ---
	if Input.is_action_just_pressed("slide"):
		if is_on_floor():
			# Normal ground slide
			start_slide()
		elif state == State.JUMP or state == State.DOUBLE_JUMP:
			# Air dive — slam to ground fast
			air_dive()

	# Release slide early on ground
	if Input.is_action_just_released("slide") and state == State.SLIDE:
		stop_slide()
		state = State.RUN

func jump():
	velocity.y = JUMP_FORCE
	state = State.JUMP
	can_double_jump = true
	coyote_used = true
	coyote_timer = 0
	stop_slide()

func coyote_jump():
	velocity.y = JUMP_FORCE
	state = State.JUMP
	can_double_jump = false
	coyote_used = true
	coyote_timer = 0

func double_jump():
	velocity.y = DOUBLE_JUMP_FORCE
	state = State.DOUBLE_JUMP
	can_double_jump = false

func air_dive():
	velocity.y = AIR_DIVE_FORCE
	can_double_jump = false
	state = State.AIR_DIVE

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
	if state == prev_state:
		# Keep slide looping while held
		if state == State.SLIDE and not anim.is_playing():
			anim.play("slide")
		return
	prev_state = state

	match state:
		State.RUN:
			anim.play("run")
		State.JUMP:
			anim.play("jump")
		State.DOUBLE_JUMP:
			anim.play("double_jump")
		State.SLIDE:
			anim.play("slide")
		State.AIR_DIVE:
			anim.play("jump")  # reuse jump anim, or make a "dive" anim
		State.HURT:
			anim.play("hurt")

func add_shard(amount: int):
	health_shards += amount
	emit_signal("shard_changed", health_shards)
	try_heal()

func try_heal():
	if health < max_health and health_shards >= 50:
		health_shards -= 50
		health += 1
		emit_signal("health_changed", health)
		emit_signal("shard_changed", health_shards)
		try_heal()

func stop():
	set_physics_process(false)
	velocity = Vector2.ZERO
