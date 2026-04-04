extends LevelEventHandler

func handle_intro_for_level() -> void:
	if not GameState.chap1_node3_2_shown:
		GameState.chap1_node3_2_shown = true

		DialogueManager.show_dialogue_balloon(
			load("res://game/chapter_1/node_3/dialogue/chap1_node3_2.dialogue"),
            "start"
		)

		await DialogueManager.dialogue_ended

		var mc = get_node("Minecart")
		player.focus_camera_to(mc)

		await get_tree().create_timer(1.0).timeout
		player.return_camera()
