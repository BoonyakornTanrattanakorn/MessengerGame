extends StaticBody2D

@onready var sprites = [$AnimatedSprite2D, $AnimatedSprite2D2]
@onready var collision: CollisionShape2D = $CollisionShape2D

var opened: bool = false

func _ready() -> void:
	_play_all("Closed")


func open() -> void:
	if opened:
		return

	opened = true

	_play_all("Open")

	if collision:
		collision.set_deferred("disabled", true)

	print("The chapter door is open.")
	
func _play_all(anim_name: String):
	for sprite in sprites:
		sprite.play(anim_name)
