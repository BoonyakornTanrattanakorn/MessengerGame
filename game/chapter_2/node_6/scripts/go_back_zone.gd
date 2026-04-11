extends Area2D

var dialogue = load("res://game/chapter_2/node_6/dialogue/go_back.dialogue")


func _is_player_hit_or_hurt_area(area: Area2D) -> bool:
	if area.is_in_group("player_hurtbox"):
		return true

	var area_name := area.name.to_lower()
	return area_name.contains("hitbox") or area_name.contains("hurtbox")


func _on_area_entered(area: Area2D) -> void:
	if not _is_player_hit_or_hurt_area(area):
		return

	DialogueManager.show_dialogue_balloon(
			dialogue,
            "start"
		)
		
	await DialogueManager.dialogue_ended
