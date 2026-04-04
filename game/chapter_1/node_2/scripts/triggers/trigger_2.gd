extends Trigger

# Called every frame. 'delta' is the elapsed time since the previous frame.
func handle_trigger():
	print("Trigger 2")
	ObjectiveManager.set_objective("Continue exploring")
