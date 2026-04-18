extends CharacterBody2D

@export_file("*.dialogue") var dialogue_path: String = "res://game/chapter_4/node_11/dialogue/villager.dialogue"

var _is_talking: bool = false


func can_interact() -> int:
	return 0


func activate() -> void:
	_talk()


func _talk() -> void:
	if _is_talking:
		return

	var dlg = load(dialogue_path)
	if dlg == null:
		push_warning("Failed to load dialogue: " + dialogue_path)
		return

	_is_talking = true
	DialogueManager.show_dialogue_balloon(dlg, "start")
	await DialogueManager.dialogue_ended
	_is_talking = false
