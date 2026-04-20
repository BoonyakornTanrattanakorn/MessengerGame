extends Control

var minigame_scene = "res://game/minigame_ver2/Level/main2.tscn"
var node_8_scene = "res://game/chapter_3/node_8/level_0.tscn"

func _ready():
	$CenterContainer/VBoxContainer/HBoxContainer/YesButton.pressed.connect(_minigame_start)
	$CenterContainer/VBoxContainer/HBoxContainer/NoButton.pressed.connect(_node_start)
	$BackToLevelSelectButton.pressed.connect(_level_select)
		
func _minigame_start():
	SaveManager.save_game()
	get_tree().change_scene_to_file(minigame_scene)

func _node_start():
	get_tree().change_scene_to_file("res://ui/level_select/node_8_select.tscn")
	
func _level_select():
	get_tree().change_scene_to_file("res://ui/level_select/level_select.tscn")
