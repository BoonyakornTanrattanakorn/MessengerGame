extends LevelEventHandler

@export var puzzle_manager: Node2D
@export var first_block: Node2D

func _ready() -> void:
	if Chap3Node8State.puzzle_1_completed and puzzle_manager and puzzle_manager.has_signal("puzzle_completed"):
		if puzzle_manager.exit_warp:
			puzzle_manager.exit_warp.show()

func handle_intro_for_level() -> void:
	if not GameState.chap3_node8_1_shown:
		GameState.chap3_node8_1_shown = true

		DialogueManager.show_dialogue_balloon(
			load("res://game/chapter_3/node_8/dialogue/chap3_node8.dialogue"),
			"puzzle_1_intro"
		)

		await DialogueManager.dialogue_ended

		if first_block:
			player.focus_camera_to(first_block)
			await get_tree().create_timer(1.0).timeout
			player.return_camera()
