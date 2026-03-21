extends StaticBody2D

@export var room_id: int = 0

@onready var sprite = $AnimatedSprite2D
@onready var collision = $CollisionShape2D

func _ready():
	sprite.play("Closed")

func open():
	sprite.play("Open")
	collision.set_deferred("disabled", true)
	print("Door for room ", room_id, " is open")
