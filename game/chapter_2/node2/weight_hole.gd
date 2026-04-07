extends Area2D

@export var platform_id: int = 1
@export var move_distance: float = 64.0 

var stones_inside: Array[Node2D] = []

func _ready():
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area2D):
	if area.is_in_group("rock_pillar"):
		var stone = area.get_parent()
		print("rock enter")

		if not stones_inside.has(stone):
			stones_inside.append(stone)

			if stone.has_method("enter_hole"):
				stone.enter_hole()

			if not stone.tree_exiting.is_connected(_on_stone_destroyed):
				stone.tree_exiting.connect(func(): _on_stone_destroyed(stone))

			_update_platforms()

func _on_area_exited(area: Area2D):
	if area.is_in_group("rock_pillar"):
		var stone = area.get_parent()

		if stones_inside.has(stone):
			stones_inside.erase(stone)
			_update_platforms()

func _on_stone_destroyed(stone: Node2D):
	if stones_inside.has(stone):
		stones_inside.erase(stone)
		_update_platforms()

func _update_platforms():
	var count = stones_inside.size()
	print("Hole ID:", platform_id, " | Stones:", count)

	var group_name = "platform_group_" + str(platform_id)
	get_tree().call_group(group_name, "update_position", count)
