extends LevelEventHandler

const ICE_GHOST_DIALOGUE := preload("res://game/chapter_4/node_11/dialogue/ice_ghost.dialogue")

@export var tower: Node2D
@export var focus_delay: float = 0.2
@export var focus_duration: float = 1.5

func on_level_loaded() -> void:
	if tower == null:
		tower = get_tree().current_scene.find_child("Tower", true, false) as Node2D

func handle_intro_for_level() -> void:
	if player == null:
		return
	if tower == null or not is_instance_valid(tower):
		tower = get_tree().current_scene.find_child("Tower", true, false) as Node2D
	if tower == null:
		return

	await get_tree().create_timer(focus_delay).timeout
	player.focus_camera_to(tower)
	if ICE_GHOST_DIALOGUE != null:
		DialogueManager.show_dialogue_balloon(ICE_GHOST_DIALOGUE, "start", [self])
		await DialogueManager.dialogue_ended
	await get_tree().create_timer(focus_duration).timeout
	player.return_camera()
