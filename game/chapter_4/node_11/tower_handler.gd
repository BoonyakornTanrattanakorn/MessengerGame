extends LevelEventHandler

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
	await get_tree().create_timer(focus_duration).timeout
	player.return_camera()
