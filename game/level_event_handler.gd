extends Node2D
class_name LevelEventHandler

@onready var player: CharacterBody2D = get_tree().get_first_node_in_group("player") as CharacterBody2D

func on_level_loaded() -> void:
	# override it yourself na
	pass

func handle_intro_for_level() -> void:
	# this one too na
	pass
