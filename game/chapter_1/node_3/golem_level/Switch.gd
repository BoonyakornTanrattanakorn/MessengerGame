extends StaticBody2D

var bridge_color: String = ""


func _ready():
	# Auto-detect color from node name
	var node_name = name.to_lower()
	if "red" in node_name:
		bridge_color = "red"
	elif "blue" in node_name:
		bridge_color = "blue"
	elif "green" in node_name:
		bridge_color = "green"
	print("Switch ready: ", name, " color: ", bridge_color)

func can_interact() -> int:
	return 0

func activate():
	# Walk up the tree to find BridgeManager
	var bridge_manager = get_tree().root.find_child("BridgeManager", true, false)
	
	if bridge_manager == null:
		print("ERROR: BridgeManager not found!")
		return
	
	if bridge_manager.is_color_active(bridge_color):
		print(bridge_color, " already active - blocked")
		return
	
	bridge_manager.activate_color(bridge_color)
	print(name, " activated: ", bridge_color)
