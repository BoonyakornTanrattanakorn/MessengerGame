extends LevelEventHandler

@export var final_door: Node2D
@export var wtl1: Node2D
@export var wtl2: Node2D
@export var wtl3: Node2D

func on_level_loaded() -> void:
	Node3State.start_node3_objective()

func handle_intro_for_level() -> void:
	if not GameState.chap1_node3_shown:
		GameState.chap1_node3_shown = true

		DialogueManager.show_dialogue_balloon(
			load("res://game/chapter_1/node_3/dialogue/chap1_node3.dialogue"),
            "start"
		)

		await DialogueManager.dialogue_ended

		player.focus_camera_to(final_door)
		await get_tree().create_timer(1.0).timeout

		player.focus_camera_to(wtl1)
		await get_tree().create_timer(1.0).timeout

		player.focus_camera_to(wtl2)
		await get_tree().create_timer(1.0).timeout

		player.focus_camera_to(wtl3)
		await get_tree().create_timer(1.0).timeout

		player.return_camera()
