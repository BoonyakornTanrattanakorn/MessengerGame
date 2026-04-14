extends LevelEventHandler

@export var puzzle_manager: Node2D

func _ready() -> void:
	if not puzzle_manager:
		puzzle_manager = get_node_or_null("Puzzle3Manager")

	if Chap3Node8State.puzzle_3_completed:
		var exit_warp := get_node_or_null("ExitWarp")
		if exit_warp:
			exit_warp.show()
		var guardian := get_node_or_null("StoneGuardian")
		if guardian:
			guardian.queue_free()

func handle_intro_for_level() -> void:
	GameState.chap3_node8_3_shown = false  # temp: remove before commit
	if not GameState.chap3_node8_3_shown:
		GameState.chap3_node8_3_shown = true

		DialogueManager.show_dialogue_balloon(
			load("res://game/chapter_3/node_8/dialogue/chap3_node8_level_3.dialogue"),
			"start"
		)

		await DialogueManager.dialogue_ended

		var guardian := get_node_or_null("StoneGuardian")
		if guardian:
			player.focus_camera_to(guardian)
			await get_tree().create_timer(1.5).timeout
		player.return_camera()

		if puzzle_manager and puzzle_manager.has_method("activate_guardian"):
			puzzle_manager.activate_guardian()
