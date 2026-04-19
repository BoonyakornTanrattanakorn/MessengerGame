extends LevelEventHandler
@export var tower: Node2D
@export var castle: Node2D
@export var towerleader: Node2D
const Villager_DIALOGUE := preload("res://game/chapter_4/node_11/dialogue/villager.dialogue")
func on_level_loaded() -> void:
	if GameState.chap4_node11_soldier:
		#print("[Node11] chap4_node11_soldier is true, removing BossSoldier")
		_remove_boss_soldier()

func handle_intro_for_level() -> void:
	if not GameState.chap4_node11_shown:
		GameState.chap4_node11_shown = true

		if tower != null:
			player.focus_camera_to(tower)
			await get_tree().create_timer(1.5).timeout
			player.return_camera()
			await get_tree().create_timer(1.0).timeout

		if castle != null:
			player.focus_camera_to(castle)
			await get_tree().create_timer(1.5).timeout
			player.return_camera()
			await get_tree().create_timer(1.0).timeout
		
		if towerleader != null:
			player.focus_camera_to(towerleader)
			DialogueManager.show_dialogue_balloon(Villager_DIALOGUE, "start", [self])
			await DialogueManager.dialogue_ended
			await get_tree().create_timer(1.5).timeout
			player.return_camera()


func _remove_boss_soldier() -> void:
	var boss_soldier := get_node_or_null("NPC/BossSoldier")
	if boss_soldier == null:
		print("[Node11] BossSoldier not found on current level")
		return

	print("[Node11] Removing BossSoldier")
	boss_soldier.queue_free()
		
		
		
		
		
