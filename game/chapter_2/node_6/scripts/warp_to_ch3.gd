extends Warp

func _ready() -> void:
	super._ready()
	next_level_path = "res://game/chapter_3/subnode/subnode_1_chap3.tscn"
	spawn_position_in_next_level = Vector2(300, 425)
	facing_direction_on_warp = Vector2.RIGHT
