extends CharacterBody2D
var speed = 200.0  # speed in pixels/sec
var dash_speed = 500.0
var dash_duration = 0.15
var dash_cooldown = 0.5
var playerAttribute = "wind"
#HP system
var player_hp = 3
var is_invincible = false
var invincible_timer = 0.0
var invincible_duration = 1.0 
# Dash system
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var last_direction: Vector2 = Vector2.RIGHT
var current_dialog = 0
var interact_with = null
# Mount system
var is_mounted = false
var current_mount = null

@onready var hud = $PlayerHUD

var respawn_position = Vector2(110, 115)
	
var inventory = {
	"blue_gem": 0,
	"brave_stone": 0,
	"potion": 3,
	"antidote": 2,
}

func _ready():
	hud.skill_changed.connect(_on_skill_changed)
	playerAttribute = hud.get_current_skill()

func _on_skill_changed(attribute: String):
	playerAttribute = attribute
	print("Switched to: ", attribute)

func _physics_process(delta):
	var direction = Input.get_vector("left", "right", "up", "down")

	# Mount/Dismount
	if Input.is_action_just_pressed("interact"):
		if is_mounted:
			if current_mount.can_dismount:
				current_mount.dismount_player()
		elif interact_with != null:
			print("Pressing F on: ", interact_with.name)
			if interact_with.has_method("activate"):
				interact_with.activate()
				interact_with = null
			elif interact_with.has_method("can_interact"):
				DialogueManager.show_dialogue_balloon(
					load("res://dialogue/conversations/" + interact_with.name + ".dialogue"),
					"_" + str(current_dialog)
				)

	# If mounted, skip all movement and just follow the cart
	if is_mounted:
		global_position = current_mount.mount_point.global_position
		return

	# Update last direction if there's input
	if direction.length() > 0:
		last_direction = direction.normalized()

	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	# Handle damage taking
	if is_invincible:
		invincible_timer -= delta
		if invincible_timer <= 0:
			is_invincible = false

	# Handle dashing
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			dash_cooldown_timer = dash_cooldown
		else:
			velocity = last_direction * dash_speed
			move_and_slide()
			return

	# Handle dash input
	if Input.is_action_just_pressed("minor magic") and dash_cooldown_timer <= 0 and not is_dashing and playerAttribute == "wind":
		is_dashing = true
		dash_timer = dash_duration
		velocity = last_direction * dash_speed

	# Normal movement
	velocity = direction * speed
	move_and_slide()

# Called by minecart to mount the player
func mount(minecart, mount_position):
	is_mounted = true
	current_mount = minecart
	global_position = mount_position
	interact_with = null

# Called by minecart to dismount the player
func dismount():
	is_mounted = false
	if current_mount != null:
		global_position = current_mount.global_position + Vector2(0, -10)
	current_mount = null

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body == self:
		return
	if body == interact_with:
		interact_with = null

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body == self:
		return
	if body.has_method("can_interact"):
		if body.has_meta("no_interact"):
			return
		interact_with = body
		current_dialog = body.can_interact()
		print("Interactable: ", body.name)

func take_damage(amount: int):
	if is_invincible:
		return
	# Can't take damage while mounted
	if is_mounted:
		return
	player_hp -= amount
	print("Player HP: ", player_hp)
	is_invincible = true
	invincible_timer = invincible_duration
	if player_hp <= 0:
		print("Player dead!")

func add_item(item_name: String, amount: int = 1):
	if item_name in inventory:
		inventory[item_name] += amount
	else:
		inventory[item_name] = amount
	print("Got: ", item_name, " total: ", inventory[item_name])
	get_node("/root").find_child("PlayerHUD", true, false).refresh_items()

func die_in_minecart_and_respawn():
	if current_mount != null:
		current_mount.reset_position()
		current_mount.dismount_player()
	is_mounted = false
	current_mount = null
	global_position = respawn_position
	player_hp = 3
