extends Node2D

@onready var player = $Player
@onready var hud = $HUD
@onready var game_over_screen = $GameOver
@onready var blast_skill = $BlastSkill

func _ready():
	await get_tree().process_frame
	BGMManager.play_bgm("res://assets/audio/hustle-and-bustle-of-ormos-2-rvikm.ogg", 0.0, true)

	hud.set_max_health(player.health)
	hud.update_health(player.health)
	hud.show_charge_ui(true)
	hud.set_label_color(Color.WHITE)
	hud.update_charges(3)
	
	blast_skill.enable()
	
	player.health_changed.connect(hud.update_health)
	player.gem_collected.connect(hud.update_gems)
	player.player_died.connect(_on_player_died)
	game_over_screen.retry_pressed.connect(_on_retry)
	blast_skill.charge_changed.connect(hud.update_charges)
	
	# Connect recharge items
	for item in get_tree().get_nodes_in_group("recharge"):
		item.picked_up.connect(_on_recharge_picked_up)
	
	# Connect endpoint
	var endpoint = get_tree().get_first_node_in_group("endpoint")
	if endpoint:
		endpoint.level_completed.connect(_on_level_completed)
		print("endpoint connected!")
	else:
		push_error("endpoint not found — make sure it is in 'endpoint' group")

func _on_player_died():
	blast_skill.disable()
	game_over_screen.show_game_over()

func _on_retry():
	get_tree().reload_current_scene()

func _on_recharge_picked_up():
	blast_skill.add_charge(1)

func _on_level_completed():
	print("_on_level_completed called")  # ← does this print?
	player.stop()
	blast_skill.disable()
	_handle_completion()

func _handle_completion():
	GameState.minigame_gems += hud.gems
	GameState.pending_level = "res://game/chapter_3/node_9/node_9.tscn"
	GameState.pending_spawn = Vector2(50, 350)
	GameState.pending_facing = Vector2.DOWN
	get_tree().change_scene_to_file("res://game/game_scene.tscn")
