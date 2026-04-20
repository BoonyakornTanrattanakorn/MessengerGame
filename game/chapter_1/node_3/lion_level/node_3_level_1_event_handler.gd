extends LevelEventHandler

@export var lion_guard: Node2D

func handle_intro_for_level() -> void:
	Node3State.update_objective()
	if not GameState.chap1_node3_1_shown:
		GameState.chap1_node3_1_shown = true
		BGMManager.play_bgm("field_theme_1", 0.0, true)

		DialogueManager.show_dialogue_balloon(
			load("res://game/chapter_1/node_3/dialogue/chap1_node3_1.dialogue"),
            "start"
		)

		await DialogueManager.dialogue_ended

		player.focus_camera_to(lion_guard)

		await get_tree().create_timer(1.0).timeout
		player.return_camera()
		SaveManager.save_game()
