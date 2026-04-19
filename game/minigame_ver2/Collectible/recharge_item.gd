# recharge_item.gd
extends Area2D

signal picked_up

func _ready():
	add_to_group("recharge")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		emit_signal("picked_up")
		queue_free()
