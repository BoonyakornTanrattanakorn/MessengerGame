extends CharacterBody2D

signal hp_changed(new_hp)
signal coin_changed(new_coin)
signal player_died
signal coin_collected

@export var speed := 300.0
@export var jump_force := -600.0
@export var gravity := 1500.0

var is_sliding := false
var hp := 3
var coin := 0

@onready var anim = $AnimatedSprite2D
@onready var stand_col = $StandingCollision
@onready var slide_col = $SlidingCollision

func _physics_process(delta):
	# gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force

	# slide
	if Input.is_action_pressed("slide") and is_on_floor():
		is_sliding = true
	else:
		is_sliding = false

	# switch collision
	stand_col.disabled = is_sliding
	slide_col.disabled = not is_sliding

	# constant forward movement
	velocity.x = speed

	move_and_slide()

	update_animation()
	
	check_collision()


func update_animation():
	if not is_on_floor():
		anim.play("jump")
	elif is_sliding:
		anim.play("slide")
	else:
		anim.play("run")


func take_damage():
	hp -= 1
	hp_changed.emit(hp)   # 👈 สำคัญ
	
	if hp <= 0:
		die()


func add_coin():
	coin += 1
	
	coin_changed.emit(coin)
	coin_collected.emit()   # 👈 ยิง signal


func die():
	player_died.emit()   # 👈 ยิง signal
	get_tree().reload_current_scene()

func check_collision():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var obj = collision.get_collider()
		
		if obj.name.contains("Cactus"):
			take_damage()
