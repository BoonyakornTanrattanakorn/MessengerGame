extends Area2D

@export var locked_texture: Texture2D
@export var unlocked_texture: Texture2D
@export var coming_soon_scene_path: String = "res://ui/coming_soon.tscn"

@onready var sprite: Sprite2D = $Sprite2D

var unlocked := false

func _ready() -> void:
	refresh_state()

func can_interact() -> int:
	return 0

func activate():
	refresh_state()

	if not unlocked:
		print("Need all 3 gems first")
		return

	get_tree().change_scene_to_file(coming_soon_scene_path)

func refresh_state() -> void:
	var player = get_tree().root.find_child("Player", true, false)
	if player == null:
		return

	unlocked = has_all_gems(player)

	if sprite:
		if unlocked and unlocked_texture:
			sprite.texture = unlocked_texture
		elif not unlocked and locked_texture:
			sprite.texture = locked_texture

func has_all_gems(player) -> bool:
	return (
		player.inventory.get("red_gem", 0) > 0
		and player.inventory.get("green_gem", 0) > 0
		and player.inventory.get("blue_gem", 0) > 0
	)
