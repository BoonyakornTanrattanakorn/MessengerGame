extends Trigger

@export var save_id = "node_10_trigger"
@export var save_scope = "scene"
@export var IceBlock: IceBlock

func handle_trigger():
	var player = get_tree().get_first_node_in_group("player")
	
	IceBlock.recover()
	player.focus_camera_to(IceBlock)

	await get_tree().create_timer(1.0).timeout

	DialogueManager.show_dialogue_balloon(
		preload("res://game/chapter_4/node_10/dialogue/node_10.dialogue"),
		"ice_block_found"
	)
	
	await DialogueManager.dialogue_ended

	player.return_camera()
	
	ObjectiveManager.set_objective("Use fire to melt the ice block")
