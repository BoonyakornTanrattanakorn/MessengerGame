extends Warp

var dialogue = load("res://game/chapter_1/node_1/dialogue/royal_knight.dialogue")

func _ready() -> void:
	super._ready()
	next_level_path = "res://game/chapter_1/node_2/scenes/Node_2.tscn"
	spawn_position_in_next_level = Vector2(2250, 3975)
	facing_direction_on_warp = Vector2.DOWN

func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return
		
	if not GameState.chap1_node1_knight_dead:
		DialogueManager.show_dialogue_balloon(dialogue, "not_talked")
		await DialogueManager.dialogue_ended
	else:
		super._on_body_entered(body)
	
