extends Trigger

@export var save_id = "city_entrance_trigger"
@export var save_scope = "scene"

func handle_trigger():
	if Node7State.riddle_solved and not Node7State.talked_to_governor:
		Node7State.update_objective()
