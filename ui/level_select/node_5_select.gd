extends Control

var village_scene = "res://game/chapter_2/node_4/chapter_2_village.tscn"
var node_5_scene = "res://game/chapter_2/node_4/lower_node/chapter2_node5.tscn"

func _ready():
	$CenterContainer/VBoxContainer/HBoxContainer/YesButton.pressed.connect(_village_start)
	$CenterContainer/VBoxContainer/HBoxContainer/NoButton.pressed.connect(_node_start)
	$BackToLevelSelectButton.pressed.connect(_level_select)
		
func _village_start():
	SaveManager.new_game_from_level(village_scene, Vector2(0, 100), Vector2.RIGHT)

func _node_start():
	SaveManager.new_game_from_level(node_5_scene, Vector2(350, 1275), Vector2.DOWN)
	
func _level_select():
	get_tree().change_scene_to_file("res://ui/level_select/level_select.tscn")
"res://game/chapter_3/node_7/scenes/node_7.tscn"
