extends Area2D
class_name Fire_small

var speed = 300.0
var direction = Vector2.RIGHT
var damage = 1
var source_element: String = "fire"

func _ready():
	$CollisionShape2D  # make sure you have one
	add_to_group("fire_reflector")
	connect("body_entered", _on_body_entered)

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body == null:
		return
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(damage, source_element)
		queue_free()
