extends LevelEventHandler

@export var pyramid_entrance: Node2D
@export var warp_to_node_9: Node2D

func on_level_loaded() -> void:
	if Chap3Node8State.all_puzzles_done():
		ObjectiveManager.set_objective("Leave the pyramid land")
		if warp_to_node_9 and warp_to_node_9.has_method("show_portal"):
			warp_to_node_9.show_portal()
	else:
		Chap3Node8State.update_objective()
		if warp_to_node_9 and warp_to_node_9.has_method("hide_portal"):
			warp_to_node_9.hide_portal()

func handle_intro_for_level() -> void:
	BGMManager.play_bgm("res://assets/audio/caravan.ogg", 0.0, true)
	if not GameState.chap3_node8_shown:
		GameState.chap3_node8_shown = true

		DialogueManager.show_dialogue_balloon(
			load("res://game/chapter_3/node_8/dialogue/chap3_node8_level_0.dialogue"),
			"start"
		)

		await DialogueManager.dialogue_ended

		if pyramid_entrance:
			player.focus_camera_to(pyramid_entrance)
			await get_tree().create_timer(1.5).timeout
			player.return_camera()
		SaveManager.save_game()
