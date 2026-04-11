# cactus.gd
extends StaticBody2D

func _on_hurt_zone_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage()
