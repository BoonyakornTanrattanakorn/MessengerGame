extends LevelEventHandler

var dialogue := load("res://game/chapter_4/node_11/dialogue/ice_ghost.dialogue")

@export var ice_ghost: Node2D

func _ready() -> void:
	player.health_component.player_dead.connect(_on_player_dead)

func handle_intro_for_level() -> void:
	if not GameState.chap4_tower_1st_floor_shown:
		GameState.chap4_tower_1st_floor_shown = true

		player.focus_camera_to(ice_ghost)
		if dialogue != null:
			DialogueManager.show_dialogue_balloon(dialogue, "start")
			await DialogueManager.dialogue_ended
		player.return_camera()
		
func _on_player_dead() -> void:
	DeadManager.kill_player("Defeated by the ice ghost", "Use fire power. Period.", Vector2(260, 130))
