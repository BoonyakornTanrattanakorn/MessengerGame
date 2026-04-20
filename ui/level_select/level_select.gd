extends Control

var node_1_scene = "res://game/chapter_1/node_1/scenes/chapter1_node1.tscn"
var node_2_scene = "res://game/chapter_1/node_2/scenes/node_2.tscn"
var node_6_scene = "res://game/chapter_2/node_6/scenes/chapter2_node3.tscn"
var node_9_scene = "res://game/chapter_3/node_9/node_9.tscn"
var node_10_scene = "res://game/chapter_4/node_10/node_10.tscn"
var node_11_scene = "res://game/chapter_4/node_11/node_11.tscn"
var node_12_scene = "res://game/chapter_4/node_12/node_12.tscn"

func _ready():
	$CenterContainer/HBoxContainer/Chapter1Container/Node1Button.pressed.connect(_node_1_start)
	$CenterContainer/HBoxContainer/Chapter1Container/Node2Button.pressed.connect(_node_2_start)
	$CenterContainer/HBoxContainer/Chapter1Container/Node3Button.pressed.connect(_node_3_start)
	$CenterContainer/HBoxContainer/Chapter2Container/Node4Button.pressed.connect(_node_4_start)
	$CenterContainer/HBoxContainer/Chapter2Container/Node5Button.pressed.connect(_node_5_start)
	$CenterContainer/HBoxContainer/Chapter2Container/Node6Button.pressed.connect(_node_6_start)
	$CenterContainer/HBoxContainer/Chapter3Container/Node7Button.pressed.connect(_node_7_start)
	$CenterContainer/HBoxContainer/Chapter3Container/Node8Button.pressed.connect(_node_8_start)
	$CenterContainer/HBoxContainer/Chapter3Container/Node9Button.pressed.connect(_node_9_start)
	$CenterContainer/HBoxContainer/Chapter4Container/Node10Button.pressed.connect(_node_10_start)
	$CenterContainer/HBoxContainer/Chapter4Container/Node11Button.pressed.connect(_node_11_start)
	$CenterContainer/HBoxContainer/Chapter4Container/Node12Button.pressed.connect(_node_12_start)
	$BackToMenuButton.pressed.connect(_back_to_menu)
		
func _node_1_start():
	SaveManager.new_game_from_level(node_1_scene, Vector2(0,0), Vector2.DOWN)

func _node_2_start():
	SaveManager.new_game_from_level(node_2_scene, Vector2(2250, 3975), Vector2.DOWN)

func _node_3_start():
	get_tree().change_scene_to_file("res://ui/level_select/node_3_select.tscn")

func _node_4_start():
	get_tree().change_scene_to_file("res://ui/level_select/node_4_select.tscn")

func _node_5_start():
	get_tree().change_scene_to_file("res://ui/level_select/node_5_select.tscn")

func _node_6_start():
	SaveManager.new_game_from_level(node_6_scene, Vector2(0, 0), Vector2.RIGHT)

func _node_7_start():
	get_tree().change_scene_to_file("res://ui/level_select/node_7_minigame_select.tscn")

func _node_8_start():
	get_tree().change_scene_to_file("res://ui/level_select/node_8_minigame_select.tscn")

func _node_9_start():
	SaveManager.new_game_from_level(node_9_scene, Vector2(50, 350), Vector2.DOWN)

func _node_10_start():
	SaveManager.new_game_from_level(node_10_scene, Vector2(400, 670), Vector2.UP)

func _node_11_start():
	SaveManager.new_game_from_level(node_11_scene, Vector2(-330, 350), Vector2.RIGHT)

func _node_12_start():
	SaveManager.new_game_from_level(node_12_scene, Vector2(0,0), Vector2.UP)
	
func _back_to_menu():
	get_tree().change_scene_to_file("res://ui/menu/main_menu.tscn")
