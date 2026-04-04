extends NodeTemplate

# Node3 handles Level_0..Level_3 intros and post-load behavior
func _on_level_loaded() -> void:
	if current_level != null and current_level.name == "Level_0":
		Node3State.start_node3_objective()

func _handle_intro_for_level(level_name: String) -> void:
	match level_name:
		"Level_0":
			if not Global.chap1_node3_shown:
				Global.chap1_node3_shown = true

				DialogueManager.show_dialogue_balloon(
					load("res://chapters/chapter_1/node_2/node_2.dialogue"),
                    "start"
				)

				await DialogueManager.dialogue_ended

				var final_door = current_level.get_node("FinalDoor")
				player.focus_camera_to(final_door)
				await get_tree().create_timer(1.0).timeout

				var wtl1 = current_level.get_node("WarpToLevel1/CollisionShape2D")
				player.focus_camera_to(wtl1)
				await get_tree().create_timer(1.0).timeout

				var wtl2 = current_level.get_node("WarpToLevel2/CollisionShape2D")
				player.focus_camera_to(wtl2)
				await get_tree().create_timer(1.0).timeout

				var wtl3 = current_level.get_node("WarpToLevel3/CollisionShape2D")
				player.focus_camera_to(wtl3)
				await get_tree().create_timer(1.0).timeout

				player.return_camera()

		"Level_1":
			if not Global.chap1_node3_1_shown:
				Global.chap1_node3_1_shown = true

				DialogueManager.show_dialogue_balloon(
					load("res://dialogue/conversations/chap1_node3_1.dialogue"),
                    "start"
				)

				await DialogueManager.dialogue_ended

				var tigerguard = current_level.get_node("TigerGuard")
				player.focus_camera_to(tigerguard)

				await get_tree().create_timer(1.0).timeout
				player.return_camera()

		"Level_2":
			if not Global.chap1_node3_2_shown:
				Global.chap1_node3_2_shown = true

				DialogueManager.show_dialogue_balloon(
					load("res://dialogue/conversations/chap1_node3_2.dialogue"),
                    "start"
				)

				await DialogueManager.dialogue_ended

				var mc = current_level.get_node("Minecart")
				player.focus_camera_to(mc)

				await get_tree().create_timer(1.0).timeout
				player.return_camera()

		"Level_3":
			if not Global.chap1_node3_3_shown:
				Global.chap1_node3_3_shown = true

				DialogueManager.show_dialogue_balloon(
					load("res://dialogue/conversations/chap1_node3_3.dialogue"),
                    "start"
				)

				await DialogueManager.dialogue_ended

				var golemboss = current_level.get_node("GolemBoss")
				player.focus_camera_to(golemboss)

				await get_tree().create_timer(1.0).timeout
				player.return_camera()

		_:
			return
