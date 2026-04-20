extends Node

# Session-only: set before change_scene_to_file("game_scene.tscn") to override the default starting level
var pending_level: String = ""
var pending_spawn: Vector2 = Vector2.ZERO
var pending_facing: Vector2 = Vector2.ZERO

# Gems accumulated across all minigames — used as shop currency
var minigame_gems: int = 0

# Where to return after leaving the market
var market_return_path: String = ""
var market_return_spawn: Vector2 = Vector2.ZERO
var market_return_facing: Vector2 = Vector2.LEFT

var chap1_node1_shown := false
var chap1_node1_knight_dead := false
var chap1_node2_shown := false
var chap1_node3_shown := false
var chap1_node3_1_shown := false
var chap1_node3_2_shown := false
var chap1_node3_3_shown := false
var chap2_node4_shown := false
var chap2_node6_shown := false
var chap3_node7_shown := false
var chap3_node9_shown := false
var chap4_node10_shown := false
var chap4_node11_shown := false
var chap4_node11_villager_talked_once := false
var chap4_node11_ice_ghost_dead := false
var chap4_node11_tower_master_returned := false
var chap4_node11_soldier := false
var chap4_tower_1st_floor_shown := false
var chap4_node12_shown := false

var clue_1_unlocked := false
var clue_2_unlocked := false
var clue_3_unlocked := false
var clue_4_unlocked := false

var element_wind_unlocked := true
var element_earth_unlocked := false
var element_water_unlocked := false
var element_fire_unlocked := false

# Chapter 3 Subnodes
var chap3_subnode1_shown := false
var chap3_subnode2_shown := false
var chap3_subnode3_shown := false
var chap3_subnode4_shown := false

# Chapter 3 Node 8
var chap3_node8_shown := false
var chap3_node8_1_shown := false
var chap3_node8_2_shown := false
var chap3_node8_3_shown := false

@export var save_id = "game_state"
@export var save_scope = "global"

func _ready() -> void:
	add_to_group("savable")

func new_game():
	minigame_gems = 0
	chap3_subnode1_shown = false
	chap3_subnode2_shown = false
	chap3_subnode3_shown = false
	chap3_subnode4_shown = false
	chap1_node1_shown = false
	chap1_node1_knight_dead = false
	chap1_node2_shown = false
	chap1_node3_shown = false
	chap1_node3_1_shown = false
	chap1_node3_2_shown = false
	chap1_node3_3_shown = false
	chap3_node8_shown = false
	chap3_node8_1_shown = false
	chap3_node8_2_shown = false
	chap3_node8_3_shown = false
	chap2_node4_shown = false
	chap2_node6_shown = false
	chap3_node7_shown = false
	chap3_node9_shown = false
	chap4_node10_shown = false
	chap4_node11_shown = false
	chap4_node11_villager_talked_once = false
	chap4_node11_ice_ghost_dead = false
	chap4_node11_tower_master_returned = false
	chap4_node11_soldier = false
	chap4_node12_shown = false
	

	clue_1_unlocked = false
	clue_2_unlocked = false
	clue_3_unlocked = false
	clue_4_unlocked = false

	element_wind_unlocked = true
	element_earth_unlocked = false
	element_water_unlocked = false
	element_fire_unlocked = false

