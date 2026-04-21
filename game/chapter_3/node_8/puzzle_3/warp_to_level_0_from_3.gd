extends Warp

func _ready() -> void:
	super._ready()
	next_level_path = "res://game/chapter_3/node_8/level_0.tscn"
	spawn_position_in_next_level = Vector2(1225, 700)
	facing_direction_on_warp = Vector2.UP

func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return
	if not visible:
		return
	get_tree().current_scene.call_deferred("load_level", next_level_path, spawn_position_in_next_level, facing_direction_on_warp)
