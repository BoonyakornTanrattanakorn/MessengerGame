extends Area2D

var speed = 150.0  # default, gets overridden by boss
var direction = Vector2.ZERO

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("boss"):
		return
	if body.name == "Player":
		body.take_damage(1)
		queue_free()
