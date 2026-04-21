extends Warp

func _ready() -> void:
	super._ready()
	next_level_path = "res://game/chapter_4/node_11/node_11.tscn"
	spawn_position_in_next_level = Vector2(-330, 350)
	facing_direction_on_warp = Vector2.RIGHT
