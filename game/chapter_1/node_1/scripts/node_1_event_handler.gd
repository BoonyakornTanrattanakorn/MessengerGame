extends LevelEventHandler

func on_level_loaded() -> void:
	# Reserved for node-specific initialization after the level is loaded.
	print("Chapter1 Node1 Loaded")

func handle_intro_for_level() -> void:
	# Node11 currently has no intro cutscene.
	
	print("Chapter1 Node1 Intro")
