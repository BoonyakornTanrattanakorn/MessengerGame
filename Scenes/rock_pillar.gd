extends StaticBody2D

@export var duration = 5.0
var is_floating = false

func setup_pillar(on_water: bool):
	is_floating = on_water
	
	if is_floating:
		set_collision_layer_value(1, false)
		set_collision_mask_value(1, false)
		print("Pillar: Floating mode")
	else:
		print("Pillar: Block mode")

	await get_tree().create_timer(duration).timeout
	queue_free()
