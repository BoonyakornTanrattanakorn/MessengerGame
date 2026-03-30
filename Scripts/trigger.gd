extends Area2D

@export var trigger_id: int = 0
@export var trigger_once: bool = true

var has_triggered := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	if trigger_once and has_triggered:
		return

	has_triggered = true

	match trigger_id:
		1:
			handle_trigger_1()
		2:
			handle_trigger_2()
		3:
			handle_trigger_3()
		_:
			print("Unknown trigger_id:", trigger_id)

func handle_trigger_1() -> void:
	print("Trigger 1")
	var player = get_tree().get_first_node_in_group("player")
	var switch_node = get_tree().current_scene.get_node("LevelHolder/Chapter1_Node2/Door/lever_room1_a2")

	player.focus_camera_to(switch_node)

	await get_tree().create_timer(1.0).timeout

	DialogueManager.show_dialogue_balloon(
		preload("res://dialogue/conversations/chap1_node2.dialogue"),
		"after_first_room"
	)

	await DialogueManager.dialogue_ended

	player.return_camera()
	ObjectiveManager.set_objective("Use wind power to flip the switch 0/2")

func handle_trigger_2() -> void:
	print("Trigger 2")
	ObjectiveManager.set_objective("Continue exploring")

func handle_trigger_3() -> void:
	print("Trigger 3")
	ObjectiveManager.set_objective("Talk to the gatekeeper")
	
	
	# ScriptedObjects/ChapterGateNpc
