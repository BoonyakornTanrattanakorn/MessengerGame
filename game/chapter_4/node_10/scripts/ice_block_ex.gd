extends IceBlock


func melt():
	
	super.melt()
	
	var current_objective = ObjectiveManager.get_objective()
	
	if(current_objective == "Use fire to melt the ice block"):
		ObjectiveManager.set_objective("Reach the exit chamber.")
