extends Area2D

@export var player_node_name: String = "Player"
@export var dialogue_resource: DialogueResource

@onready var prompt_label: Label = $PromptLabel

var player_in_range: bool = false
var is_talking: bool = false
var talk_count: int = 0

func _ready() -> void:
	prompt_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range or is_talking:
		return
	if event.is_action_pressed("interact"):
		start_dialogue()

func start_dialogue() -> void:
	if dialogue_resource == null:
		push_warning("CityNPC dialogue_resource is not assigned.")
		return
	is_talking = true
	prompt_label.visible = false
	var title := "npc_repeat" if talk_count > 0 else "npc_first"
	talk_count += 1
	DialogueManager.show_dialogue_balloon(dialogue_resource, title)

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

func _enter_tree() -> void:
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func _exit_tree() -> void:
	if DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.disconnect(_on_dialogue_ended)
