extends Node2D

@onready var bridge_manager = $BridgeManager

func _ready():
	for node in get_all_children(self):
		# Only connect nodes that have switch_activated signal
		if node.has_method("activate") and node.has_signal("switch_activated"):
			node.switch_activated.connect(bridge_manager.activate_color)

func get_all_children(node: Node) -> Array:
	var result = []
	for child in node.get_children():
		result.append(child)
		result.append_array(get_all_children(child))
	return result
