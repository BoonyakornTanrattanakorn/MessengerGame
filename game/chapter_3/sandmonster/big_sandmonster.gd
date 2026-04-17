extends "res://game/chapter_3/sandmonster/sandmonster.gd"

func _ready():
	hp = 15
	move_speed = 40.0
	ATTACK_RANGE = 80.0
	ATTACK_DAMAGE = 2
	ATTACK_COOLDOWN = 2.0
	super._ready()

func _check_fairy_proximity() -> void:
	pass  # big sandmonster is not affected by the water fairy

func _handle_damage_normal(amount: int, source: String) -> void:
	match source:
		"water_lv2":
			_set_state(State.DRIED)
		"fire":
			_reduce_hp(amount)
		"wind":
			pass
		_:
			_reduce_hp(amount)

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

	if player != null:
		var dist = global_position.distance_to(player.global_position)

		if dist > AGGRO_RANGE * 1.5:
			is_aggro = false

		if dist <= DETECTION_RANGE:
			is_aggro = true

		var current_range = AGGRO_RANGE if is_aggro else DETECTION_RANGE

		if dist <= ATTACK_RANGE and attack_timer <= 0.0:
			_start_attack()
			return

		if dist > current_range:
			velocity = Vector2.ZERO
			move_and_slide()
			return

	super._physics_process(delta)

func _start_attack():
	attacking = true
	velocity = Vector2.ZERO
	animated_sprite.play("attack")
	await animated_sprite.animation_finished
	_do_attack_hit()
	await get_tree().create_timer(1.0).timeout
	attacking = false

func _do_attack_hit():
	if player != null and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= ATTACK_RANGE:
			if player.has_node("HealthComponent"):
				player.get_node("HealthComponent").take_damage(ATTACK_DAMAGE)
			elif player.has_method("take_damage"):
				player.take_damage(ATTACK_DAMAGE)
	attack_timer = ATTACK_COOLDOWN
	if state == State.NORMAL:
		animated_sprite.play("normal")

func _die():
	Node7State.on_big_sandmonster_killed()
	_set_state(State.DUST)
	await animated_sprite.animation_finished
	queue_free()
