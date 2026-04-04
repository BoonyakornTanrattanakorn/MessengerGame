extends LevelEventHandler

func handle_intro_for_level() -> void:
	if not GameState.chap1_node3_1_shown:
		GameState.chap1_node3_1_shown = true

		DialogueManager.show_dialogue_balloon(
			load("res://game/chapter_1/node_3/dialogue/chap1_node3_1.dialogue"),
            "start"
		)

		await DialogueManager.dialogue_ended

		var lion_guard = get_node("LionGuard")
		player.focus_camera_to(lion_guard)

		await get_tree().create_timer(1.0).timeout
		player.return_camera()
