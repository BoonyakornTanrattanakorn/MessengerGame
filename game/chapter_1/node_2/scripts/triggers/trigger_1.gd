extends Trigger

@export var save_id = "trigger1"
@export var save_scope = "scene"
@export var switch_node: Node2D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func handle_trigger():
	print("Trigger 1")
	var player = get_tree().get_first_node_in_group("player")

	player.focus_camera_to(switch_node)

	await get_tree().create_timer(1.0).timeout

	DialogueManager.show_dialogue_balloon(
		preload("res://game/chapter_1/node_2/dialogue/node_2.dialogue"),
		"after_first_room"
	)
	
	await DialogueManager.dialogue_ended

	player.return_camera()
	ObjectiveManager.set_objective("Flip the switch (0/2)")
