extends Node

# TODO: remove these
var chap1_node2_shown := false
var chap1_node3_shown := false
var chap1_node3_1_shown := false
var chap1_node3_2_shown := false
var chap1_node3_3_shown := false

@export var save_id = "game_state"
@export var save_scope = "global"

func _ready() -> void:
	add_to_group("savable")

func new_game():
	chap1_node2_shown = false
	chap1_node3_shown = false
	chap1_node3_1_shown = false
	chap1_node3_2_shown = false
	chap1_node3_3_shown = false

func save():
	return {
		"chap1_node2_shown": chap1_node2_shown,
		"chap1_node3_shown": chap1_node3_shown,
		"chap1_node3_1_shown": chap1_node3_1_shown,
		"chap1_node3_2_shown": chap1_node3_2_shown,
		"chap1_node3_3_shown": chap1_node3_3_shown
	}

func load_data(data):
	chap1_node2_shown = data.get("chap1_node2_shown", false)
	chap1_node3_shown = data.get("chap1_node3_shown", false)
	chap1_node3_1_shown = data.get("chap1_node3_1_shown", false)
	chap1_node3_2_shown = data.get("chap1_node3_2_shown", false)
	chap1_node3_3_shown = data.get("chap1_node3_3_shown", false)
