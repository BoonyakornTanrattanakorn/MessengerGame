extends Warp

func _ready() -> void:
	super._ready()
	next_level_path = "res://game/chapter_4/node_12/node_12.tscn"
	spawn_position_in_next_level = Vector2(0, 0)
	facing_direction_on_warp = Vector2.UP
