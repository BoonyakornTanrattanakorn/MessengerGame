extends LevelEventHandler
@export var Worm: Node2D

func on_level_loaded() -> void:
	pass

func handle_intro_for_level() -> void:
	BGMManager.play_bgm("caravan", 0.0, true)

	if GameState.chap3_subnode4_shown:
		return
	GameState.chap3_subnode4_shown = true

	DialogueManager.show_dialogue_balloon(
		load("res://game/chapter_3/subnode/subnode_4_intro.dialogue"),
		"start"
	)
	await DialogueManager.dialogue_ended

	if Worm:
		player.focus_camera_to(Worm)
		await get_tree().create_timer(1.5).timeout
		player.return_camera()
