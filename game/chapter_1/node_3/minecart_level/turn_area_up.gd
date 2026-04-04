extends Area2D

@export var redirect_direction: Vector2 = Vector2.UP
@export var required_input: String = "down"

var carts_in_zone = []

func _ready():
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(area):
	if area.name == "CartArea":
		var cart = area.get_parent()
		cart.in_turn_zone = true
		cart.turn_direction = redirect_direction
		cart.turn_input = required_input
		carts_in_zone.append(cart)

func _on_area_exited(area):
	if area.name == "CartArea":
		var cart = area.get_parent()
		cart.in_turn_zone = false
		carts_in_zone.erase(cart)
