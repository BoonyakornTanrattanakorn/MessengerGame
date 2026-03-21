extends StaticBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

var opened: bool = false

func _ready() -> void:
	if sprite:
		sprite.play("Closed")

func open() -> void:
	if opened:
		return

	opened = true

	if sprite:
		sprite.play("Open")

	if collision:
		collision.set_deferred("disabled", true)

	print("The chapter door is open.")
