extends LevelEventHandler

func on_level_loaded() -> void:
	pass

func handle_intro_for_level() -> void:
	BGMManager.play_bgm("res://assets/audio/caravan.ogg", 0.0, true)

	if GameState.chap3_subnode1_shown:
		return
	GameState.chap3_subnode1_shown = true

	DialogueManager.show_dialogue_balloon(
		load("res://game/chapter_3/subnode/subnode_1_intro.dialogue"),
		"start"
	)
	await DialogueManager.dialogue_ended

	var camel_station := get_node_or_null("CamelStation")
	if camel_station:
		player.focus_camera_to(camel_station)
		await get_tree().create_timer(1.5).timeout
		player.return_camera()
