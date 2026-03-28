extends Node

const TOTAL_FRAGMENTS := 4
const CORRECT_ORDER := ["rose", "helmet", "sword", "book"]

var found_fragments: Array[String] = []
var puzzle_solved: bool = false

var save_id := "puzzle_state"
var save_scope := "global"

func _ready() -> void:
	add_to_group("savable")

func collect_fragment(fragment_id: String) -> void:
	print("Found: ", fragment_id)
	if fragment_id not in found_fragments:
		found_fragments.append(fragment_id)

func has_all_fragments() -> bool:
	return found_fragments.size() >= TOTAL_FRAGMENTS

func check_answer(answer: Array[String]) -> bool:
	return answer == CORRECT_ORDER

func reset_puzzle() -> void:
	found_fragments.clear()
	puzzle_solved = false

func save():
	return {
		"found_fragments": found_fragments.duplicate(),
		"puzzle_solved": puzzle_solved
	}

func load_data(data: Dictionary) -> void:
	found_fragments = []
	for f in data.get("found_fragments", []):
		found_fragments.append(str(f))
	puzzle_solved = data.get("puzzle_solved", false)
