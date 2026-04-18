extends LevelEventHandler
@export var ice: Node2D

func on_level_loaded() -> void:
	# Reserved for tower-specific initialization after the level is loaded.
	pass

func handle_intro_for_level() -> void:
	if not GameState.chap4_tower_1st_floor_shown:
		GameState.chap4_tower_1st_floor_shown = true

		if ice != null:
			player.focus_camera_to(ice)
			await get_tree().create_timer(1.5).timeout
			player.return_camera()
