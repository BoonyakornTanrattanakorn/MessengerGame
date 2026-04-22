extends LevelEventHandler

var dialogue = load("res://game/chapter_2/node_6/dialogue/chap2_node3.dialogue")
@export var town: Node2D

func _ready() -> void:
	_set_player_boat_mode(true)
	await get_tree().process_frame
	player.health_component.player_dead.connect(_on_player_dead)
	if DeadManager != null and not DeadManager.player_respawned.is_connected(_on_player_respawned):
		DeadManager.player_respawned.connect(_on_player_respawned)

func _exit_tree() -> void:
	_set_player_boat_mode(false)


func _set_player_boat_mode(enabled: bool) -> void:
	var target_player := player
	if target_player == null:
		target_player = get_tree().get_first_node_in_group("player") as CharacterBody2D

	if target_player != null and target_player.has_method("set_boat_mode"):
		target_player.set_boat_mode(enabled)

func handle_intro_for_level() -> void:
	if not GameState.chap2_node6_shown:
		BGMManager.play_bgm("chapter2", 0.0, true)
		
		GameState.chap2_node6_shown = true

		DialogueManager.show_dialogue_balloon(
			dialogue,
            "start"
		)

		await DialogueManager.dialogue_ended

		player.focus_camera_to(town)
		await get_tree().create_timer(1.0).timeout
		
		player.return_camera()
		
		DialogueManager.show_dialogue_balloon(
			dialogue,
            "start_2"
		)
		
		await DialogueManager.dialogue_ended
		ObjectiveManager.set_objective("Continue to the desert")
		SaveManager.save_game()

func _on_player_dead():
	DeadManager.kill_player("Shot down by water ball", "Try using wind and earth element alternately.", Vector2(1300,0))


func _on_player_respawned(_position: Vector2) -> void:
	call_deferred("_reset_after_respawn")


func _reset_after_respawn() -> void:
	# GameState.chap2_node6_shown = false
	ObjectiveManager.set_objective("Continue to the desert")

	var boss_fight_zone := get_tree().current_scene.find_child("BossFightZone", true, false)
	if boss_fight_zone != null and boss_fight_zone.has_method("reset_encounter_after_respawn"):
		boss_fight_zone.reset_encounter_after_respawn()
