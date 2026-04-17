extends Area2D

@export var next_level_path: String = "res://game/chapter_3/node_3/node_3.tscn"
@export var spawn_position_in_next_level: Vector2 = Vector2(0, 0)
@export var facing_direction_on_warp: Vector2 = Vector2.RIGHT

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	hide_portal()
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return
	SaveManager.save_game()
	get_tree().change_scene_to_file("res://game/minigame_ver2/Level/main2.tscn")

func show_portal() -> void:
	show()
	set_meta("no_interact", false) if has_meta("no_interact") else null
	if collision_shape:
		collision_shape.disabled = false

func hide_portal() -> void:
	hide()
	set_meta("no_interact", true)
	if collision_shape:
		collision_shape.disabled = true
