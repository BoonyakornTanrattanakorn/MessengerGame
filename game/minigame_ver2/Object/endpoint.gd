extends Area2D

signal level_completed

func _ready():
	add_to_group("endpoint")
	body_entered.connect(_on_body_entered)

# endpoint.gd
func _on_body_entered(body):
	print("body entered: ", body.name)
	if body.is_in_group("player"):
		print("player detected — emitting level_completed")
		emit_signal("level_completed")
