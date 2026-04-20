extends Node
class_name LevelManager

var initial_states := {}
var current_room : Node = null
var player_checkpoint_position

@export var room_nodes : Array[Node]
@export var save_id = "level_manager"
@export var save_scope = "scene"
var player : Player

func _ready():
	add_to_group("savable")
	if room_nodes.is_empty():
		for child in get_parent().get_children():
			if child.name.begins_with("Room"):
				room_nodes.append(child)

	store_initial_states()
	player = get_player()
	print(player)
	await get_tree().process_frame
	player.health_component.player_dead.connect(_on_player_dead)

func store_initial_states():

	initial_states.clear()

	for room in room_nodes:

		initial_states[room] = {}

		for child in room.get_children():

			if child is Node2D:

				initial_states[room][child] = {
					"position": child.global_position,
					"visible": child.visible
				}

func _input(event):

	if event.is_action_pressed("reset_level"):
		reset_room()


func reset_room():

	if current_room == null:
		return

	for node in initial_states[current_room].keys():

		if not is_instance_valid(node):
			continue

		var state = initial_states[current_room][node]

		node.global_position = state["position"]

		if node.has_method("recover"):
			node.recover()

		if not node.has_method("recover"):
			node.visible = state["visible"]


	player = get_player()

	if player:
		player.global_position = player_checkpoint_position
		
func get_player() -> Player: 
	return get_tree().get_first_node_in_group("player")
	
func _on_player_dead():
	DeadManager.kill_player("Overheat", Vector2(412,675))

func save():

	var data = {
		"current_room": "",
		"player_checkpoint_position": null
	}

	if current_room != null:
		data["current_room"] = current_room.name

	if player_checkpoint_position != null:
		data["player_checkpoint_position"] = {
			"x": player_checkpoint_position.x,
			"y": player_checkpoint_position.y
		}

	return data
	
func load_data(data):

	var room_name = data.get("current_room", "")

	if room_name != "":
		for room in room_nodes:
			if room.name == room_name:
				current_room = room
				break

	var pos = data.get("player_checkpoint_position", null)

	if pos != null:
		player_checkpoint_position = Vector2(pos.x, pos.y)
		
	if player_checkpoint_position:
		player = get_player()
		#if player:
		#	player.global_position = player_checkpoint_position
