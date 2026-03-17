extends Area2D

@export var player_node_name: String = "Player"
@export var fragment_id: String = ""
@export var start_title: String = ""
@export var dialogue_resource: DialogueResource

@onready var prompt_label: Label = $PromptLabel

var player_in_range: bool = false
var is_talking: bool = false

func _ready() -> void:
	prompt_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range:
		return
	if is_talking:
		return
	if event.is_action_pressed("ui_accept"):
		read_paper()

func read_paper() -> void:
	if dialogue_resource == null:
		push_warning("Paper dialogue_resource is not assigned.")
		return
	if start_title == "":
		push_warning("Paper start_title is empty.")
		return

	is_talking = true
	prompt_label.visible = false

	PuzzleState.collect_fragment(fragment_id)
	DialogueManager.show_dialogue_balloon(dialogue_resource, start_title)

func _on_body_entered(body: Node) -> void:
	if body.name == player_node_name:
		player_in_range = true
		if not is_talking:
			prompt_label.text = "Read"
			prompt_label.visible = true

func _on_body_exited(body: Node) -> void:
	if body.name == player_node_name:
		player_in_range = false
		prompt_label.visible = false

func _on_dialogue_ended(_resource: Resource) -> void:
	is_talking = false
	if player_in_range:
		prompt_label.text = "Read"
		prompt_label.visible = true

func _enter_tree() -> void:
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func _exit_tree() -> void:
	if DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.disconnect(_on_dialogue_ended)
