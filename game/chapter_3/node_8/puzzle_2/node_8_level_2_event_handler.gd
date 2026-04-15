extends LevelEventHandler

@export var puzzle_manager: Node2D

func _ready() -> void:
	if not puzzle_manager:
		puzzle_manager = get_node_or_null("Puzzle2Manager")
	if Chap3Node8State.puzzle_2_completed and puzzle_manager:
		var exit_warp := get_node_or_null("ExitWarp")
		if exit_warp:
			exit_warp.show()
		puzzle_manager._is_solved = true

func on_level_loaded() -> void:
	Chap3Node8State.update_objective()

func handle_intro_for_level() -> void:
	GameState.chap3_node8_2_shown = false  # temp: remove before commit
	if not GameState.chap3_node8_2_shown:
		GameState.chap3_node8_2_shown = true

		DialogueManager.show_dialogue_balloon(
			load("res://game/chapter_3/node_8/dialogue/chap3_node8_level_2.dialogue"),
			"start"
		)

		await DialogueManager.dialogue_ended

		var hint_stone := get_node_or_null("HintStone")
		var sand_block := get_node_or_null("Puzzle2Manager/Symbol1/Cover1")
		if hint_stone:
			player.focus_camera_to(hint_stone)
			await get_tree().create_timer(1.5).timeout
		if sand_block:
			player.focus_camera_to(sand_block)
			await get_tree().create_timer(1.0).timeout
		player.return_camera()
