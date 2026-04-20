extends CharacterBody2D

var dialogue_path = "res://game/chapter_4/node_11/dialogue/villager_talk.dialogue"
var dialogue_tag = "start"

var _is_talking: bool = false

@export var hide_if_tower_master_not_returned: bool = false

func _ready() -> void:
	if hide_if_tower_master_not_returned and not GameState.chap4_node11_tower_master_returned:
		queue_free()

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
