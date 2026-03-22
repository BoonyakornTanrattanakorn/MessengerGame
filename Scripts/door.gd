extends StaticBody2D

@export var room_id: int = 0

# Using a list or a container makes it easier to manage multiple parts
@onready var sprites = [$AnimatedSprite2D, $AnimatedSprite2D2]
@onready var collision = $CollisionShape2D

func _ready():
	_play_all("Closed")
	# Force the top part to stay above the bottom part to stop blinking
	$AnimatedSprite2D.z_index = 1 
	$AnimatedSprite2D2.z_index = 0

func open():
	_play_all("Open")
	collision.set_deferred("disabled", true)
	print("Door for room ", room_id, " is open")

# Helper function so you don't have to write the same line twice
func _play_all(anim_name: String):
	for sprite in sprites:
		sprite.play(anim_name)
