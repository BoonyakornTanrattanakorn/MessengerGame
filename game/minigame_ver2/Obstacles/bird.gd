# bird.gd
extends Area2D

func _ready():
	$AnimatedSprite2D.play("fly")

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage()