func save():
	return {
		"minigame_gems": minigame_gems,
		"chap3_subnode1_shown": chap3_subnode1_shown,
		"chap3_subnode2_shown": chap3_subnode2_shown,
		"chap1_node1_shown": chap1_node1_shown,
		"chap1_node1_knight_dead": chap1_node1_knight_dead,
		"chap1_node2_shown": chap1_node2_shown,
		"chap1_node3_shown": chap1_node3_shown,
		"chap1_node3_1_shown": chap1_node3_1_shown,
		"chap1_node3_2_shown": chap1_node3_2_shown,
		"chap1_node3_3_shown": chap1_node3_3_shown,
		"chap3_node8_shown": chap3_node8_shown,
		"chap3_node8_1_shown": chap3_node8_1_shown,
		"chap3_node8_2_shown": chap3_node8_2_shown,
		"chap3_node8_3_shown": chap3_node8_3_shown,
		"chap2_node4_shown": chap2_node4_shown,
		"chap2_node6_shown": chap2_node6_shown,
		"chap3_node7_shown": chap3_node7_shown,
		"chap3_node9_shown": chap3_node9_shown,
		"chap4_node10_shown": chap4_node10_shown,
		"chap4_node11_shown": chap4_node11_shown,
		"chap4_node11_villager_talked_once": chap4_node11_villager_talked_once,
		"chap4_node11_ice_ghost_dead": chap4_node11_ice_ghost_dead,
		"chap4_node11_tower_master_returned": chap4_node11_tower_master_returned,
		"chap4_node11_soldier": chap4_node11_soldier,
		"chap4_node12_shown": chap4_node12_shown,
		
		"clue_1_unlocked": clue_1_unlocked,
		"clue_2_unlocked": clue_2_unlocked,
		"clue_3_unlocked": clue_3_unlocked,
		"clue_4_unlocked": clue_4_unlocked,
		"element_wind_unlocked": element_wind_unlocked,
		"element_earth_unlocked": element_earth_unlocked,
		"element_water_unlocked": element_water_unlocked,
		"element_fire_unlocked": element_fire_unlocked
	}

func load_data(data):
	minigame_gems = data.get("minigame_gems", 0)
	chap3_subnode1_shown = data.get("chap3_subnode1_shown", false)
	chap3_subnode2_shown = data.get("chap3_subnode2_shown", false)
	chap3_subnode3_shown = data.get("chap3_subnode3_shown", false)
	chap3_subnode4_shown = data.get("chap3_subnode4_shown", false)
	chap1_node1_shown = data.get("chap1_node1_shown", false)
	chap1_node1_knight_dead = data.get("chap1_node1_knight_dead", false)
	chap1_node2_shown = data.get("chap1_node2_shown", false)
	chap1_node3_shown = data.get("chap1_node3_shown", false)
	chap1_node3_1_shown = data.get("chap1_node3_1_shown", false)
	chap1_node3_2_shown = data.get("chap1_node3_2_shown", false)
	chap1_node3_3_shown = data.get("chap1_node3_3_shown", false)
	chap3_node8_shown = data.get("chap3_node8_shown", false)
	chap3_node8_1_shown = data.get("chap3_node8_1_shown", false)
	chap3_node8_2_shown = data.get("chap3_node8_2_shown", false)
	chap3_node8_3_shown = data.get("chap3_node8_3_shown", false)
	chap2_node4_shown = data.get("chap2_node4_shown", false)
	chap2_node6_shown = data.get("chap2_node6_shown", false)
	chap3_node7_shown = data.get("chap3_node7_shown", false)
	chap3_node9_shown = data.get("chap3_node9_shown", false)
	chap4_node10_shown = data.get("chap4_node10_shown", false)
	chap4_node11_shown = data.get("chap4_node11_shown", false)
	chap4_node11_villager_talked_once = data.get("chap4_node11_villager_talked_once", false)
	chap4_node11_ice_ghost_dead = data.get("chap4_node11_ice_ghost_dead", false)
	chap4_node11_tower_master_returned = data.get("chap4_node11_tower_master_returned", false)
	chap4_node11_soldier = data.get("chap4_node11_soldier", false)
	chap4_node12_shown = data.get("chap4_node12_shown", false)
	
	clue_1_unlocked = data.get("clue_1_unlocked", false)
	clue_2_unlocked = data.get("clue_2_unlocked", false)
	clue_3_unlocked = data.get("clue_3_unlocked", false)
	clue_4_unlocked = data.get("clue_4_unlocked", false)

	element_wind_unlocked = data.get("element_wind_unlocked", true)
	if data.has("element_earth_unlocked"):
		element_earth_unlocked = data.get("element_earth_unlocked", false)
	else:
		element_earth_unlocked = chap2_node6_shown or chap3_node7_shown or chap4_node10_shown

	if data.has("element_water_unlocked"):
		element_water_unlocked = data.get("element_water_unlocked", false)
	else:
		element_water_unlocked = chap3_node7_shown or chap4_node10_shown

	if data.has("element_fire_unlocked"):
		element_fire_unlocked = data.get("element_fire_unlocked", false)
	else:
		element_fire_unlocked = chap4_node10_shown
