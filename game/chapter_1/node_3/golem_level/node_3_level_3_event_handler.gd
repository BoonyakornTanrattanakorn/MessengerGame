extends LevelEventHandler

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


func handle_intro_for_level() -> void:
	if not GameState.chap1_node3_3_shown:
		GameState.chap1_node3_3_shown = true

		DialogueManager.show_dialogue_balloon(
			load("res://game/chapter_1/node_3/dialogue/chap1_node3_3.dialogue"),
            "start"
		)

		await DialogueManager.dialogue_ended

		var golemboss = get_node("GolemBoss")
		player.focus_camera_to(golemboss)

		await get_tree().create_timer(1.0).timeout
		player.return_camera()
