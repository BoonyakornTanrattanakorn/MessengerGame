# BossMap.gd
extends Node2D

@onready var tile_manager = $TileManager
@onready var boss_display = $BossDisplay
@onready var rock_fall_manager = $RockFallManager

func on_level_loaded() -> void:
	pass

func handle_intro_for_level() -> void:
	pass

func _ready():
	tile_manager.phase_complete.connect(_on_phase_complete)
	tile_manager.boss_defeated.connect(_on_boss_defeated)
	rock_fall_manager.start(1)

func _on_phase_complete(phase: int):
	boss_display.play_hit()
	await get_tree().create_timer(0.9).timeout
	var next_phase = phase + 1
	boss_display.show_phase(next_phase)
	rock_fall_manager.start(next_phase)


func _on_boss_defeated():
	boss_display.play_hit()
	rock_fall_manager.stop()              # ← stop rocks on defeat
	await get_tree().create_timer(0.9).timeout
	boss_display.play_defeat()

	get_tree().change_scene_to_file("res://game/minigame_ver2/Level/main3.tscn")
