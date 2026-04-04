extends LevelEventHandler

func handle_intro_for_level() -> void:
	if not Global.chap1_node3_1_shown:
		Global.chap1_node3_1_shown = true

		DialogueManager.show_dialogue_balloon(
			load("res://game/chapter_1/node_3/dialogue/chap1_node3_1.dialogue"),
            "start"
		)

		await DialogueManager.dialogue_ended

		var tigerguard = get_node("TigerGuard")
		player.focus_camera_to(tigerguard)

		await get_tree().create_timer(1.0).timeout
		player.return_camera()
