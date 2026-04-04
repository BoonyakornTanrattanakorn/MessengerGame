extends Area2D

func _ready():
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(area):
	if area.name == "CartArea":
		area.get_parent().can_dismount = true

func _on_area_exited(area):
	if area.name == "CartArea":
		area.get_parent().can_dismount = false
