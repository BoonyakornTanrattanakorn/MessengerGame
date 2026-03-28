extends Node2D

@export var total_levers: Array[int] = [2, 2, 1, 1]
var activated_levers: Array[int] = []

var doors_by_room: Dictionary = {}

@export var save_id = "lever_editor"
@export var save_scope = "scene"

func _ready():
	add_to_group("savable")
	activated_levers.resize(total_levers.size())
	for i in range(activated_levers.size()):
		activated_levers[i] = 0

	for child in get_children():
		if child.has_signal("lever_activated"):
			child.lever_activated.connect(_on_lever_activated)

		if child.has_method("open") and "room_id" in child:
			doors_by_room[child.room_id] = child

func _on_lever_activated(room_id: int):
	if room_id < 0 or room_id >= activated_levers.size():
		print("Invalid room_id: ", room_id)
		return

	activated_levers[room_id] += 1
	print("Room ", room_id, " levers active: ",
		activated_levers[room_id], "/", total_levers[room_id])

	if activated_levers[room_id] >= total_levers[room_id]:
		open_door(room_id)

func open_door(room_id: int):
	if doors_by_room.has(room_id):
		doors_by_room[room_id].open()
	else:
		print("No door found for room ", room_id)
		
func save():
	return {
		"activated_levers": activated_levers
	}

func load_data(data):
	var temp = data.get("activated_levers", [])
	activated_levers = []
	for val in temp:
		activated_levers.append(int(val))
	
	for room_id in doors_by_room.keys():
		if room_id < activated_levers.size() and activated_levers[room_id] >= total_levers[room_id]:
			open_door(room_id)
