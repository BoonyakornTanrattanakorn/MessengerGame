extends CheckPoint_Node10


func _on_body_entered(body):
	if(!is_reached): 
		if body.is_in_group("player"):
			is_reached = true
			SaveManager.save_game()
	
	level_manager.current_room = get_parent()
	level_manager.player_checkpoint_position = body.global_position
