extends CharacterBody2D

var dialogue = load("res://game/chapter_4/node_11/dialogue/soldier_talk.dialogue")
var dialogue_tag = "no_code"

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

	if GameState.chap4_node11_tower_master_returned:
		dialogue_tag = "has_code"

	_is_talking = true
	DialogueManager.show_dialogue_balloon(dialogue, dialogue_tag)
	await DialogueManager.dialogue_ended
	_is_talking = false

	if dialogue_tag == "has_code" and not GameState.chap4_node11_soldier:
		GameState.chap4_node11_soldier = true
		ObjectiveManager.set_objective("Go into the palace")
		_remove_boss_soldier()
		SaveManager.save_game()


func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.interact_with = self


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and body.interact_with == self:
		body.interact_with = null


func _remove_boss_soldier() -> void:
	print("[BossSoldier] Removing BossSoldier only")
	queue_free()
