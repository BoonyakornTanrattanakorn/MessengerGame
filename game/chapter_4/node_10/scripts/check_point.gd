extends Area2D

@export var level_manager : LevelManager
var is_reached = false

func _ready():
	body_entered.connect(_on_body_entered)


func _on_body_entered(body):
	if(!is_reached): 
		if body.is_in_group("player"):
			DialogueManager.show_dialogue_balloon(
				load("res://game/chapter_4/node_10/dialogue/node_10.dialogue"),
				"checkpoint"
			)
			level_manager.current_room = get_parent()
			level_manager.player_checkpoint_position = body.global_position
			is_reached = true
