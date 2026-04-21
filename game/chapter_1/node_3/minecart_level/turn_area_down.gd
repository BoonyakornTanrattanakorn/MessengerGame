extends Area2D

@export var redirect_direction: Vector2 = Vector2.DOWN
var carts_in_zone = []

func _ready():
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	# Handle carts already inside the zone at scene start
	call_deferred("_check_initial_overlaps")

func _check_initial_overlaps():
	for area in get_overlapping_areas():
		if area.name == "CartArea":
			var cart = area.get_parent()
			cart.in_turn_zone = true
			cart.turn_direction = redirect_direction
			if not carts_in_zone.has(cart):
				carts_in_zone.append(cart)

func _on_area_entered(area):
	if area.name == "CartArea":
		var cart = area.get_parent()
		cart.in_turn_zone = true
		cart.turn_direction = redirect_direction
		carts_in_zone.append(cart)

func _on_area_exited(area):
	if area.name == "CartArea":
		var cart = area.get_parent()
		cart.in_turn_zone = false
		carts_in_zone.erase(cart)
