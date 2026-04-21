extends Warp

func _ready() -> void:
	super._ready()
	next_level_path = "res://game/chapter_4/node_11/tower_1st_flr.tscn"
	spawn_position_in_next_level = Vector2(360,407)
	facing_direction_on_warp = Vector2.UP

func _on_body_entered(body: Node) -> void:
	super._on_body_entered(body)
	
