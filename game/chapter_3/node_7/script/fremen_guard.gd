class_name FremenGuard
extends Area2D

@export var player_node_name: String = "Player"
@export var dialogue_resource: DialogueResource

@onready var prompt_label: Label = $PromptLabel
@onready var blocker = $StaticBody2D/CollisionShape2D

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
	if event.is_action_pressed("interact"):
		start_dialogue()

func start_dialogue() -> void:
	if dialogue_resource == null:
		push_warning("FremenGuard dialogue_resource is not assigned.")
		return
	is_talking = true
	prompt_label.visible = false
	var start_title := "guard_after_solved" if Node7State.riddle_solved else "guard_start"
	DialogueManager.show_dialogue_balloon(dialogue_resource, start_title)

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
	if Node7State.riddle_solved:
		_step_aside()
	elif player_in_range:
		prompt_label.text = "Press F"
		prompt_label.visible = true

func _step_aside() -> void:
	prompt_label.visible = false
	blocker.set_deferred("disabled", true)
	var tween = create_tween()
	tween.tween_property(self, "position", position + Vector2(60, 0), 0.5)
	await tween.finished
	visible = false

func _enter_tree() -> void:
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func _exit_tree() -> void:
	if DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.disconnect(_on_dialogue_ended)
