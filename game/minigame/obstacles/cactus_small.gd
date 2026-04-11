extends StaticBody2D

@export var speed := 300.0

func _process(delta):
	position.x -= speed * delta
	
	if position.x < -150:
		queue_free()
