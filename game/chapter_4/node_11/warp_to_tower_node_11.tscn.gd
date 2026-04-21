extends Warp

var dialogue = load("res://game/chapter_4/node_11/dialogue/node_11_dialogue.dialogue")
var tag = "tower_stop"

func _ready() -> void:
	super._ready()
	next_level_path = "res://game/chapter_4/node_11/tower_1st_flr.tscn"
	spawn_position_in_next_level = Vector2(385,107)
	facing_direction_on_warp = Vector2.DOWN

func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return
		
	if not GameState.chap4_node11_villager_talked_once:
		DialogueManager.show_dialogue_balloon(dialogue, tag)
		await DialogueManager.dialogue_ended
	else:
		super._on_body_entered(body)
	
