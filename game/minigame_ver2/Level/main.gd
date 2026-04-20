extends Node2D

@onready var player = $Player
@onready var hud = $HUD
@onready var game_over_screen = $GameOver
@onready var endpoint = $endpoint

func _ready():
	await get_tree().process_frame
	BGMManager.play_bgm("camel", 0.0, true)
	hud.show_charge_ui(false)
	hud.set_max_health(player.health)
	hud.update_health(player.health)
	hud.set_label_color(Color.BLACK)
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
	GameState.minigame_gems += hud.gems
	GameState.pending_level = "res://game/chapter_3/node_7/scenes/node_7.tscn"
	GameState.pending_spawn = Vector2(450, 1660)
	GameState.pending_facing = Vector2.LEFT
	get_tree().change_scene_to_file("res://game/game_scene.tscn")
