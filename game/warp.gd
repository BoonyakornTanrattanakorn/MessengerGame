extends Area2D
class_name Warp

@export var next_level_path: String
@export var spawn_position_in_next_level: Vector2
@export var facing_direction_on_warp: Vector2

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return
	SaveManager.save_game()

	get_tree().current_scene.call_deferred(
		"load_level",
		next_level_path,
		spawn_position_in_next_level,
		facing_direction_on_warp
	)
