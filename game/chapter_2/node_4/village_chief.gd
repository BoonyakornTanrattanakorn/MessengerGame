extends Area2D

@export_file("*.dialogue") var dialogue_path: String = "res://game/chapter_2/node_4/dialogue/village_chief.dialogue"

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
		DialogueManager.show_dialogue_balloon(dlg, "start")
	else:
		var count = Node4State.insignias_obtained_count()
		
		if count >= 2:
			DialogueManager.show_dialogue_balloon(dlg, "after_both")
		elif count == 1:
			DialogueManager.show_dialogue_balloon(dlg, "after_one")
		else:
			DialogueManager.show_dialogue_balloon(dlg, "progress")

	await DialogueManager.dialogue_ended
	_is_talking = false
