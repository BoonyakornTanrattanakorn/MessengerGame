extends Area2D

@export var item_name: String = "green_gem"
@export var amount: int = 1

var picked_up := false

func can_interact() -> int:
	return 0

func activate():
	if picked_up:
		return

	var player = get_tree().root.find_child("Player", true, false)
	if player and player.has_method("add_item"):
		player.add_item(item_name, amount)
		print("Player received ", item_name, " x", amount)

	picked_up = true
	set_meta("no_interact", true)
	queue_free()
