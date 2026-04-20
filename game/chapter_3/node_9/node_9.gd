# BossMap.gd
extends LevelEventHandler

@onready var tile_manager = $TileManager
@onready var boss_display = $BossDisplay
@onready var rock_fall_manager = $RockFallManager
var is_boss_dead = false

func update_objective() -> void:
	if is_boss_dead:
		ObjectiveManager.set_objective("Head to the next city")
	else:
		ObjectiveManager.set_objective("Defeat the boss")

func on_level_loaded() -> void:
	pass

func handle_intro_for_level() -> void:
	BGMManager.play_bgm("caravan", 0.0, true)

func _ready():
	is_boss_dead = false
	update_objective()
	tile_manager.phase_complete.connect(_on_phase_complete)
	tile_manager.boss_defeated.connect(_on_boss_defeated)
	rock_fall_manager.start(1)
	player.health_component.player_dead.connect(_on_player_dead)

func _on_phase_complete(phase: int):
	boss_display.play_hit()
	await get_tree().create_timer(0.9).timeout
	var next_phase = phase + 1
	boss_display.show_phase(next_phase)
	rock_fall_manager.start(next_phase)

func _on_player_dead() -> void:
	DeadManager.kill_player("Defeated by the Worm Guardian", "", Vector2(100, 500))

func _on_boss_defeated():
	is_boss_dead = true
	boss_display.play_hit()
	rock_fall_manager.stop()              # ← stop rocks on defeat
	await get_tree().create_timer(0.9).timeout
	boss_display.play_defeat()
	update_objective()
	
	GameState.pending_level = "res://game/chapter_3/subnode/subnode_3_chap3.tscn"
	GameState.pending_spawn = Vector2(606, 671)
	GameState.pending_facing = Vector2.RIGHT
	get_tree().change_scene_to_file("res://game/game_scene.tscn")
