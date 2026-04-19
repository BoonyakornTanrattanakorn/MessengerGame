extends LevelEventHandler

func on_level_loaded() -> void:
	print("Village level (UPPER) loaded")
	GameState.save()

func handle_intro_for_level() -> void:
	pass
