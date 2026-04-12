extends Node

var talked_to_village_chief: bool = false

var first_insignia_started: bool = false
var first_insignia_obtained: bool = false

var second_insignia_started: bool = false
var second_insignia_obtained: bool = false

var cat_quest_started: bool = false
var total_cats: int = 4
var cats_found: int = 0
var found_cat_ids: Dictionary = {}

var exit_gate_opened: bool = false

func start_node4() -> void:
	print("start node4")
	if not talked_to_village_chief:
		ObjectiveManager.set_objective("Talk to village chief")
	else:
		_update_insignia_objective()

func talk_to_village_chief() -> void:
	talked_to_village_chief = true
	_update_insignia_objective()

func enter_upper_node() -> void:
	if talked_to_village_chief and not first_insignia_obtained:
		first_insignia_started = true
		ObjectiveManager.set_objective("Solve the mechanism and collect the insignia")

func enter_lower_node() -> void:
	if talked_to_village_chief and not second_insignia_obtained and not cat_quest_started:
		second_insignia_started = true
		ObjectiveManager.set_objective("Talk to the cat lady")

func obtain_first_insignia() -> void:
	if first_insignia_obtained:
		return
	
	first_insignia_obtained = true
	_update_insignia_objective()

func start_cat_lady_quest() -> void:
	if second_insignia_obtained:
		return
	
	if cat_quest_started:
		return
	
	second_insignia_started = true
	cat_quest_started = true
	cats_found = 0
	found_cat_ids.clear()
	ObjectiveManager.set_objective("Find all 4 cats")

func register_cat(cat_id: String) -> bool:
	if not cat_quest_started:
		return false
	
	if found_cat_ids.has(cat_id):
		return false
	
	found_cat_ids[cat_id] = true
	cats_found += 1
	
	if cats_found >= total_cats:
		ObjectiveManager.set_objective("Return to the cat lady")
	else:
		ObjectiveManager.set_objective("Find all 4 cats (%d/%d)" % [cats_found, total_cats])
	
	return true

func all_cats_found() -> bool:
	return cats_found >= total_cats

func obtain_second_insignia() -> void:
	if second_insignia_obtained:
		return
	
	second_insignia_obtained = true
	cat_quest_started = false
	_update_insignia_objective()

func both_insignias_obtained() -> bool:
	return first_insignia_obtained and second_insignia_obtained

func insignias_obtained_count() -> int:
	var count := 0
	if first_insignia_obtained:
		count += 1
	if second_insignia_obtained:
		count += 1
	return count

func open_exit_gate() -> void:
	exit_gate_opened = true

func _update_insignia_objective() -> void:
	if not talked_to_village_chief:
		ObjectiveManager.set_objective("Talk to village chief")
		return
	
	var count := insignias_obtained_count()
	
	if count >= 2:
		ObjectiveManager.set_objective("Return to village chief")
	else:
		ObjectiveManager.set_objective("Collect insignias (%d/2)" % count)
