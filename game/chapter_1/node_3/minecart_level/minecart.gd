extends Node2D

var player_in_range = false
var player_mounted = false
var mounted_player = null

# Speed system
var cart_speed = 200.0
var target_speed = 250.0
var speed_increase_per_second = 5.0

var is_moving = false
var move_direction = Vector2.ZERO
var in_turn_zone = false
var turn_direction = Vector2.ZERO
var turn_input = ""
var can_dismount = false

@onready var sprite = $Sprite2D
@onready var mount_point = $MountPoint
@onready var interact_area = $InteractArea
@onready var danger_area = $DangerArea
@onready var stop_area = $StopArea

@export var save_id = "minecart_1"
@export var save_scope = "scene"

var front_region = Rect2(0, 18, 32, 40)
var side_region = Rect2(34, 18, 58, 42)
var original_position = Vector2.ZERO
var start_turn_direction = Vector2.ZERO
var start_turn_input = ""

func _ready():
	add_to_group("savable")
	original_position = global_position
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	danger_area.area_entered.connect(_on_danger_entered)
	stop_area.area_entered.connect(_on_stop_area_entered)

func reset_position():
	global_position = original_position
	stop_cart()
	can_dismount = false
	turn_direction = Vector2.ZERO
	turn_input = ""
	player_mounted = false
	mounted_player = null
	await get_tree().physics_frame
	await get_tree().physics_frame
	in_turn_zone = true
	
func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true
		body.interact_with = self

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		if body.interact_with == self:
			body.interact_with = null


func activate():
	print("yesris")
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	mount_player(player)

func mount_player(player):
	print("yessir")
	player_mounted = true
	mounted_player = player
	player.mount(self, mount_point.global_position)

func dismount_player():
	if mounted_player:
		player_mounted = false
		mounted_player.dismount()
		mounted_player = null
	stop_cart()

func stop_cart():
	is_moving = false
	move_direction = Vector2.ZERO
	cart_speed = 200.0  # reset speed

func _physics_process(delta):
	if player_mounted:
		if Input.is_action_just_pressed("greater_magic") and in_turn_zone:
			var mouse_pos = get_global_mouse_position()
			var dir_to_mouse = (mouse_pos - global_position).normalized()
			var snapped_dir = _snap_to_cardinal(dir_to_mouse)

			if snapped_dir == -turn_direction:
				is_moving = true
				move_direction = turn_direction
			else:
				print("wrong direction! mouse snapped to: ", snapped_dir, " but zone wants: ", turn_direction)

	# Speed ramp
	if is_moving and cart_speed < target_speed:
		cart_speed += speed_increase_per_second * delta
		cart_speed = min(cart_speed, target_speed)

	# Move cart
	if is_moving:
		global_position += move_direction * cart_speed * delta

	# Keep player on cart
	if player_mounted and mounted_player:
		mounted_player.global_position = mount_point.global_position

	# Update sprite
	if is_moving:
		if abs(move_direction.x) > abs(move_direction.y):
			sprite.region_rect = side_region
			sprite.flip_h = move_direction.x < 0
		else:
			sprite.region_rect = front_region
			sprite.flip_h = false

func _snap_to_cardinal(dir: Vector2) -> Vector2:
	# Snap a normalized direction to the nearest of 4 cardinal directions
	if abs(dir.x) > abs(dir.y):
		return Vector2(sign(dir.x), 0)
	else:
		return Vector2(0, sign(dir.y))

func _on_danger_entered(area):
	if area.is_in_group("danger"):
		if mounted_player:
			mounted_player.die_in_minecart_and_respawn(Vector2(113, 130))
		stop_cart()

func _on_stop_area_entered(area):
	if area.is_in_group("stop_block"):
		stop_cart()
		
func save():
	return {
		"player_mounted": player_mounted,
		"cart_position": {"x": global_position.x, "y": global_position.y},
		"is_moving": is_moving,
		"move_direction": {"x": move_direction.x, "y": move_direction.y},
		"cart_speed": cart_speed
	}

func load_data(data):
	player_mounted = data.get("player_mounted", false)

	var pos = data.get("cart_position", {"x": original_position.x, "y": original_position.y})
	global_position = Vector2(pos.get("x", original_position.x), pos.get("y", original_position.y))

	var dir = data.get("move_direction", {"x": 0, "y": 0})
	move_direction = Vector2(dir.get("x", 0), dir.get("y", 0))

	is_moving = data.get("is_moving", false)

	cart_speed = data.get("cart_speed", 200.0)

	if player_mounted:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			mount_player(player)
