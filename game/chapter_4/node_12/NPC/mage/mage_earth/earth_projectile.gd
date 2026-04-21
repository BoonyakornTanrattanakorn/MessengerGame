extends Node12MageBaseProjectile

func _ready() -> void:
	if source_element == "":
		source_element = "earth"
	base_speed = 500.0
	super._ready()

func _get_aim_direction(target_position: Vector2) -> Vector2:
	# Earth behavior is simple direct aim for shotgun/straight-line firing.
	return target_position - global_position
