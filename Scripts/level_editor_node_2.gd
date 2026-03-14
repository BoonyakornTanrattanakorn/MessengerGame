extends Node2D

@export var total_levers: int = 2
var activated_levers: int = 0

@onready var door: StaticBody2D = $Door

func _ready():
	for child in get_children():
		if child.has_signal("lever_activated"):
			child.lever_activated.connect(_on_lever_activated)

func _on_lever_activated():
	activated_levers += 1
	print("Levers active: ", activated_levers, "/", total_levers)
	
	if activated_levers >= total_levers:
		open_door()

func open_door():
	print("All levers active! Door opening...")
	if door:
		door.open()
