extends NodeTemplate

# Node-specific intro handling for Chapter1 Node2
func _handle_intro_for_level(level_name: String) -> void:
	if level_name == "Chapter1_Node2" and not Global.chap1_node2_shown:
		Global.chap1_node2_shown = true

		DialogueManager.show_dialogue_balloon(
			load("res://chapters/chapter_1/node_2/node_2.dialogue"),
			"start"
		)

		await DialogueManager.dialogue_ended

		var switch_node = current_level.get_node("Door/lever_room0_a2")
		player.focus_camera_to(switch_node)

		await get_tree().create_timer(1.0).timeout
		player.return_camera()
