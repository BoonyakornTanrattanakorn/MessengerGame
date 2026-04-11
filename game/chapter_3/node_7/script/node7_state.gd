extends Node

const TOTAL_STATUES := 5

var collected_statues: Array[String] = []
var riddle_solved := false
var intro_objective_started := false
var save_scope := "global"
var save_id := "node_desert_state"

func _ready() -> void:
	add_to_group("savable")

func start_desert_objective() -> void:
	if intro_objective_started:
		return
	intro_objective_started = true
	update_objective()

func collect_statue(statue_id: String) -> void:
	if statue_id not in collected_statues:
		collected_statues.append(statue_id)
	update_objective()

func solve_riddle() -> void:
	if not has_all_statues():
		return
	riddle_solved = true
	update_objective()

func has_all_statues() -> bool:
	return collected_statues.size() >= TOTAL_STATUES

func get_statue_count() -> int:
	return collected_statues.size()

func update_objective() -> void:
	if riddle_solved:
		ObjectiveManager.set_objective("Head to the city")
	elif has_all_statues():
		ObjectiveManager.set_objective("Solve the riddle of the five statues")
	else:
		ObjectiveManager.set_objective("Find the missing statues (%d/5)" % get_statue_count())

func reset_desert_state() -> void:
	collected_statues.clear()
	riddle_solved = false
	intro_objective_started = false

func save():
	return {
		"collected_statues": collected_statues.duplicate(),
		"riddle_solved": riddle_solved,
		"intro_objective_started": intro_objective_started
	}

func load_data(data) -> void:
	if data.has("collected_statues"):
		collected_statues.clear()
		for statue in data.collected_statues:
			collected_statues.append(str(statue))
	riddle_solved = data.get("riddle_solved", false)
	intro_objective_started = data.get("intro_objective_started", false)
