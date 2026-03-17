extends Area2D

signal lever_activated(room_id: int)

@export var room_id: int = 0

@onready var sprite = $AnimatedSprite2D

var is_active: bool = false
var player_in_range: bool = false

func _ready():
	sprite.play("off")

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("ui_accept"):
		activate_lever()

func activate_lever():
	if not is_active:
		is_active = true
		sprite.play("on")
		lever_activated.emit(room_id)
		print("Lever activated in room ", room_id)

func _on_area_entered(area):
	if area.name.to_lower().contains("wind") or area.is_in_group("wind_magic"):
		activate_lever()
		if area.has_method("queue_free"):
			area.queue_free()

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
