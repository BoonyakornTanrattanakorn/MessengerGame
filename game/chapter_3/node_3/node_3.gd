# BossMap.gd
extends Node2D

@onready var tile_manager = $TileManager
@onready var boss_display = $BossDisplay

func on_level_loaded() -> void:
	pass

func handle_intro_for_level() -> void:
	pass

func _ready():
	tile_manager.phase_complete.connect(_on_phase_complete)
	tile_manager.boss_defeated.connect(_on_boss_defeated)

func _on_phase_complete(phase: int):
	boss_display.show_phase(phase + 1)

func _on_boss_defeated():
	boss_display.play_defeat()
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://game/minigame_ver2/Level/main3.tscn")
