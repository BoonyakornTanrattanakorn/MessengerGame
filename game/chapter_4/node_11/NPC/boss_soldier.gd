extends CharacterBody2D

@export_file("*.dialogue") var dialogue_path: String = "res://game/chapter_4/node_11/dialogue/soldier_talk.dialogue"
@export_file("*.dialogue") var dialogue_path_after_clue: String = "res://game/chapter_4/node_11/dialogue/soldier_talk2.dialogue"

@onready var interaction_area: Area2D = $InteractArea

var _is_talking: bool = false


func _ready() -> void:
	interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	interaction_area.body_exited.connect(_on_interaction_area_body_exited)


func can_interact() -> int:
	return 0


func activate() -> void:
	_talk()


func _talk() -> void:
	if _is_talking:
		return

	var selected_dialogue_path: String

	if GameState.clue_4_unlocked:
		selected_dialogue_path = dialogue_path_after_clue
	else:
		selected_dialogue_path = dialogue_path

	var dlg = load(selected_dialogue_path)
	if dlg == null:
		push_warning("Failed to load dialogue: " + selected_dialogue_path)
		return

	_is_talking = true
	DialogueManager.show_dialogue_balloon(dlg, "start")
	await DialogueManager.dialogue_ended
	_is_talking = false


func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.interact_with = self


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and body.interact_with == self:
		body.interact_with = null
