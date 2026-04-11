extends StaticBody2D

@export var duration = 5.0
@export var pulse_radius: float = 42.0
@export var pulse_interval: float = 0.65
@export var pulse_damage: int = 1
var is_floating = false

func setup_pillar(on_water: bool):
	is_floating = on_water
	
	if is_floating:
		set_collision_layer_value(1, false)
		set_collision_mask_value(1, false)
		print("Pillar: Floating mode")
	else:
		print("Pillar: Block mode")

	start_damage_pulse()

	await get_tree().create_timer(duration).timeout
	queue_free()

func start_damage_pulse() -> void:
	while is_inside_tree():
		for body in get_tree().get_nodes_in_group("enemy"):
			if body == null:
				continue
			if global_position.distance_to(body.global_position) > pulse_radius:
				continue
			if body.has_method("take_damage"):
				body.take_damage(pulse_damage, "earth")
		await get_tree().create_timer(pulse_interval).timeout
