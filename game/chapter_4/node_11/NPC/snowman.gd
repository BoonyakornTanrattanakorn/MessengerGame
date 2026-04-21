extends CharacterBody2D

@export var dialogue_path: String = "res://game/chapter_4/node_11/dialogue/snowman.dialogue"
@export var required_item_name: String = "desert_crystal"
@export var required_item_count: int = 1

var _is_talking: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func can_interact() -> int:
	return 0


func activate() -> void:
	_talk()


func _talk() -> void:
	if _is_talking:
		return

	var dialogue_resource := load(dialogue_path)
	if dialogue_resource == null:
		push_warning("Snowman dialogue missing: %s" % dialogue_path)
		return

	var dialogue_tag := "has_item" if _player_has_required_item() else "no_item"
	_set_talking_animation(true)
	_is_talking = true
	DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_tag)
	await DialogueManager.dialogue_ended
	_is_talking = false
	_set_talking_animation(false)


func _player_has_required_item() -> bool:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return false

	var inventory = player.get("inventory")
	if not (inventory is Dictionary):
		return false

	return int(inventory.get(required_item_name, 0)) >= required_item_count


func _set_talking_animation(is_talking: bool) -> void:
	if animated_sprite == null:
		return

	var animation_name := "talk" if is_talking and animated_sprite.sprite_frames.has_animation("talk") else "idle"
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)
