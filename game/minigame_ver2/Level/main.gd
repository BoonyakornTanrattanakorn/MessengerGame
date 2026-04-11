extends Node2D

@onready var player = $Player
@onready var hud = $HUD
@onready var game_over_screen = $GameOver  # instance game_over.tscn here

func _ready():
	await get_tree().process_frame
	
	hud.set_max_health(player.health)
	hud.update_health(player.health)
	
	player.health_changed.connect(hud.update_health)
	player.gem_collected.connect(hud.update_gems)
	player.player_died.connect(_on_player_died)
	game_over_screen.retry_pressed.connect(_on_retry)

func _on_player_died():
	game_over_screen.show_game_over()

func _on_retry():
	get_tree().reload_current_scene()  # restart the whole scene from beginning
