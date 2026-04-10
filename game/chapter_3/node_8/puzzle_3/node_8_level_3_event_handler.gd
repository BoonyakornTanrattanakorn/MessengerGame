extends LevelEventHandler

@export var puzzle_manager: Node2D

func _ready() -> void:
	if not puzzle_manager:
		puzzle_manager = get_node_or_null("Puzzle3Manager")
	if Chap3Node8State.puzzle_3_completed and puzzle_manager:
		var exit_warp := get_node_or_null("ExitWarp")
		if exit_warp:
			exit_warp.show()
		for trap in puzzle_manager._traps:
			trap.queue_free()

func handle_intro_for_level() -> void:
	GameState.chap3_node8_3_shown = false  # temp: remove before commit
	if not GameState.chap3_node8_3_shown:
		GameState.chap3_node8_3_shown = true

		DialogueManager.show_dialogue_balloon(
			load("res://game/chapter_3/node_8/dialogue/chap3_node8_level_3.dialogue"),
			"start"
		)

		await DialogueManager.dialogue_ended

		var trap1 := get_node_or_null("Puzzle3Manager/Trap1")
		var trap2 := get_node_or_null("Puzzle3Manager/Trap2")
		var lever := get_node_or_null("ExitLever")
		if trap1:
			player.focus_camera_to(trap1)
			await get_tree().create_timer(1.0).timeout
		if trap2:
			player.focus_camera_to(trap2)
			await get_tree().create_timer(1.0).timeout
		if lever:
			player.focus_camera_to(lever)
			await get_tree().create_timer(1.0).timeout
		player.return_camera()
