extends Node

const TOTAL_BIG_SANDMONSTERS := 3
var big_sandmonsters_killed := 0
const TOTAL_STATUES := 5
var collected_statues: Array[String] = []
var talked_to_guard := false
var riddle_solved := false
var talked_to_governor := false
var intro_objective_started := false
var sandmonster_quest_accepted := false
var sandmonster_quest_complete := false
var talked_to_guard_after_riddle := false
var sandmonster_quest_turned_in := false
var visited_shop := false

func _ready() -> void:
	add_to_group("savable")

func update_objective() -> void:
	if sandmonster_quest_turned_in:
		ObjectiveManager.set_objective("Head to the next city")
		SaveManager.save_game()
	elif sandmonster_quest_complete:
		ObjectiveManager.set_objective("Return to the quest giver")
		SaveManager.save_game()
	elif sandmonster_quest_accepted:
		ObjectiveManager.set_objective(
			"Defeat big sand monsters (%d/%d)" % [big_sandmonsters_killed, TOTAL_BIG_SANDMONSTERS]
		)
		SaveManager.save_game()
	elif talked_to_governor:
		ObjectiveManager.set_objective("Explore the city")
		SaveManager.save_game()
	elif riddle_solved and talked_to_guard_after_riddle:
		ObjectiveManager.set_objective("Talk to the city governor")
		SaveManager.save_game()
	elif riddle_solved:
		ObjectiveManager.set_objective("Talk to the guard again")
		SaveManager.save_game()
	elif talked_to_guard:
		if has_all_statues():
			ObjectiveManager.set_objective("Solve the riddle of the five statues")
			SaveManager.save_game()
		else:
			ObjectiveManager.set_objective(
				"Find the missing statues (%d/%d)" % [get_statue_count(), TOTAL_STATUES]
			)
	else:
		ObjectiveManager.set_objective("Talk to the Guard")
		SaveManager.save_game()

func accept_quest() -> void:
	if sandmonster_quest_accepted:
		return
	sandmonster_quest_accepted = true
	big_sandmonsters_killed = 0
	update_objective()
	get_tree().call_group("quest_blocker", "update_blocker")
		
func on_big_sandmonster_killed() -> void:
	if not sandmonster_quest_accepted or sandmonster_quest_complete:
		return

	big_sandmonsters_killed += 1
	print("Big monsters killed: ", big_sandmonsters_killed)

	if big_sandmonsters_killed >= TOTAL_BIG_SANDMONSTERS:
		sandmonster_quest_complete = true
		print("Side quest complete!")
		
	update_objective()
	get_tree().call_group("portal", "update_portal_state")

func start_desert_objective() -> void:
	if intro_objective_started:
		return
	intro_objective_started = true
	update_objective()

func talk_to_guard_done() -> void:
	talked_to_guard = true
	update_objective()

func collect_statue(statue_id: String) -> void:
	if statue_id not in collected_statues:
		collected_statues.append(statue_id)
	update_objective()

func solve_riddle() -> void:
	riddle_solved = true
	update_objective()

func talk_to_guard_after_riddle_done() -> void:
	talked_to_guard_after_riddle = true
	update_objective()
	
# Add a reset function and separate the two flags
func talk_to_governor() -> void:
	talked_to_governor = true
	update_objective()

# Add a reset so stale state doesn't bleed across sessions
func reset() -> void:
	collected_statues.clear()
	talked_to_guard = false
	riddle_solved = false
	talked_to_governor = false
	intro_objective_started = false
	sandmonster_quest_accepted = false
	sandmonster_quest_complete = false
	talked_to_guard_after_riddle = false
	visited_shop = false
	big_sandmonsters_killed = 0

func has_all_statues() -> bool:
	return collected_statues.size() >= TOTAL_STATUES

func get_statue_count() -> int:
	return collected_statues.size()
