extends Node
class_name LevelManager

var initial_states := {}
var current_room : Node = null
var player_checkpoint_position

@export var room_nodes : Array[Node]

func _ready():

	if room_nodes.is_empty():
		room_nodes = get_parent().get_children()

	store_initial_states()


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
		print("reset")


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

		node.visible = state["visible"]
		print("reset", node.name)


	var player = get_player()

	if player:
		player.global_position = player_checkpoint_position
		
func get_player():

	return get_tree().get_first_node_in_group("player")
