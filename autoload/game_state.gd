extends Node

var chap1_node1_shown := false
var chap1_node2_shown := false
var chap1_node3_shown := false
var chap1_node3_1_shown := false
var chap1_node3_2_shown := false
var chap1_node3_3_shown := false
var chap2_node4_shown := false
var chap2_node6_shown := false
var chap3_node7_shown := false
var chap3_node8_shown := false
var chap3_node9_shown := false
var chap4_node10_shown := false
var chap4_node11_shown := false
var chap4_tower_1st_floor_shown := false
var chap4_node11_ice_ghost_dead := false
var chap4_node12_shown := false

var clue_1_unlocked := false
var clue_2_unlocked := false
var clue_3_unlocked := false
var clue_4_unlocked := false

@export var save_id = "game_state"
@export var save_scope = "global"

func _ready() -> void:
	add_to_group("savable")

func new_game():
	chap1_node1_shown = false
	chap1_node2_shown = false
	chap1_node3_shown = false
	chap1_node3_1_shown = false
	chap1_node3_2_shown = false
	chap1_node3_3_shown = false
	chap2_node4_shown = false
	chap2_node6_shown = false
	chap3_node7_shown = false
	chap3_node8_shown = false
	chap3_node9_shown = false
	chap4_node10_shown = false
	chap4_node11_shown = false
	chap4_node11_ice_ghost_dead = false
	chap4_node12_shown = false

	clue_1_unlocked = false
	clue_2_unlocked = false
	clue_3_unlocked = false
	clue_4_unlocked = false

func save():
	return {
		"chap1_node1_shown": chap1_node1_shown,
		"chap1_node2_shown": chap1_node2_shown,
		"chap1_node3_shown": chap1_node3_shown,
		"chap1_node3_1_shown": chap1_node3_1_shown,
		"chap1_node3_2_shown": chap1_node3_2_shown,
		"chap1_node3_3_shown": chap1_node3_3_shown,
		"chap2_node4_shown": chap2_node4_shown,
		"chap2_node6_shown": chap2_node6_shown,
		"chap3_node7_shown": chap3_node7_shown,
		"chap3_node8_shown": chap3_node8_shown,
		"chap3_node9_shown": chap3_node9_shown,
		"chap4_node10_shown": chap4_node10_shown,
		"chap4_node11_shown": chap4_node11_shown,
		"chap4_node11_ice_ghost_dead": chap4_node11_ice_ghost_dead,
		"chap4_node12_shown": chap4_node12_shown,
		
		"clue_1_unlocked": clue_1_unlocked,
		"clue_2_unlocked": clue_2_unlocked,
		"clue_3_unlocked": clue_3_unlocked,
		"clue_4_unlocked": clue_4_unlocked
	}

func load_data(data):
	chap1_node1_shown = data.get("chap1_node1_shown", false)
	chap1_node2_shown = data.get("chap1_node2_shown", false)
	chap1_node3_shown = data.get("chap1_node3_shown", false)
	chap1_node3_1_shown = data.get("chap1_node3_1_shown", false)
	chap1_node3_2_shown = data.get("chap1_node3_2_shown", false)
	chap1_node3_3_shown = data.get("chap1_node3_3_shown", false)
	chap2_node4_shown = data.get("chap2_node4_shown", false)
	chap2_node6_shown = data.get("chap2_node6_shown", false)
	chap3_node7_shown = data.get("chap3_node7_shown", false)
	chap3_node8_shown = data.get("chap3_node8_shown", false)
	chap3_node9_shown = data.get("chap3_node9_shown", false)
	chap4_node10_shown = data.get("chap4_node10_shown", false)
	chap4_node11_shown = data.get("chap4_node11_shown", false)
	chap4_node11_ice_ghost_dead = data.get("chap4_node11_ice_ghost_dead", false)
	chap4_node12_shown = data.get("chap4_node12_shown", false)
	
	clue_1_unlocked = data.get("clue_1_unlocked", false)
	clue_2_unlocked = data.get("clue_2_unlocked", false)
	clue_3_unlocked = data.get("clue_3_unlocked", false)
	clue_4_unlocked = data.get("clue_4_unlocked", false)
