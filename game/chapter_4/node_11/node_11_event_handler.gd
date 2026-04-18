extends LevelEventHandler
@export var tower: Node2D
@export var castle: Node2D

func on_level_loaded() -> void:
	# Reserved for node-specific initialization after the level is loaded.
	pass

func handle_intro_for_level() -> void:
	if not GameState.chap4_node11_shown:
		GameState.chap4_node11_shown = true

		if tower != null:
			player.focus_camera_to(tower)
			await get_tree().create_timer(1.5).timeout
			player.return_camera()
			await get_tree().create_timer(1.0).timeout

		if castle != null:
			player.focus_camera_to(castle)
			await get_tree().create_timer(1.5).timeout
			player.return_camera()
