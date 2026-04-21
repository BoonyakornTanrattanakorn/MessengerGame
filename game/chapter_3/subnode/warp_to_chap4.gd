extends Warp

func _ready() -> void:
	super._ready()
	next_level_path = "res://game/chapter_4/node_10/node_10.tscn"
	spawn_position_in_next_level = Vector2(400, 670)
	facing_direction_on_warp = Vector2.DOWN
