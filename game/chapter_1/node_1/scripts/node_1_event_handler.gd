extends LevelEventHandler

@export var switch_node: Node2D
@export var dialogue_resource: DialogueResource

func on_level_loaded() -> void:
	print("Chapter1 Node1 Loaded")

func handle_intro_for_level() -> void:
	if not GameState.chap1_node1_shown:
		GameState.chap1_node1_shown = true
		
		print("Chapter1 Node1 Intro")

		await _play_intro_dialogue()

		if player and player.has_method("focus_camera_to") and switch_node:
			player.focus_camera_to(switch_node)
			await get_tree().create_timer(2.0).timeout
			player.return_camera()

		await _play_knight_dialogue()
		
		_set_objective_talk_to_knight()

func _play_intro_dialogue() -> void:
	if dialogue_resource == null:
		return
	DialogueManager.show_dialogue_balloon(dialogue_resource, "start")
	await DialogueManager.dialogue_ended

func _play_knight_dialogue() -> void:
	if dialogue_resource == null:
		return
	DialogueManager.show_dialogue_balloon(dialogue_resource, "knight_spotted")
	await DialogueManager.dialogue_ended

func _set_objective_talk_to_knight() -> void:
	ObjectiveManager.set_objective("Talk to the knight")

func on_knight_dialogue_finished() -> void:
	ObjectiveManager.set_objective("Head to the secret passage")
