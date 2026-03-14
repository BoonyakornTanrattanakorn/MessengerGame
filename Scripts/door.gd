extends StaticBody2D

@onready var sprite = $AnimatedSprite2D
@onready var collision = $CollisionShape2D

func _ready():
	sprite.play("Closed")

func open():
	sprite.play("Open")
	
	collision.set_deferred("disabled", true) 
	print("the door is open")
