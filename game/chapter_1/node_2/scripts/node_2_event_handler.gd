extends LevelEventHandler

func handle_intro_for_level() -> void:
	# Play BGM
	BGMManager.play_bgm("res://assets/audio/field_theme_1.ogg", 0.0, true)
	
	Global.chap1_node2_shown = true

	DialogueManager.show_dialogue_balloon(
		load("res://game/chapter_1/node_2/dialogue/node_2.dialogue"),
		"start"
	)

	await DialogueManager.dialogue_ended

	var switch_node = get_node("Door/lever_room0_a2")
	player.focus_camera_to(switch_node)

	await get_tree().create_timer(1.0).timeout
	player.return_camera()
