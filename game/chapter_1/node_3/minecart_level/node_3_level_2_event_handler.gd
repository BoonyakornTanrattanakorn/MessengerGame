extends LevelEventHandler

@export var minecart: Node2D
@export var green_gem: Node2D

func handle_intro_for_level() -> void:
	if not GameState.chap1_node3_2_shown:
		GameState.chap1_node3_2_shown = true

		DialogueManager.show_dialogue_balloon(
			load("res://game/chapter_1/node_3/dialogue/chap1_node3_2.dialogue"),
            "start"
		)

		await DialogueManager.dialogue_ended

		player.focus_camera_to(minecart)
		await get_tree().create_timer(1.0).timeout
		
		player.focus_camera_to(green_gem)
		await get_tree().create_timer(1.0).timeout
		
		player.return_camera()
