extends Area2D # ตรวจสอบ: Node นี้ใน Godot ต้องเป็น Area2D เท่านั้น

@export_group("Identity & Routing")
@export var hole_id: int = 1            
@export var target_group_id: int = 1 

var stones_inside = []

func _ready():
	# เชื่อมสัญญาณตรวจจับ
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(area_node):
	if area_node.is_in_group("rock_pillar"):
		var stone = area_node.get_parent()
		if stone and not stones_inside.has(stone):
			stones_inside.append(stone)
			
			if stone.has_method("enter_hole"): 
				stone.enter_hole()
			
			if not stone.tree_exiting.is_connected(_on_stone_destroyed):
				stone.tree_exiting.connect(func(): _on_stone_destroyed(stone))
			
			_update_platforms()

func _on_area_exited(area_node):
	if area_node.is_in_group("rock_pillar"):
		var stone = area_node.get_parent()
		if stone and stones_inside.has(stone):
			stones_inside.erase(stone)
			_update_platforms()

func _on_stone_destroyed(stone_node):
	if stones_inside.has(stone_node):
		stones_inside.erase(stone_node)
		_update_platforms()

func _update_platforms():
	var count = stones_inside.size()
	var group_name = "platform_group_" + str(target_group_id)
	get_tree().call_group(group_name, "update_position_from_hole", hole_id, count)
