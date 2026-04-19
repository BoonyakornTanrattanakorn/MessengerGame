class_name FremenGuard
extends Node2D

@export var player_node_name: String = "Player"
@export var dialogue_resource: DialogueResource

# ADD THESE — assign each statue node in the Godot editor
@export var statue_king: Node2D
@export var statue_knight: Node2D
@export var statue_princess: Node2D
@export var statue_scarab: Node2D
@export var statue_villager: Node2D
@export var stone_tablet: Area2D

@onready var prompt_label: Label = $PromptLabel
@onready var blocker = $StaticBody2D/CollisionShape2D
@onready var interaction_area: Area2D = $Area2D

var player_in_range: bool = false
var is_talking: bool = false

func _ready() -> void:
	prompt_label.visible = false
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range or is_talking:
		return
	if event.is_action_pressed("interact"):
		start_dialogue()

func start_dialogue() -> void:
	if dialogue_resource == null: return
	is_talking = true
	prompt_label.visible = false
	var start_title: String
	if Node7State.riddle_solved:
		start_title = "guard_after_solved"
	elif Node7State.talked_to_guard:
		start_title = "guard_not_solved"  # ← talked before but puzzle not done yet
	else:
		start_title = "guard_start"
	DialogueManager.show_dialogue_balloon(dialogue_resource, start_title)

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
	if not Node7State.talked_to_guard:
		Node7State.talk_to_guard_done()
		await _pan_camera_to_statues()
	elif Node7State.riddle_solved and not Node7State.talked_to_guard_after_riddle:
		Node7State.talk_to_guard_after_riddle_done()  # ← sets flag → "Talk to governor"
	if Node7State.riddle_solved:
		_step_aside()
	elif player_in_range:
		prompt_label.visible = true

func _pan_camera_to_statues() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player or not player.has_method("focus_camera_to"):
		return

	var statues := [statue_king, statue_knight, statue_princess, statue_scarab, statue_villager]
	for statue in statues:
		if statue == null:
			continue
		player.focus_camera_to(statue)
		await get_tree().create_timer(2.0).timeout

	player.return_camera()
	await get_tree().create_timer(0.2).timeout

	# MC reacts after seeing all statues
	DialogueManager.show_dialogue_balloon(dialogue_resource, "guard_hint")
	await DialogueManager.dialogue_ended

	# Pan to stone tablet after MC finishes speaking
	if stone_tablet:
		player.focus_camera_to(stone_tablet)
		await get_tree().create_timer(2.0).timeout
		player.return_camera()

func _step_aside() -> void:
	prompt_label.visible = false
	blocker.set_deferred("disabled", true)
	var tween = create_tween()
	tween.tween_property(self, "position", position + Vector2(0, -40), 0.5)

func _enter_tree() -> void:
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func _exit_tree() -> void:
	if DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.disconnect(_on_dialogue_ended)
