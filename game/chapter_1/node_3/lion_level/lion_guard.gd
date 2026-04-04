extends Node2D

@export var scared_texture: Texture2D
@export var disappear_delay := 0.35

@onready var sprite: Sprite2D = $Sprite2D

var gone := false

func scare_and_leave() -> void:
	if gone:
		return

	gone = true

	if scared_texture:
		sprite.texture = scared_texture

	await get_tree().create_timer(disappear_delay).timeout
	queue_free()
