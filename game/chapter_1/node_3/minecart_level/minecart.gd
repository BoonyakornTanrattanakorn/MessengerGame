extends Node2D
var player_in_range = false
var player_mounted = false
var mounted_player = null
var cart_speed = 200.0
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

func _physics_process(delta):
	if player_mounted:
		if Input.is_action_just_pressed("greater_magic") and in_turn_zone:
			var dir = Vector2.ZERO
			#if is_moving:
			if Input.is_action_pressed(turn_input):
					dir = turn_direction
			#else:
			#	if Input.is_action_pressed("up"):
			#		dir = Vector2.DOWN
			#	elif Input.is_action_pressed("down"):
			#		dir = Vector2.UP
			#	elif Input.is_action_pressed("left"):
			#		dir = Vector2.RIGHT
			#	elif Input.is_action_pressed("right"):
			#		dir = Vector2.LEFT
			if dir != Vector2.ZERO:
				is_moving = true
				move_direction = dir

	# move cart
	if is_moving:
		global_position += move_direction * cart_speed * delta

	# keep player on cart
	if player_mounted and mounted_player:
		mounted_player.global_position = mount_point.global_position

	# update sprite
	if is_moving:
		if abs(move_direction.x) > abs(move_direction.y):
			sprite.region_rect = side_region
			sprite.flip_h = move_direction.x < 0
		else:
			sprite.region_rect = front_region
			sprite.flip_h = false

func _on_danger_entered(area):
	if area.is_in_group("danger"):
		if mounted_player:
			mounted_player.die_in_minecart_and_respawn(Vector2(-30, -200))
		stop_cart()

func _on_stop_area_entered(area):
	if area.is_in_group("stop_block"):
		stop_cart()
		
func save():
	return {
		"player_mounted": player_mounted,
		"cart_position": {"x": global_position.x, "y": global_position.y},
		"is_moving": is_moving,
		"move_direction": {"x": move_direction.x, "y": move_direction.y}
	}

func load_data(data):
	player_mounted = data.get("player_mounted", false)

	var pos = data.get("cart_position", {"x": original_position.x, "y": original_position.y})
	global_position = Vector2(pos.get("x", original_position.x), pos.get("y", original_position.y))

	var dir = data.get("move_direction", {"x": 0, "y": 0})
	move_direction = Vector2(dir.get("x", 0), dir.get("y", 0))

	is_moving = data.get("is_moving", false)

	if player_mounted:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			mount_player(player)
