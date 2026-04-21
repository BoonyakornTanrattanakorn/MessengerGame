extends Warp

func _ready() -> void:
	super._ready()
	next_level_path = "res://game/chapter_4/node_11/tower_2nd_flr.tscn"
	spawn_position_in_next_level = Vector2(286,159)
	facing_direction_on_warp = Vector2.DOWN

func _on_body_entered(body: Node) -> void:
	if not GameState.chap4_node11_ice_ghost_dead:
		return
	super._on_body_entered(body)
	
