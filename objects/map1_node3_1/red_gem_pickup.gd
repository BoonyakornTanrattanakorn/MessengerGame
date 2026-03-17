extends Area2D

@export var item_name: String = "red_gem"
@export var amount: int = 1
@export var locked := true

var picked_up := false

func _ready() -> void:
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

	picked_up = true
	set_meta("no_interact", true)
	queue_free()
