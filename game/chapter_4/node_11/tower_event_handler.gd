extends LevelEventHandler

var dialogue := load("res://game/chapter_4/node_11/dialogue/ice_ghost.dialogue")

@export var ice_ghost: Node2D

func handle_intro_for_level() -> void:
	if not GameState.chap4_tower_1st_floor_shown:
		GameState.chap4_tower_1st_floor_shown = true

		player.focus_camera_to(ice_ghost)
		if dialogue != null:
			DialogueManager.show_dialogue_balloon(dialogue, "start")
			await DialogueManager.dialogue_ended
		player.return_camera()
