extends Trigger

@export var save_id = "trigger3"
@export var save_scope = "scene"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func handle_trigger():
	print("Trigger 3")
	ObjectiveManager.set_objective("Talk to the gatekeeper")
