extends Control

var level_0_scene = "res://game/chapter_3/node_8/level_0.tscn"
var level_1_scene = "res://game/chapter_3/node_8/level_1.tscn"
var level_2_scene = "res://game/chapter_3/node_8/level_2.tscn"
var level_3_scene = "res://game/chapter_3/node_8/level_3.tscn"

func _ready():
	$CenterContainer/HBoxContainer/VBoxContainer/Level0Button.pressed.connect(_level_0_start)
	$CenterContainer/HBoxContainer/VBoxContainer/Level1Button.pressed.connect(_level_1_start)
	$CenterContainer/HBoxContainer/VBoxContainer/Level2Button.pressed.connect(_level_2_start)
	$CenterContainer/HBoxContainer/VBoxContainer/Level3Button.pressed.connect(_level_3_start)
	$BackToLevelSelectButton.pressed.connect(_level_select)
		
func _level_0_start():
	SaveManager.new_game_from_level(level_0_scene, Vector2(75, 725), Vector2.RIGHT)

func _level_1_start():
	SaveManager.new_game_from_level(level_1_scene, Vector2(100, 500), Vector2.DOWN)

func _level_2_start():
	SaveManager.new_game_from_level(level_2_scene, Vector2(100, 500), Vector2.DOWN)

func _level_3_start():
	SaveManager.new_game_from_level(level_3_scene, Vector2(100, 500), Vector2.DOWN)
	
func _level_select():
	get_tree().change_scene_to_file("res://ui/level_select/level_select.tscn")
