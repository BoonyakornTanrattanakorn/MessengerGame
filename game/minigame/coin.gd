extends Area2D

@export var speed := 300.0

func _process(delta):
	position.x -= speed * delta
	if position.x < -100:
		queue_free()


func _on_body_entered(body):
	if body.name == "Player":
		body.add_coin()
		queue_free()
