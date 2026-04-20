extends Warp

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	next_level_path = "res://game/chapter_1/node_3/level_0.tscn"
	spawn_position_in_next_level = Vector2(100, 575)
	facing_direction_on_warp = Vector2.DOWN
