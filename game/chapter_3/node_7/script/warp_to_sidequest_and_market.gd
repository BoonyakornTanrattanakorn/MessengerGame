extends Warp

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if Node7State.sandmonster_quest_turned_in:
		next_level_path = "res://game/chapter_3/node_7_market/scenes/node7_market.tscn"
		spawn_position_in_next_level = Vector2(-200, 666)
		facing_direction_on_warp = Vector2.RIGHT
	else:
		next_level_path = "res://game/chapter_3/node_7_sidequest/scenes/node7_sidequest.tscn"
		spawn_position_in_next_level = Vector2(-320, 610)
		facing_direction_on_warp = Vector2.RIGHT

	super._on_body_entered(body)
