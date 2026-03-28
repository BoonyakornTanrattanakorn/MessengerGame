extends CharacterBody2D

# States
enum BossState {IDLE, ACTIVATING, ACTIVE, STUNNED, DYING, DEAD_WITH_DROP, DEAD}
var state = BossState.IDLE

var hp_sequence = ["red", "green", "blue", "red", "green", "blue"]
var current_hp_index = 0
var is_stunned = false

# Movement
var speed = 80.0
var player: Node2D = null

# Bullet
var bullet_scene = preload("res://objects/map1_node3_3/ManaBall.tscn")
var bullet_timer = 0.0
var bullet_interval = 2.0
var bullet_speed = 150.0

# Timers
var activation_timer = 0.0
var activation_delay = 1.0
var stun_timer = 0.0
var stun_duration = 2.0
var blink_timer = 0.0
var blink_duration = 0.8
var blink_interval = 0.1
var is_blinking = false

# Death blink
var death_blink_timer = 0.0
var death_blink_duration = 1.0

@onready var sprite = $AnimatedSprite2D

@export var save_id = "golem_boss"
@export var save_scope = "scene"

func _ready():
	add_to_group("savable")
	player = get_tree().root.find_child("Player", true, false)
	sprite.play("idle")

func can_interact() -> int:
	return 0

func activate():
	match state:
		BossState.IDLE:
			if player:
				player.add_item("blue_gem", 1)
			state = BossState.ACTIVATING
			activation_timer = activation_delay

		BossState.DEAD_WITH_DROP:
			if player:
				player.add_item("brave_stone", 1)
				print("Player received brave_stone!")
			state = BossState.DEAD
			sprite.stop()
			sprite.play("die_golem")
			set_meta("no_interact", true)  # ← only set HERE after looting

func can_interact_check() -> bool:
	return not has_meta("no_interact")

func current_mode() -> String:
	if current_hp_index >= hp_sequence.size():
		return ""
	return hp_sequence[current_hp_index]

func update_mode():
	sprite.play(current_mode())
	if current_hp_index >= hp_sequence.size() / 2:
		bullet_interval = 1.5
		bullet_speed = 200.0
		print("Boss enraged!")

func try_damage(color: String):
	if state != BossState.ACTIVE or is_stunned:
		return
	if color == current_mode():
		take_damage()

func take_damage():
	current_hp_index += 1
	is_stunned = true
	stun_timer = stun_duration
	start_blink()
	if current_hp_index >= hp_sequence.size():
		start_death()
	else:
		update_mode()

func start_blink():
	is_blinking = true
	blink_timer = blink_duration

func start_death():
	state = BossState.DYING
	is_stunned = false          # ← clear stun immediately
	sprite.modulate = Color.WHITE  # ← clear any red tint
	death_blink_timer = death_blink_duration
	velocity = Vector2.ZERO     # ← stop moving
	print("Boss dying!")

func _physics_process(delta):
	match state:
		BossState.ACTIVATING:
			activation_timer -= delta
			if activation_timer <= 0:
				state = BossState.ACTIVE
				update_mode()

		BossState.ACTIVE:
			_handle_stun(delta)
			_handle_blink(delta)
			if not is_stunned:
				_follow_player()
				_handle_shooting(delta)

		BossState.DYING:
			death_blink_timer -= delta
			var blink_on = int(death_blink_timer / 0.1) % 2 == 0
			sprite.modulate = Color.RED if blink_on else Color.WHITE
			if death_blink_timer <= 0:
				sprite.modulate = Color.WHITE
				print("Playing die_golem_wdrop animation")  # ← add this
				sprite.animation = "die_golem_wdrop"        # ← try this instead of play()
				sprite.play()
				print("Current animation: ", sprite.animation)  # ← confirm it changed
				state = BossState.DEAD_WITH_DROP

		BossState.DEAD_WITH_DROP:
			pass  # just wait for player to press F

		BossState.DEAD:
			pass  # fully looted, do nothing
func _handle_stun(delta):
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0:
			is_stunned = false
			sprite.modulate = Color.WHITE

func _handle_blink(delta):
	if is_blinking:
		blink_timer -= delta
		var blink_on = int(blink_timer / blink_interval) % 2 == 0
		sprite.modulate = Color.RED if blink_on else Color.WHITE
		if blink_timer <= 0:
			is_blinking = false
			sprite.modulate = Color.WHITE

func _follow_player():
	if player:
		var dir = (player.global_position - global_position).normalized()
		velocity = dir * speed
		move_and_slide()

func _handle_shooting(delta):
	bullet_timer -= delta
	if bullet_timer <= 0:
		bullet_timer = bullet_interval
		shoot()

func shoot():
	if not player:
		return
	var bullet = bullet_scene.instantiate()
	get_parent().add_child(bullet)
	var dir = (player.global_position - global_position).normalized()
	bullet.global_position = global_position + dir * 120
	bullet.direction = dir
	bullet.speed = bullet_speed

func _on_hit_box_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.take_damage(1)
		
func save():
	return {
		"state": state,
		"current_hp_index": current_hp_index,
		"is_stunned": is_stunned,
		"stun_timer": stun_timer,
		"activation_timer": activation_timer,
		"death_blink_timer": death_blink_timer,
		"no_interact": has_meta("no_interact"),
		"position": {
			"x": global_position.x,
			"y": global_position.y
		}
	}
	
func load_data(data):

	state = int(data.get("state", BossState.IDLE))
	current_hp_index = int(data.get("current_hp_index", 0))

	is_stunned = data.get("is_stunned", false)

	stun_timer = float(data.get("stun_timer", 0.0))
	activation_timer = float(data.get("activation_timer", 0.0))
	death_blink_timer = float(data.get("death_blink_timer", 0.0))

	if data.get("no_interact", false):
		set_meta("no_interact", true)
	else:
		remove_meta("no_interact")


	if data.has("position"):
		var pos = data["position"]
		global_position = Vector2(
			float(pos["x"]),
			float(pos["y"])
		)
		velocity = Vector2.ZERO


	match state:

		BossState.IDLE:
			sprite.play("idle")

		BossState.ACTIVATING:
			sprite.play("idle")

		BossState.ACTIVE:
			update_mode()

		BossState.STUNNED:
			is_stunned = true
			update_mode()

		BossState.DYING:
			start_death()

		BossState.DEAD_WITH_DROP:
			sprite.play("die_golem_wdrop")

		BossState.DEAD:
			sprite.play("die_golem")
