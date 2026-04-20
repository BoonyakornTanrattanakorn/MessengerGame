extends Area2D

signal lever_activated(room_id: int)

@export var room_id: int = 0

@onready var sprite = $AnimatedSprite2D

var is_active: bool = false
var player_in_range: bool = false

@export var save_id = "lever_1"
@export var save_scope = "scene" 

func _ready():
	add_to_group("savable")
	sprite.play("off")

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		activate_lever()

func activate_lever():
	if not is_active:
		is_active = true
		sprite.play("on")
		lever_activated.emit(room_id)
		print("Lever activated in room ", room_id)

func _on_area_entered(area):
	if area.name.to_lower().contains("wind") or area.is_in_group("wind_wave"):
		activate_lever()
		if area.has_method("queue_free"):
			area.queue_free()

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		
func _update_sprite():
	if is_active:
		sprite.play("on")
	else:
		sprite.play("off")
		
func save():
	return {
		"is_active": is_active
	}

func load_data(data):
	is_active = data.get("is_active", false)
	_update_sprite()
