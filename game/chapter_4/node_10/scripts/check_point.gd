extends Area2D

@export var level_manager : LevelManager
@export var save_id = ""
@export var save_scope = "scene"
var is_reached = false

func _ready():
	add_to_group("savable")

	if save_id == "":
		save_id = get_parent().name + "/" + name
	body_entered.connect(_on_body_entered)


func _on_body_entered(body):
	if(!is_reached): 
		if body.is_in_group("player"):
			DialogueManager.show_dialogue_balloon(
				load("res://game/chapter_4/node_10/dialogue/node_10.dialogue"),
				"checkpoint"
			)
			is_reached = true
	
	level_manager.current_room = get_parent()
	level_manager.player_checkpoint_position = body.global_position

func save():
	return {
		"is_reached": is_reached
	}
	
func load_data(data):
	is_reached = data.get("is_reached", false)
	if is_reached == true:
			level_manager.current_room = get_parent()
