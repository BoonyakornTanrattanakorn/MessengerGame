extends Warp

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	next_level_path = "res://game/chapter_3/node_8/level_2.tscn"
	spawn_position_in_next_level = Vector2(100, 500)
	facing_direction_on_warp = Vector2.DOWN
