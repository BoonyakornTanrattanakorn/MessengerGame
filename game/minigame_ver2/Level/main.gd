extends Node2D

@onready var player = $Player
@onready var hud = $HUD
@onready var game_over_screen = $GameOver
@onready var endpoint = $endpoint

func _ready():
	await get_tree().process_frame
	hud.show_charge_ui(false)
	hud.set_max_health(player.health)
	hud.update_health(player.health)
	
	player.health_changed.connect(hud.update_health)
	player.gem_collected.connect(hud.update_gems)
	player.player_died.connect(_on_player_died)
	game_over_screen.retry_pressed.connect(_on_retry)
	endpoint.level_completed.connect(_on_level_completed)

func _on_player_died():
	game_over_screen.show_game_over()

func _on_retry():
	get_tree().reload_current_scene()

func _on_level_completed():
	player.set_physics_process(false)
	# ↓ Everything below here is a placeholder — replace when ready
	_handle_completion()

func _handle_completion():
	# TODO: replace this whole function later with whatever you need
	# Options you might want later:
	# get_tree().change_scene_to_file("res://game/results_screen.tscn")
	# GlobalData.save_score(hud.gems)
	# emit_signal to parent game if this is a minigame
	# show a win popup
	print("Level complete! Gems collected: ", hud.gems)
