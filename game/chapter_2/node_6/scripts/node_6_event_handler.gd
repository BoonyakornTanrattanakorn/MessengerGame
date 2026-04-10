extends LevelEventHandler

var dialogue = load("res://game/chapter_2/node_6/dialogue/chap2_node3.dialogue")
@export var town: Node2D

func handle_intro_for_level() -> void:
	if not GameState.chap2_node3_shown:
		GameState.chap2_node3_shown = true

		DialogueManager.show_dialogue_balloon(
			dialogue,
            "start"
		)

		await DialogueManager.dialogue_ended

		player.focus_camera_to(town)
		await get_tree().create_timer(1.0).timeout
		
		player.return_camera()
		
		DialogueManager.show_dialogue_balloon(
			dialogue,
            "start_2"
		)
		
		await DialogueManager.dialogue_ended
