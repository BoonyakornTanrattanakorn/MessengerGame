extends Area2D

func can_interact() -> int:
	return get_parent().can_interact()

func activate():
	get_parent().activate()
