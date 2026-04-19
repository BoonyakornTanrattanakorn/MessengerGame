extends LevelEventHandler

func on_level_loaded() -> void:
	Node7State.update_objective()


func handle_intro_for_level() -> void:
	BGMManager.play_bgm("caravan", 0.0, true)
	Node7State.update_objective()
