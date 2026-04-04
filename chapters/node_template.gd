extends Node2D
class_name NodeTemplate

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

func load_level(level_path: String, player_spawn_position: Vector2, spawn_facing_direction: Vector2 = Vector2.ZERO) -> void:
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
	if spawn_facing_direction != Vector2.ZERO and player.has_method("set_facing_direction"):
		player.set_facing_direction(spawn_facing_direction)
	
	if current_level.name in ["Level_0"]:
		# Node-specific post-load hook
		_on_level_loaded()
	
	await get_tree().process_frame
	await _run_level_intro_if_needed()

func _run_level_intro_if_needed() -> void:
	if current_level == null:
		return

	# Delegate node-specific intro handling to subclasses
	await _handle_intro_for_level(current_level.name)

func _handle_intro_for_level(level_name: String) -> void:
	# Default: no-op. Subclasses should override.
	return

func _on_level_loaded() -> void:
	# Default post-load hook for subclasses.
	return
