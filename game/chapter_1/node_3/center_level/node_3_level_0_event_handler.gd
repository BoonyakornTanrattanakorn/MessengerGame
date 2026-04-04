extends LevelEventHandler

func on_level_loaded() -> void:
	Node3State.start_node3_objective()

func handle_intro_for_level() -> void:
	if not Global.chap1_node3_shown:
		Global.chap1_node3_shown = true

		DialogueManager.show_dialogue_balloon(
			load("res://game/chapter_1/node_3/dialogue/chap1_node3.dialogue"),
            "start"
		)

		await DialogueManager.dialogue_ended

		var final_door = get_node("FinalDoor")
		player.focus_camera_to(final_door)
		await get_tree().create_timer(1.0).timeout

		var wtl1 = get_node("WarpToLevel1/CollisionShape2D")
		player.focus_camera_to(wtl1)
		await get_tree().create_timer(1.0).timeout

		var wtl2 = get_node("WarpToLevel2/CollisionShape2D")
		player.focus_camera_to(wtl2)
		await get_tree().create_timer(1.0).timeout

		var wtl3 = get_node("WarpToLevel3/CollisionShape2D")
		player.focus_camera_to(wtl3)
		await get_tree().create_timer(1.0).timeout

		player.return_camera()
