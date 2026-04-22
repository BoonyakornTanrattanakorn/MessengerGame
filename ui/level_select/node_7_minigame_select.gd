extends Control

var subnode_scene = "res://game/chapter_3/subnode/subnode_1_chap3.tscn"
var node_7_scene = "res://game/chapter_3/node_7/scenes/node_7.tscn"

func _ready():
	$CenterContainer/VBoxContainer/HBoxContainer/YesButton.pressed.connect(_subnode_start)
	$CenterContainer/VBoxContainer/HBoxContainer/NoButton.pressed.connect(_node_start)
	$BackToLevelSelectButton.pressed.connect(_level_select)
		
func _subnode_start():
	SaveManager.new_game_from_level(subnode_scene, Vector2(300, 425), Vector2.RIGHT)
	GameState.element_earth_unlocked = true
	GameState.element_water_unlocked = true

func _node_start():
	SaveManager.new_game_from_level(node_7_scene, Vector2(450, 1660), Vector2.RIGHT)
	GameState.element_earth_unlocked = true
	GameState.element_water_unlocked = true
	
func _level_select():
	get_tree().change_scene_to_file("res://ui/level_select/level_select.tscn")
