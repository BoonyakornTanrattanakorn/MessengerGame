extends LevelEventHandler

func on_level_loaded() -> void:
	pass

func handle_intro_for_level() -> void:
	BGMManager.play_bgm("caravan", 0.0, true)

	if GameState.chap3_subnode2_shown:
		return
	GameState.chap3_subnode2_shown = true

	DialogueManager.show_dialogue_balloon(
		load("res://game/chapter_3/subnode/subnode_2_intro.dialogue"),
		"start"
	)
	await DialogueManager.dialogue_ended

	var warp := get_node_or_null("WarpToBossWorm")
	if warp:
		player.focus_camera_to(warp)
		await get_tree().create_timer(1.5).timeout
		player.return_camera()
