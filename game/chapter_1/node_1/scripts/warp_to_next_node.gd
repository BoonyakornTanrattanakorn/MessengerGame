extends Area2D

@export var next_level_path: String = "res://game/chapter_1/node_2/scenes/Node_2.tscn"
@export var spawn_position_in_next_level: Vector2 = Vector2(2250, 3975)
@export var facing_direction_on_warp: Vector2 = Vector2.DOWN

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return

	get_tree().current_scene.call_deferred(
		"load_level",
		next_level_path,
		spawn_position_in_next_level,
		facing_direction_on_warp
	)
