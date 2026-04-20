extends LevelEventHandler

@export var switch_node: Node2D

func handle_intro_for_level() -> void:
	if not GameState.chap1_node2_shown:
		# Play BGM
		BGMManager.stop_bgm(2.0)
		GameState.chap1_node2_shown = true

		DialogueManager.show_dialogue_balloon(
			load("res://game/chapter_1/node_2/dialogue/node_2.dialogue"),
			"start"
		)

		await DialogueManager.dialogue_ended

		player.focus_camera_to(switch_node)

		await get_tree().create_timer(1.0).timeout
		player.return_camera()
		BGMManager.play_bgm("dungeon", -5.0, true)
		SaveManager.save_game()
