extends Area2D

var speed = 300.0
var direction = Vector2.RIGHT
var source: String = "fire"
var damage: int = 1

func _ready():
	$CollisionShape2D  # make sure you have one
	add_to_group("enemy_projectile")
	connect("body_entered", _on_body_entered)

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	pass
