extends Area2D
class_name Fire_small

var speed = 300.0
var direction = Vector2.RIGHT
var damage = 1

func _ready():
	$CollisionShape2D  # make sure you have one
	connect("body_entered", _on_body_entered)

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	pass
