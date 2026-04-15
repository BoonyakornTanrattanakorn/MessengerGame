class_name GovernorNPC
extends Node2D

@export var player_node_name: String = "Player"
@export var dialogue_resource: DialogueResource

@onready var prompt_label: Label = $PromptLabel
@onready var interaction_area: Area2D = $Area2D

var player_in_range: bool = false
var is_talking: bool = false

func _ready() -> void:
	prompt_label.visible = false
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	# Reset local talking state on scene load
	is_talking = false

func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range or is_talking:
		return
	if event.is_action_pressed("interact"):
		start_dialogue()

func start_dialogue() -> void:
	if dialogue_resource == null:
		push_warning("GovernorNPC dialogue_resource is not assigned.")
		return
	is_talking = true
	prompt_label.visible = false
	var title := "governor_after" if Node7State.talked_to_governor else "governor_first"
	DialogueManager.show_dialogue_balloon(dialogue_resource, title)

func _on_body_entered(body: Node) -> void:
	if body.name == player_node_name:
		player_in_range = true
		if not is_talking:
			prompt_label.visible = true

func _on_body_exited(body: Node) -> void:
	if body.name == player_node_name:
		player_in_range = false
		prompt_label.visible = false

func _on_dialogue_ended(resource: Resource) -> void:
	if resource != dialogue_resource:
		return
	is_talking = false
	if not Node7State.talked_to_governor:
		Node7State.talk_to_governor()
	if player_in_range:
		prompt_label.visible = true

func _enter_tree() -> void:
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func _exit_tree() -> void:
	if DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.disconnect(_on_dialogue_ended)
