extends Area2D

var dialogue := load("res://game/chapter_4/node_11/dialogue/bookcase_clue.dialogue")

var _is_talking := false

func can_interact() -> int:
	return 0

func activate() -> void:
	if _is_talking:
		return

	if dialogue == null:
		push_warning("Failed to load dialogue resource for bookcases")
		return

	var tag := _resolve_tag_from_nearest_hitbox()
	_is_talking = true
	DialogueManager.show_dialogue_balloon(dialogue, tag)
	await DialogueManager.dialogue_ended
	_is_talking = false

	if tag == "clue" and not GameState.clue_4_unlocked:
		GameState.clue_4_unlocked = true
		ObjectiveManager.set_objective("Talk to the boss soldier")
		SaveManager.save_game()

func _resolve_tag_from_nearest_hitbox() -> String:
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not (player is Node2D):
		return "normal"

	var player_pos: Vector2 = (player as Node2D).global_position
	var nearest_name := ""
	var nearest_distance := INF

	for child in get_children():
		if child is CollisionShape2D:
			var hitbox := child as CollisionShape2D
			if hitbox.disabled:
				continue

			var distance := player_pos.distance_to(hitbox.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_name = hitbox.name.to_lower()

	if nearest_name.find("clue") != -1:
		return "clue"

	return "normal"
