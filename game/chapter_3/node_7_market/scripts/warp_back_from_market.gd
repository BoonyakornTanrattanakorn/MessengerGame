extends Warp

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return
	if GameState.market_return_path == "":
		# fallback: return to node_7
		next_level_path = "res://game/chapter_3/node_7/scenes/node_7.tscn"
		spawn_position_in_next_level = Vector2(5000, 1741)
		facing_direction_on_warp = Vector2.LEFT
	else:
		next_level_path = GameState.market_return_path
		spawn_position_in_next_level = GameState.market_return_spawn
		facing_direction_on_warp = GameState.market_return_facing
		GameState.market_return_path = ""
	super._on_body_entered(body)
