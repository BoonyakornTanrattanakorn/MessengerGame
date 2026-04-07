extends LevelEventHandler

func handle_intro_for_level() -> void:
	# Play BGM
	BGMManager.play_bgm("res://assets/audio/field_theme_1.ogg", 0.0, true)
