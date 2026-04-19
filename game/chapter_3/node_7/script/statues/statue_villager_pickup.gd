extends Area2D

@export var item_name: String = "statue_villager"
@export var amount: int = 1

var picked_up := false

@export var save_id = "statue_villager_pickup"
@export var save_scope = "scene"

func _ready():
	add_to_group("savable")

func can_interact() -> int:
	return 0

func activate():
	if picked_up:
		return

	var player = get_tree().root.find_child("Player", true, false)
	if player and player.has_method("add_item"):
		player.add_item(item_name, amount)
		print("Player received ", item_name, " x", amount)

	Node7State.collect_statue("statue_villager")
	picked_up = true
	set_meta("no_interact", true)
	hide()
	
func save():
	return {
		"picked_up": picked_up
	}


func load_data(data):
	picked_up = data.get("picked_up", picked_up)
	if picked_up:
		hide()
		set_meta("no_interact", true)
		set_deferred("monitoring", false)  # disables the Area2D
		return
