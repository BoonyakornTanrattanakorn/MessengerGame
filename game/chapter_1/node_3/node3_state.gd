extends Node

const TOTAL_GEMS := 3

var collected_gems: Array[String] = []
var intro_objective_started := false

func start_node3_objective() -> void:
	if intro_objective_started:
		return
	intro_objective_started = true
	update_objective()

func collect_gem(gem_id: String) -> void:
	if gem_id not in collected_gems:
		collected_gems.append(gem_id)
	update_objective()

func has_all_gems() -> bool:
	return collected_gems.size() >= TOTAL_GEMS

func get_gem_count() -> int:
	return collected_gems.size()

func update_objective() -> void:
	if has_all_gems():
		ObjectiveManager.set_objective("Interact with the final door")
	else:
		ObjectiveManager.set_objective("Collect gems (%d/3)" % get_gem_count())

func reset_node3_state() -> void:
	collected_gems.clear()
	intro_objective_started = false
