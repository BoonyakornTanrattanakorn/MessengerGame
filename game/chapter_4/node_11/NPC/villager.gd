extends CharacterBody2D

var dialogue_path = "res://game/chapter_4/node_11/dialogue/villager_talk.dialogue"
var dialogue_tag = "start"

var _is_talking: bool = false
var _player_in_range: bool = false

@export var hide_if_tower_master_not_returned: bool = false

@onready var interaction_area: Area2D = $InteractArea
@onready var prompt_label: Label = $PromptLabel

func _ready() -> void:
	add_to_group("interaction_prompt_target")
	if hide_if_tower_master_not_returned and not GameState.chap4_node11_tower_master_returned:
		queue_free()
		return

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
		dialogue_tag = "inside_tower"
	elif GameState.chap4_node11_ice_ghost_dead:
		dialogue_tag = "after_ice_ghost"
	elif GameState.chap4_node11_villager_talked_once:
		dialogue_tag = "talked"
	
	_is_talking = true
	prompt_label.hide()
	DialogueManager.show_dialogue_balloon(load(dialogue_path), dialogue_tag)
	await DialogueManager.dialogue_ended
	_is_talking = false
	
	if dialogue_tag == "talked":
		ObjectiveManager.set_objective("Defeat the monster in the tower")
		SaveManager.save_game()
		
	if dialogue_tag == "after_ice_ghost":
		queue_free()
		GameState.chap4_node11_tower_master_returned = true
		ObjectiveManager.set_objective("Talk to the boss soldier\n(Optional) Read the archives in the tower")
		SaveManager.save_game()

	if not GameState.chap4_node11_villager_talked_once:
		GameState.chap4_node11_villager_talked_once = true
		SaveManager.save_game()

	if is_inside_tree():
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
