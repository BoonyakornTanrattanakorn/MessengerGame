extends StaticBody2D

@onready var sprites = [$AnimatedSprite2D, $AnimatedSprite2D2]
@onready var collision: CollisionShape2D = $CollisionShape2D

var opened: bool = false

@export var save_id = "last_door"
@export var save_scope = "scene" 

func _ready() -> void:
	add_to_group("savable")
	_play_all("Closed")


func open() -> void:
	if opened:
		return

	opened = true

	_play_all("Open")
	ObjectiveManager.set_objective("Leave the dungeons")

	if collision:
		collision.set_deferred("disabled", true)

	print("The chapter door is open.")
	
func _play_all(anim_name: String):
	for sprite in sprites:
		sprite.play(anim_name)
		
func save():
	return {
		"opened": opened
	}

func load_data(data):
	opened = data.get("opened", false)
	if opened:
		_play_all("Open")
		if collision:
			collision.set_deferred("disabled", true)
		
