extends Area2D

@onready var prompt_label: Label = $PromptLabel

var player_in_range: bool = false
var is_talking: bool = false

const DIALOGUE = preload("res://game/chapter_3/subnode/cookie_run_guide.dialogue")

func _ready() -> void:
	prompt_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range or is_talking:
		return
	if event.is_action_pressed("interact"):
		_start_dialogue()

func _start_dialogue() -> void:
	is_talking = true
	prompt_label.visible = false
	DialogueManager.show_dialogue_balloon(DIALOGUE, "start")

func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return
	player_in_range = true
	if not is_talking:
		prompt_label.text = "Press F to talk"
		prompt_label.visible = true

func _on_body_exited(body: Node) -> void:
	if body.name != "Player":
		return
	player_in_range = false
	prompt_label.visible = false

func _on_dialogue_ended(_resource: Resource) -> void:
	is_talking = false
	if player_in_range:
		prompt_label.text = "Press F to talk"
		prompt_label.visible = true

func _enter_tree() -> void:
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func _exit_tree() -> void:
	if DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.disconnect(_on_dialogue_ended)
