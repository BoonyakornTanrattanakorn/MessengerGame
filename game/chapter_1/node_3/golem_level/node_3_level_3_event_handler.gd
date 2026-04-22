extends LevelEventHandler

@onready var bridge_manager = $BridgeManager

@export var golem_boss: Node2D
@onready var portal = $Portal

func _ready():
	player.health_component.player_dead.connect(_on_player_dead)
	if DeadManager != null and not DeadManager.player_respawned.is_connected(_on_player_respawned):
		DeadManager.player_respawned.connect(_on_player_respawned)
	for node in get_all_children(self):
		# Only connect nodes that have switch_activated signal
		if node.has_method("activate") and node.has_signal("switch_activated"):
			node.switch_activated.connect(bridge_manager.activate_color)

	if golem_boss and golem_boss.has_signal("boss_defeated"):
		golem_boss.boss_defeated.connect(_on_golem_boss_defeated)

	if portal and portal.has_method("hide_portal"):
		portal.hide_portal()

	if golem_boss and golem_boss.has_method("is_defeated") and golem_boss.is_defeated():
		_on_golem_boss_defeated()

func get_all_children(node: Node) -> Array:
	var result = []
	for child in node.get_children():
		result.append(child)
		result.append_array(get_all_children(child))
	return result

func _on_player_dead() -> void:
	DeadManager.kill_player("Defeated by the tormented flame of Golem Guardian", "Color of the golems seems to resemble the switches...", Vector2(900, 600))


func _on_player_respawned(_position: Vector2) -> void:
	if player == null:
		return

	if player.inventory.get("blue_gem", 0) > 0:
		player.inventory.erase("blue_gem")
		if player.hud != null:
			player.hud.refresh_items()

func handle_intro_for_level() -> void:
	Node3State.update_objective()
	if not GameState.chap1_node3_3_shown:
		BGMManager.play_bgm("dungeon", -5.0, true)
		GameState.chap1_node3_3_shown = true

		DialogueManager.show_dialogue_balloon(
			load("res://game/chapter_1/node_3/dialogue/chap1_node3_3.dialogue"),
            "start"
		)

		await DialogueManager.dialogue_ended

		player.focus_camera_to(golem_boss)

		await get_tree().create_timer(1.0).timeout
		player.return_camera()
		SaveManager.save_game()

func _on_golem_boss_defeated() -> void:
	if portal and portal.has_method("show_portal"):
		portal.show_portal()
		SaveManager.save_game()
