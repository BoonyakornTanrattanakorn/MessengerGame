extends Area2D

@export_file("*.dialogue") var dialogue_path: String = "res://game/chapter_2/node_4/dialogue/cat_lady.dialogue"

var _player_in_range: bool = false
var _is_talking: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if _is_talking:
		return
	
	if _player_in_range and Input.is_action_just_pressed("interact"):
		_talk()

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		_player_in_range = false

func _talk() -> void:
	if _is_talking:
		return
	
	var dlg = load(dialogue_path)
	if dlg == null:
		push_warning("Failed to load dialogue: " + dialogue_path)
		return

	_is_talking = true

	if not Node4State.talked_to_village_chief:
		DialogueManager.show_dialogue_balloon(dlg, "before_chief")
	elif Node4State.second_insignia_obtained:
		if Node4State.both_insignias_obtained():
			DialogueManager.show_dialogue_balloon(dlg, "after_reward_all_done")
		else:
			DialogueManager.show_dialogue_balloon(dlg, "reward")
	elif Node4State.all_cats_found():
		DialogueManager.show_dialogue_balloon(dlg, "all_found")
	elif Node4State.cat_quest_started:
		DialogueManager.show_dialogue_balloon(dlg, "in_progress")
	else:
		DialogueManager.show_dialogue_balloon(dlg, "start")

	await DialogueManager.dialogue_ended
	_is_talking = false
