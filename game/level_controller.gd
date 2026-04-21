extends Node2D
class_name NodeTemplate

@onready var player: Node2D = $Player
@onready var level_holder: Node2D = $LevelHolder

var current_level: Node = null

func _ready() -> void:
	if GameState.pending_level != "":
		var path := GameState.pending_level
		var spawn := GameState.pending_spawn
		var facing := GameState.pending_facing
		GameState.pending_level = ""
		await load_level(path, spawn, facing)
		return

	if level_holder.get_child_count() > 0:
		current_level = level_holder.get_child(0)

	await get_tree().process_frame
	await _run_level_intro_if_needed()

func load_level(level_path: String, player_spawn_position: Vector2, spawn_facing_direction: Vector2 = Vector2.ZERO) -> void:
	var packed_level := load(level_path) as PackedScene
	if packed_level == null:
		push_error("โหลดแมพไม่ได้: %s" % level_path)
		return

	# ล้างเลเวลเก่าทิ้งหมดจาก LevelHolder
	#for child in level_holder.get_children():
	#	child.queue_free()

	# รอ 1 physics frame ให้ collision เก่าหายจริงก่อน
	#await get_tree().physics_frame

	var new_level := packed_level.instantiate()
	level_holder.add_child(new_level)
	current_level = new_level

	player.global_position = player_spawn_position
	if spawn_facing_direction != Vector2.ZERO and player.has_method("set_facing_direction"):
		player.set_facing_direction(spawn_facing_direction)
	
	current_level.on_level_loaded()
	
	for child in level_holder.get_children():
		if child != current_level:
			child.queue_free()
	await get_tree().physics_frame
	await get_tree().process_frame
	SaveManager.restore_level_objects()
	await _run_level_intro_if_needed()

func _run_level_intro_if_needed() -> void:
	if current_level == null:
		return

	# Delegate node-specific intro handling to subclasses
	await current_level.handle_intro_for_level()
	SaveManager.save_game()

func _on_level_loaded() -> void:
	# Default post-load hook for subclasses.
	return
