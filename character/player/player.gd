extends CharacterBody2D

var speed = 200.0  # speed in pixels/sec
var dash_speed = 500.0
var dash_duration = 0.15
var dash_cooldown = 0.5

var playerAttribute = "wind"

#HP system
@export var player_max_hp = 3
var player_hp = player_max_hp
var is_invincible = false
var invincible_timer = 0.0
var invincible_duration = 1.0 
signal health_changed

# Dash system
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var last_direction: Vector2 = Vector2.RIGHT  # Track last faced direction

var interact_with = null
var current_dialog = 0

# Mount system
var is_mounted = false
var current_mount = null

@onready var hud = $PlayerHUD  # or get_node path
@onready var animated_sprite = $AnimatedSprite2D
@onready var camera = $Camera2D

var respawn_position = Vector2(110, 115)

var inventory = {
	"red_gem": 0,
	"green_gem": 0,
	"blue_gem": 0,
	"brave_stone": 0,
	"potion": 3,
	"antidote": 2,
}

var is_in_dialogue = false

@export var save_id = "player" 
@export var save_scope = "global" 

@export var wind_scene: PackedScene = preload("res://Scenes/wind.tscn")

func _ready():
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	#ObjectiveManager.set_objective("Use wind power to flip the switch")
	add_to_group("savable")
	hud.skill_changed.connect(_on_skill_changed)
	# Set starting attribute from HUD
	playerAttribute = hud.get_current_skill()
	$Hurtbox.add_to_group("player_hurtbox")

func _on_dialogue_started(_arg = null):
	is_in_dialogue = true
	is_dashing = false
	velocity = Vector2.ZERO

func _on_dialogue_ended(_arg = null):
	is_in_dialogue = false
	
func _on_skill_changed(attribute: String):
	playerAttribute = attribute
	print("Switched to: ", attribute)

func _physics_process(delta):
	if is_in_dialogue:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
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
				var dialogue_path = "res://dialogue/conversations/" + interact_with.name + ".dialogue"
				if ResourceLoader.exists(dialogue_path):
					DialogueManager.show_dialogue_balloon(
						load(dialogue_path),
						"_" + str(current_dialog)
					)
				else:
					print("No dialogue for: ", interact_with.name)
	
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
			# End dash
			is_dashing = false
			dash_cooldown_timer = dash_cooldown
		else:
			# During dash: move in dash direction at dash speed
			velocity = last_direction * dash_speed
			move_and_slide()
			_update_animation(last_direction)
			return  # Skip rest of physics processing while dashing
	
	# Handle dash input (only if not on cooldown and not already dashing)
	if Input.is_action_just_pressed("minor magic") and dash_cooldown_timer <= 0 and not is_dashing and playerAttribute == "wind":
		# Start dash in last faced direction
		is_dashing = true
		dash_timer = dash_duration
		velocity = last_direction * dash_speed
	
	if Input.is_action_just_pressed("major magic"):
		shoot_wind_wave()
	
	# Normal movement
	velocity = direction * speed
	move_and_slide()
	_update_animation(direction)

func _facing_suffix(dir: Vector2) -> String:
	if abs(dir.x) >= abs(dir.y):
		return "right" if dir.x > 0 else "left"
	else:
		return "front" if dir.y > 0 else "back"

func _update_animation(direction: Vector2) -> void:
	var facing = _facing_suffix(last_direction)
	var anim = ""

	if is_dashing:
		anim = "dash"
		if not animated_sprite.sprite_frames.has_animation(anim):
			anim = "walk " + facing
	else:
		var moving = direction.length() > 0.1
		anim = ("walk " if moving else "idle ") + facing

	if animated_sprite.animation != anim:
		animated_sprite.play(anim)

# Called by minecart to mount the player
func mount(minecart, mount_position):
	is_mounted = true
	current_mount = minecart
	global_position = mount_position
	interact_with = null

func _find_safe_dismount_position() -> Vector2:
	if current_mount == null:
		return global_position

	var base = current_mount.mount_point.global_position
	var offsets: Array[Vector2] = [
		Vector2(0, -24),
		Vector2(24, 0),
		Vector2(-24, 0),
		Vector2(0, 24),
		Vector2(0, -40)
	]

	if current_mount.move_direction != Vector2.ZERO:
		var side = current_mount.move_direction.orthogonal().normalized() * 24.0
		offsets.insert(0, side)
		offsets.insert(1, -side)

	for offset in offsets:
		var target = base + offset
		var motion = target - global_position
		if not test_move(global_transform, motion):
			return target

	return base + Vector2(0, -24)

# Called by minecart to dismount the player
func dismount():
	is_mounted = false
	if current_mount != null:
		global_position = _find_safe_dismount_position()
	current_mount = null

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body == self:
		return
	if body.has_method("can_interact"):
		if body.has_meta("no_interact"):
			return
		interact_with = body
		current_dialog = body.can_interact()
		print("Interactable: ", body.name)

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body == self:
		return
	if body == interact_with:
		interact_with = null

func _on_interaction_area_area_entered(area: Area2D) -> void:
	if area == self:
		return
	if area.has_method("can_interact"):
		if area.has_meta("no_interact"):
			return
		interact_with = area
		current_dialog = area.can_interact()
		print("Interactable area: ", area.name)

func _on_interaction_area_area_exited(area: Area2D) -> void:
	if area == self:
		return
	if area == interact_with:
		interact_with = null

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if not area.is_in_group("enemy_projectile"):
		return
	var dmg = area.get("damage")
	take_damage(int(dmg) if dmg != null else 1)

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
	health_changed.emit(player_hp)
	if player_hp <= 0:
		player_hp = 0
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
	player_hp = player_max_hp
		
func shoot_wind_wave():
	if wind_scene:
		var wave = wind_scene.instantiate()
		wave.direction = last_direction
		wave.global_position = global_position
	
		wave.rotation = last_direction.angle()
		
		get_tree().current_scene.add_child(wave)

func save():
	return {
		"position" : {
			"x" : position.x,
			"y" : position.y
		},
		"playerAttribute" : playerAttribute,
		"player_max_hp" : player_max_hp,
		"player_hp" : player_hp,
		"inventory" : inventory,
		"respawn_position" : {
			"x" : respawn_position.x,
			"y" : respawn_position.y
		}
	}
	
func load_data(data):
	var pos = data.get("position", null)
	var re_pos = data.get("respawn_position", null)
	
	if re_pos:
		respawn_position = Vector2(re_pos["x"], re_pos["y"])

	if pos:
		position = Vector2(pos["x"], pos["y"])

	playerAttribute = hud.get_current_skill()
	player_max_hp = int(data.get("player_max_hp", player_max_hp))
	player_hp = int(data.get("player_hp", player_hp))
	call_deferred("emit_signal", "health_changed", player_hp)
	var loaded_inventory = data.get("inventory", {})

	for key in loaded_inventory:
		inventory[key] = int(loaded_inventory[key])
		
func focus_camera_to(target: Node2D):
	camera.reparent(get_tree().current_scene) # detach from player

	var tween = create_tween()
	tween.tween_property(camera, "global_position", target.global_position, 0.5)

func return_camera():
	camera.reparent(self)  # back to player
	camera.position = Vector2.ZERO  # reset offset
