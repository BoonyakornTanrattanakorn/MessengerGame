extends LevelEventHandler

var _exit_opening_started: bool = false
var _exit_opened: bool = false

func _ready() -> void:
	add_to_group("level_event_handler")

func on_level_loaded() -> void:
	print("Village level loaded")
	
	if Node4State.exit_gate_opened:
		_hide_exit_door_immediately()

func handle_intro_for_level() -> void:
	Node4State.start_node4()
	
	if not GameState.chap2_node4_shown:
		GameState.chap2_node4_shown = true
		
		# Play BGM
		BGMManager.play_bgm("res://assets/audio/chapter2.ogg", 0.0, true)

		DialogueManager.show_dialogue_balloon(
			load("res://game/chapter_2/node_4/dialogue/intro_node4.dialogue"),
			"start"
		)

		await DialogueManager.dialogue_ended

		var chief = get_node("VillageChief")
		player.focus_camera_to(chief)
		await get_tree().create_timer(1.0).timeout
		player.return_camera()

func trigger_exit_open() -> void:
	if _exit_opening_started or _exit_opened:
		return
	
	await _start_exit_open_sequence()

func _start_exit_open_sequence() -> void:
	_exit_opening_started = true
	
	var wall = get_node_or_null("ExitDoor")
	var camera_point = get_node_or_null("ExitDoorCameraPoint/CollisionShape2D")
	
	if wall == null:
		push_warning("ExitDoor not found")
		_exit_opened = true
		return

	if camera_point != null:
		player.focus_camera_to(camera_point)
	else:
		player.focus_camera_to(wall)

	await get_tree().create_timer(0.8).timeout

	for i in range(6):
		wall.visible = false
		await get_tree().create_timer(0.10).timeout
		wall.visible = true
		await get_tree().create_timer(0.10).timeout

	wall.visible = false
	wall.set("collision_enabled", false)

	Node4State.open_exit_gate()

	await get_tree().create_timer(0.4).timeout
	player.return_camera()

	_exit_opened = true

func _hide_exit_door_immediately() -> void:
	var wall = get_node_or_null("ExitDoor")
	if wall == null:
		return
	
	wall.visible = false
	wall.set("collision_enabled", false)

	_exit_opened = true
	_exit_opening_started = true
