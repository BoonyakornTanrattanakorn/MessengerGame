extends Warp

func _ready() -> void:
	super._ready()
	next_level_path = "res://game/chapter_4/node_11/node_11.tscn"
	spawn_position_in_next_level = Vector2(-330, 350)
	facing_direction_on_warp = Vector2.RIGHT

func _on_body_entered(body: Node) -> void:
	super._on_body_entered(body)
	get_player().earth_greater_locked = false

func get_player() -> Player: 
	return get_tree().get_first_node_in_group("player")
