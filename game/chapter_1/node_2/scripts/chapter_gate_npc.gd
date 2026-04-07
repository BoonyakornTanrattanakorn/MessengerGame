extends Area2D

@export var player_node_name: String = "Player"
@export var dialogue_resource: DialogueResource
@export var next_door_path: NodePath

@onready var prompt_label: Label = $PromptLabel
@onready var next_door: Node = get_node_or_null(next_door_path)

var player_in_range: bool = false
var is_talking: bool = false
var first_talk: bool = false

func _ready() -> void:
	prompt_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range:
		return
	if is_talking:
		return
	if event.is_action_pressed("interact"):
		start_dialogue()

func start_dialogue() -> void:
	if dialogue_resource == null:
		push_warning("NPC dialogue_resource is not assigned.")
		return

	is_talking = true
	prompt_label.visible = false

	var start_title := "npc_after_solved" if PuzzleState.puzzle_solved else "npc_start"

	# Pass "self" into extra_game_states so dialogue can call NPC.submit_answer(...)
	DialogueManager.show_dialogue_balloon(dialogue_resource, start_title, [self])
	
	if (!first_talk):
		first_talk = true
		if (PuzzleState.found_fragments.size() <= 0):
			ObjectiveManager.set_objective("Find all clues (0/4)")

func _on_body_entered(body: Node) -> void:
	if body.name == player_node_name:
		player_in_range = true
		if not is_talking:
			prompt_label.text = "Press F"
			prompt_label.visible = true

func _on_body_exited(body: Node) -> void:
	if body.name == player_node_name:
		player_in_range = false
		prompt_label.visible = false

func _on_dialogue_ended(_resource: Resource) -> void:
	is_talking = false
	if player_in_range:
		prompt_label.text = "Press F"
		prompt_label.visible = true

func submit_answer(answer: Array[String]) -> void:
	if PuzzleState.check_answer(answer):
		PuzzleState.puzzle_solved = true
		ObjectiveManager.clear_memorized_keywords()
		open_next_door()
	else:
		# nothing else needed here;
		# the dialogue branch already handles wrong-answer text
		pass

func open_next_door() -> void:
	if next_door == null:
		push_warning("NPC next_door_path is not assigned.")
		return

	if next_door.has_method("open"):
		next_door.open()
	elif next_door.has_method("unlock"):
		next_door.unlock()
	else:
		push_warning("Door has no open() or unlock() method.")

func _enter_tree() -> void:
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func _exit_tree() -> void:
	if DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.disconnect(_on_dialogue_ended)
