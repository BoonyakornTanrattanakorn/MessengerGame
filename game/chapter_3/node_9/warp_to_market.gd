extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return
	GameState.market_return_path = "res://game/chapter_3/node_9/node_9.tscn"
	GameState.market_return_spawn = Vector2(0, 100)
	GameState.market_return_facing = Vector2.DOWN
	SaveManager.save_game()
	get_tree().current_scene.call_deferred(
		"load_level",
		"res://game/chapter_3/node_7_market/scenes/node7_market.tscn",
		Vector2(-200, 666),
		Vector2.RIGHT
	)
