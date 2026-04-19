extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return
	SaveManager.save_game()
	GameState.pending_level = "res://game/chapter_3/node_9/node_9.tscn"
	GameState.pending_spawn = Vector2(50, 350)
	GameState.pending_facing = Vector2.DOWN
	get_tree().change_scene_to_file("res://game/game_scene.tscn")
