extends Node2D

@onready var player: Node2D = $Player
@onready var level_holder: Node2D = $LevelHolder

var current_level: Node = null

func _ready() -> void:
	if level_holder.get_child_count() > 0:
		current_level = level_holder.get_child(0)
		
	# Play BGM
	BGMManager.play_bgm("res://assets/audio/field_theme_1.ogg", 0.0, true)
	
	await get_tree().process_frame
	await _run_level_intro_if_needed()

	#if not Global.tutorial_shown:
		#Global.tutorial_shown = true
		#DialogueManager.show_dialogue_balloon(
			#load("res://dialogue/conversations/tutorial.dialogue"),
			#"start"
		#)
		#
		#await DialogueManager.dialogue_ended
#
		#var switch_node = get_tree().current_scene.get_node("LevelHolder/Chapter1_Node2/Door/lever_room0_a2")
		#player.focus_camera_to(switch_node)
#
		#await get_tree().create_timer(1.0).timeout
		#player.return_camera()

func load_level(level_path: String, player_spawn_position: Vector2) -> void:
	var packed_level := load(level_path) as PackedScene
	if packed_level == null:
		push_error("โหลดแมพไม่ได้: %s" % level_path)
		return

	# ล้างเลเวลเก่าทิ้งหมดจาก LevelHolder
	for child in level_holder.get_children():
		child.queue_free()

	# รอ 1 physics frame ให้ collision เก่าหายจริงก่อน
	await get_tree().physics_frame

	var new_level := packed_level.instantiate()
	level_holder.add_child(new_level)
	current_level = new_level

	player.global_position = player_spawn_position
	
	if current_level.name in ["Level_0"]:
		Node3State.start_node3_objective()
	
	await get_tree().process_frame
	await _run_level_intro_if_needed()

func _run_level_intro_if_needed() -> void:
	if current_level == null:
		return

	if current_level.name == "Chapter1_Node2" and not Global.chap1_node2_shown:
		Global.chap1_node2_shown = true

		DialogueManager.show_dialogue_balloon(
			load("res://dialogue/conversations/chap1_node2.dialogue"),
			"start"
		)

		await DialogueManager.dialogue_ended

		var switch_node = current_level.get_node("Door/lever_room0_a2")
		player.focus_camera_to(switch_node)

		await get_tree().create_timer(1.0).timeout
		player.return_camera()

	elif current_level.name == "Level_0" and not Global.chap1_node3_shown:
		Global.chap1_node3_shown = true

		DialogueManager.show_dialogue_balloon(
			load("res://dialogue/conversations/chap1_node3.dialogue"),
			"start"
		)

		await DialogueManager.dialogue_ended

		var final_door = current_level.get_node("FinalDoor")
		player.focus_camera_to(final_door)
		await get_tree().create_timer(1.0).timeout
		
		var wtl1 = current_level.get_node("WarpToLevel1/CollisionShape2D")
		player.focus_camera_to(wtl1)
		await get_tree().create_timer(1.0).timeout
		
		var wtl2 = current_level.get_node("WarpToLevel2/CollisionShape2D")
		player.focus_camera_to(wtl2)
		await get_tree().create_timer(1.0).timeout
		
		var wtl3 = current_level.get_node("WarpToLevel3/CollisionShape2D")
		player.focus_camera_to(wtl3)
		await get_tree().create_timer(1.0).timeout
		
		player.return_camera()
		
	elif current_level.name == "Level_1" and not Global.chap1_node3_1_shown:
		Global.chap1_node3_1_shown = true

		DialogueManager.show_dialogue_balloon(
			load("res://dialogue/conversations/chap1_node3_1.dialogue"),
			"start"
		)

		await DialogueManager.dialogue_ended

		var tigerguard = current_level.get_node("TigerGuard")
		player.focus_camera_to(tigerguard)

		await get_tree().create_timer(1.0).timeout
		player.return_camera()
		
	elif current_level.name == "Level_2" and not Global.chap1_node3_2_shown:
		Global.chap1_node3_2_shown = true

		DialogueManager.show_dialogue_balloon(
			load("res://dialogue/conversations/chap1_node3_2.dialogue"),
			"start"
		)

		await DialogueManager.dialogue_ended

		var mc = current_level.get_node("Minecart")
		player.focus_camera_to(mc)

		await get_tree().create_timer(1.0).timeout
		player.return_camera()
		
	elif current_level.name == "Level_3" and not Global.chap1_node3_3_shown:
		Global.chap1_node3_3_shown = true

		DialogueManager.show_dialogue_balloon(
			load("res://dialogue/conversations/chap1_node3_3.dialogue"),
			"start"
		)

		await DialogueManager.dialogue_ended

		var golemboss = current_level.get_node("GolemBoss")
		player.focus_camera_to(golemboss)

		await get_tree().create_timer(1.0).timeout
		player.return_camera()
