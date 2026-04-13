extends Node

const TOTAL_STATUES := 5
var collected_statues: Array[String] = []
var riddle_solved := false
var intro_objective_started := false
var talked_to_governor := false
var city_exploration_started := false
var sandmonster_quest_accepted := false
var sandmonster_quest_complete := false
var save_scope := "global"
var save_id := "node7_state"

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

func enter_city() -> void:
	if city_exploration_started:
		return
	update_objective()

func talk_to_governor() -> void:
	talked_to_governor = true
	city_exploration_started = true
	update_objective()

func complete_sandmonster_quest() -> void:
	sandmonster_quest_complete = true

func has_all_statues() -> bool:
	return collected_statues.size() >= TOTAL_STATUES

func get_statue_count() -> int:
	return collected_statues.size()

func update_objective() -> void:
	if city_exploration_started:
		ObjectiveManager.set_objective("Explore the city")
	elif riddle_solved and not talked_to_governor:
		ObjectiveManager.set_objective("Talk to the city governor")
	elif riddle_solved:
		ObjectiveManager.set_objective("Head to the city")
	elif has_all_statues():
		ObjectiveManager.set_objective("Solve the riddle of the five statues")
	else:
		ObjectiveManager.set_objective("Find the missing statues (%d/5)" % get_statue_count())

func reset_desert_state() -> void:
	collected_statues.clear()
	riddle_solved = false
	intro_objective_started = false
	talked_to_governor = false
	city_exploration_started = false
	sandmonster_quest_accepted = false
	sandmonster_quest_complete = false

func save():
	return {
		"collected_statues": collected_statues.duplicate(),
		"riddle_solved": riddle_solved,
		"intro_objective_started": intro_objective_started,
		"talked_to_governor": talked_to_governor,
		"city_exploration_started": city_exploration_started,
		"sandmonster_quest_accepted": sandmonster_quest_accepted,
		"sandmonster_quest_complete": sandmonster_quest_complete
	}

func load_data(data) -> void:
	if data.has("collected_statues"):
		collected_statues.clear()
		for statue in data.collected_statues:
			collected_statues.append(str(statue))
	riddle_solved = data.get("riddle_solved", false)
	intro_objective_started = data.get("intro_objective_started", false)
	talked_to_governor = data.get("talked_to_governor", false)
	city_exploration_started = data.get("city_exploration_started", false)
	sandmonster_quest_accepted = data.get("sandmonster_quest_accepted", false)
	sandmonster_quest_complete = data.get("sandmonster_quest_complete", false)
