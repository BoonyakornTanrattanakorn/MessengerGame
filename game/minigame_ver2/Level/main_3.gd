extends Node2D

@onready var player = $Player
@onready var hud = $HUD
@onready var game_over_screen = $GameOver
@onready var blast_skill = $BlastSkill

@onready var flying_organ = $Player/GameCamera/FlyingOrgan 

func _ready():
	await get_tree().process_frame
	
	hud.set_max_health(player.health)
	hud.update_health(player.health)
	
	# main3 specific — hide gem, show shard and charge
	hud.show_gem_ui(false)
	hud.show_shard_ui(true)
	hud.show_charge_ui(true)
	hud.update_charges(3)
	hud.update_shards(0)
	hud.set_label_color(Color.WHITE)
	
	# Enable blast skill same as main2
	blast_skill.enable()
	
	# Connect signals
	player.health_changed.connect(hud.update_health)
	player.shard_changed.connect(hud.update_shards)  # ← shard signal
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
	else:
		push_error("endpoint not found!")

	flying_organ.organ_destroyed.connect(_on_organ_destroyed)

func _on_player_died():
	blast_skill.disable()
	game_over_screen.show_game_over()

func _on_retry():
	get_tree().reload_current_scene()

func _on_recharge_picked_up():
	blast_skill.add_charge(1)

func _on_level_completed():
	player.stop()
	blast_skill.disable()
	_handle_completion()

func _handle_completion():
	pass

func _on_organ_destroyed():
	print("organ destroyed — level complete!")
	player.stop()
	blast_skill.disable()
	_handle_completion()
