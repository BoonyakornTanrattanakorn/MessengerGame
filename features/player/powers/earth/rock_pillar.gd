extends Node2D

@onready var body = $StaticBody2D
@onready var area = $Area2D

@export var duration = 10
var is_in_hole = false
var is_floating = false

func _ready():
	add_to_group("rock_pillar_main") 
	area.add_to_group("rock_pillar")
	start_timer()

func setup_pillar(on_water: bool):
	add_to_group("earth_reflector")
	is_floating = on_water
	if is_floating:
		body.set_collision_layer_value(1, false)
		body.set_collision_mask_value(1, false)
		print("Pillar: Floating mode (Walkable)")
	else:
		body.set_collision_layer_value(1, true)
		body.set_collision_mask_value(1, true)
		print("Pillar: Block mode")

func enter_hole():
	if is_in_hole: return
	is_in_hole = true
	
	body.set_collision_layer_value(1, false)
	area.monitoring = false
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_property(self, "scale", Vector2(0.5, 0.5), 0.3)

func start_timer():
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
