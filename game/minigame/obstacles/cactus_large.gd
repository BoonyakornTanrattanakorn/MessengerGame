extends StaticBody2D
func _ready():
	add_to_group("obstacle")
	var area = Area2D.new()
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(24, 56)
	shape.shape = rect
	area.add_child(shape)
	area.position = Vector2(0, -20)
	area.body_entered.connect(_on_body_entered)
	add_child(area)

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage()
