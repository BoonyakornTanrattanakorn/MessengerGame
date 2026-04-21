extends CharacterBody2D

var dialogue = load("res://game/chapter_4/node_11/dialogue/soldier_talk.dialogue")
var dialogue_tag = "no_code"

@onready var interaction_area: Area2D = $InteractArea
@onready var prompt_label: Label = $PromptLabel

var _is_talking: bool = false
var _player_in_range: bool = false


func _ready() -> void:
	add_to_group("interaction_prompt_target")
	prompt_label.hide()
	prompt_label.top_level = true
	prompt_label.z_index = 100
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
	prompt_label.hide()
	DialogueManager.show_dialogue_balloon(dialogue, dialogue_tag)
	await DialogueManager.dialogue_ended
	_is_talking = false

	if dialogue_tag == "has_code" and not GameState.chap4_node11_soldier:
		GameState.chap4_node11_soldier = true
		ObjectiveManager.set_objective("Go into the palace")
		_remove_boss_soldier()
		SaveManager.save_game()
		return

	_refresh_prompt()


func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		body.interact_with = self
		_refresh_prompt()


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		prompt_label.hide()
		if body.interact_with == self:
			body.interact_with = null


func _refresh_prompt() -> void:
	if _player_in_range and not _is_talking:
		prompt_label.text = "Press F to talk"
		prompt_label.global_position = global_position + Vector2(-54, -42)
		prompt_label.show()
	else:
		prompt_label.hide()


func show_interaction_prompt() -> void:
	_player_in_range = true
	_refresh_prompt()


func hide_interaction_prompt() -> void:
	_player_in_range = false
	prompt_label.hide()


func _remove_boss_soldier() -> void:
	print("[BossSoldier] Removing BossSoldier only")
	queue_free()
