extends CharacterBody2D

@export_file("*.dialogue") var dialogue_path: String = "res://game/chapter_4/node_11/dialogue/villager_talk.dialogue"
@export_file("*.dialogue") var dialogue_path_after_first: String = "res://game/chapter_4/node_11/dialogue/villager_talk2.dialogue"

var _is_talking: bool = false


func can_interact() -> int:
	return 0


func activate() -> void:
	_talk()


func _talk() -> void:
	if _is_talking:
		return

	var selected_dialogue_path: String

	if GameState.chap4_node11_villager_talked_once:
		selected_dialogue_path = dialogue_path_after_first
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

	if not GameState.chap4_node11_villager_talked_once:
		GameState.chap4_node11_villager_talked_once = true
		SaveManager.save_game()
