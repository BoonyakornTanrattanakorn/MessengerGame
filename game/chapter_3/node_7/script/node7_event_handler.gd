extends LevelEventHandler

@export var switch_node: Node2D
@export var dialogue_resource: DialogueResource

func handle_intro_for_level() -> void:
	if Node7State.intro_objective_started:
		BGMManager.play_bgm("res://assets/audio/caravan.ogg", 0.0, true)
		Node7State.update_objective()
		return

	Node7State.reset()
	BGMManager.play_bgm("res://assets/audio/caravan.ogg", 0.0, true)
	Node7State.start_desert_objective()
	
	await _play_intro_dialogue()
	
	if player and player.has_method("focus_camera_to") and switch_node:
		player.focus_camera_to(switch_node)
		await get_tree().create_timer(2.0).timeout
		player.return_camera()

func _play_intro_dialogue() -> void:
	if dialogue_resource == null:
		return
	DialogueManager.show_dialogue_balloon(dialogue_resource, "start")
	await DialogueManager.dialogue_ended
