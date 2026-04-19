extends Area2D

@export var player_node_name: String = "Player"
@export var dialogue_resource: DialogueResource

@onready var prompt_label: Label = $PromptLabel  # optional, if you have one

var player_in_range := false

func _ready() -> void:
	prompt_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range:
		return
	if event.is_action_pressed("interact"):
		_read_tablet()

func _read_tablet() -> void:
	if dialogue_resource == null:
		push_warning("Stone tablet dialogue_resource not assigned.")
		return
	DialogueManager.show_dialogue_balloon(dialogue_resource, "stone_tablet")

func _on_body_entered(body: Node) -> void:
	if body.name == player_node_name:
		player_in_range = true
		prompt_label.visible = true
			
func _on_body_exited(body: Node) -> void:
	if body.name == player_node_name:
		player_in_range = false
		prompt_label.visible = false
