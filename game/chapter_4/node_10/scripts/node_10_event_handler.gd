extends LevelEventHandler

@export var ice_layer: IceLayer

func _ready() -> void:
	add_to_group("level_event_handler")

func handle_intro_for_level() -> void:
	if not GameState.chap4_node1_shown:
		GameState.chap4_node1_shown = true

		DialogueManager.show_dialogue_balloon(
			load("res://game/chapter_4/node_10/dialogue/node_10.dialogue"),
			"start"
		)

		await DialogueManager.dialogue_ended
