extends Node2D

@export var total_levers: Array[int] = [2, 2, 1, 1]
var activated_levers: Array[int] = []

var doors_by_room: Dictionary = {}

func _ready():
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
