extends Node2D

@onready var player: Node2D = $Player
@onready var level_holder: Node2D = $LevelHolder

var current_level: Node = null

func _ready() -> void:
	if level_holder.get_child_count() > 0:
		current_level = level_holder.get_child(0)
	
	# Play BGM
	BGMManager.play_bgm("res://assets/audio/testBGM.ogg", 0.0, true)

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
