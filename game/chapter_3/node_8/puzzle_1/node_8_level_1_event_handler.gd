extends LevelEventHandler

@export var puzzle_manager: Node2D

func _ready() -> void:
	if not puzzle_manager:
		puzzle_manager = get_node_or_null("Puzzle1Manager")
	if Chap3Node8State.puzzle_1_completed and puzzle_manager:
		var exit_warp := get_node_or_null("ExitWarp")
		if exit_warp:
			exit_warp.show()

func on_level_loaded() -> void:
	Chap3Node8State.update_objective()

func handle_intro_for_level() -> void:
	BGMManager.play_bgm("res://assets/audio/caravan.ogg", 0.0, true)
	if not GameState.chap3_node8_1_shown:
		GameState.chap3_node8_1_shown = true

		DialogueManager.show_dialogue_balloon(
			load("res://game/chapter_3/node_8/dialogue/chap3_node8_level_1.dialogue"),
			"start"
		)

		await DialogueManager.dialogue_ended

		var block_a := get_node_or_null("Puzzle1Manager/BlockA")
		var block_b := get_node_or_null("Puzzle1Manager/BlockB")
		var plate_decoy := get_node_or_null("Puzzle1Manager/PlateDecoy")
		if block_a:
			player.focus_camera_to(block_a)
			await get_tree().create_timer(1.0).timeout
		if block_b:
			player.focus_camera_to(block_b)
			await get_tree().create_timer(1.0).timeout
		if plate_decoy:
			player.focus_camera_to(plate_decoy)
			await get_tree().create_timer(1.0).timeout
		player.return_camera()
