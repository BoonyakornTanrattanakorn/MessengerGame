extends Area2D

@export var speed := 350.0

@onready var anim = $AnimatedSprite2D

func _ready():
ii	anim.play("fly")

func _process(delta):
	position.x -= speed * delta
	
	if position.x < -100:
		queue_free()


func _on_body_entered(body):
	if body.name == "Player":
		body.take_damage()
		queue_free()
