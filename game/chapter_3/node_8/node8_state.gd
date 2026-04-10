extends Node

var puzzle_1_completed := false
var puzzle_2_completed := false
var puzzle_3_completed := false

var save_scope := "global"
var save_id := "chap3_node8_state"

func _ready() -> void:
	add_to_group("savable")

func complete_puzzle(puzzle_id: int) -> void:
	match puzzle_id:
		1: puzzle_1_completed = true
		2: puzzle_2_completed = true
		3: puzzle_3_completed = true
	update_objective()

func all_puzzles_done() -> bool:
	return puzzle_1_completed and puzzle_2_completed and puzzle_3_completed

func get_completed_count() -> int:
	var count := 0
	if puzzle_1_completed: count += 1
	if puzzle_2_completed: count += 1
	if puzzle_3_completed: count += 1
	return count

func update_objective() -> void:
	if all_puzzles_done():
		ObjectiveManager.set_objective("Get out of pyramid")
	else:
		ObjectiveManager.set_objective("Solve pyramid puzzles (%d/3)" % get_completed_count())

func reset() -> void:
	puzzle_1_completed = false
	puzzle_2_completed = false
	puzzle_3_completed = false

func save():
	return {
		"puzzle_1_completed": puzzle_1_completed,
		"puzzle_2_completed": puzzle_2_completed,
		"puzzle_3_completed": puzzle_3_completed,
	}

func load_data(data) -> void:
	puzzle_1_completed = data.get("puzzle_1_completed", false)
	puzzle_2_completed = data.get("puzzle_2_completed", false)
	puzzle_3_completed = data.get("puzzle_3_completed", false)
