extends Area2D

@export var item_name: String = "red_gem"
@export var amount: int = 1
@export var locked := true

var picked_up := false

@export var save_id = "red_gem_pickup"
@export var save_scope = "scene"

func _ready() -> void:
	add_to_group("savable")
	if locked:
		set_meta("no_interact", true)

func can_interact() -> int:
	return 0

func unlock_pickup() -> void:
	locked = false
	if has_meta("no_interact"):
		remove_meta("no_interact")
	print(name, " unlocked")

func activate():
	if picked_up:
		return

	if locked:
		print("Gem is still locked")
		return

	var player = get_tree().root.find_child("Player", true, false)
	if player and player.has_method("add_item"):
		player.add_item(item_name, amount)
		print("Player received ", item_name, " x", amount)
	
	Node3State.collect_gem("red_gem")

	picked_up = true
	set_meta("no_interact", true)
	hide()
	
func save():
	return {
		"picked_up": picked_up,
		"locked": locked
	}


func load_data(data):

	picked_up = data.get("picked_up", picked_up)
	locked = data.get("locked", locked)

	if picked_up:
		hide()
		return

	if locked:
		set_meta("no_interact", true)
	else:
		if has_meta("no_interact"):
			remove_meta("no_interact")
