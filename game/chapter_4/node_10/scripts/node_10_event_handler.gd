extends LevelEventHandler

@export var ice_layer: IceLayer



func _ready() -> void:
	add_to_group("level_event_handler")


func on_level_loaded() -> void:
	pass

func handle_intro_for_level() -> void:
	if not GameState.chap4_node10_shown:
		GameState.chap4_node10_shown = true

		DialogueManager.show_dialogue_balloon(
			load("res://game/chapter_4/node_10/dialogue/node_10.dialogue"),
			"start"
		)

		await DialogueManager.dialogue_ended
		
		ObjectiveManager.set_objective("Explore the frozen cave")
