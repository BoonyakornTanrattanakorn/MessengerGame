extends Warp


func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return
	if not visible:
		return
	SaveManager.save_game()
	
	get_player().earth_greater_locked = false
	
	get_tree().current_scene.call_deferred(
		"load_level",
		next_level_path,
		spawn_position_in_next_level,
		facing_direction_on_warp
	)
	
	
func get_player() -> Player: 
	return get_tree().get_first_node_in_group("player")
