extends CharacterBody2D

@export var dialogue_path: String = "res://game/chapter_4/node_11/dialogue/snowman.dialogue"
@export var required_item_name: String = "snowstone"
@export var required_item_count: int = 1

var _is_talking: bool = false
var _player_in_range: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractArea
@onready var prompt_label: Label = $PromptLabel


func _ready() -> void:
	add_to_group("interaction_prompt_target")
	prompt_label.hide()
	prompt_label.top_level = true
	prompt_label.z_index = 100
	if interaction_area != null:
		interaction_area.body_entered.connect(_on_interaction_area_body_entered)
		interaction_area.body_exited.connect(_on_interaction_area_body_exited)


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

	var dialogue_tag := _resolve_dialogue_tag()
	_set_talking_animation(true)
	_is_talking = true
	prompt_label.hide()
	DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_tag)
	await DialogueManager.dialogue_ended
	_is_talking = false
	_set_talking_animation(false)
	_refresh_prompt()

	if dialogue_tag == "has_item":
		_grant_reward()


func _resolve_dialogue_tag() -> String:
	if GameState.chap4_node11_snowman_reward_claimed:
		return "after_reward"
	if _player_has_required_item():
		return "has_item"
	return "no_item"


func _player_has_required_item() -> bool:
	var player: CharacterBody2D = _get_player()
	if player == null:
		return false

	var inventory = player.get("inventory")
	if not (inventory is Dictionary):
		return false

	return int(inventory.get(required_item_name, 0)) >= required_item_count


func _grant_reward() -> void:
	var player: CharacterBody2D = _get_player()
	if player == null or GameState.chap4_node11_snowman_reward_claimed:
		return

	var inventory = player.get("inventory")
	if not (inventory is Dictionary):
		return

	var current_amount := int(inventory.get(required_item_name, 0))
	if current_amount < required_item_count:
		return

	current_amount -= required_item_count
	if current_amount > 0:
		inventory[required_item_name] = current_amount
	else:
		inventory.erase(required_item_name)

	if player.health_component != null:
		player.health_component.increase_max_hp(1)
		player.health_component.hp = player.health_component.max_hp
		player.health_component.health_changed.emit(player.health_component.hp)

	if player.hud != null:
		if player.hud.has_method("set_max_health"):
			player.hud.set_max_health(player.health_component.max_hp)
		if "top_left_gui" in player.hud and player.hud.top_left_gui != null:
			player.hud.top_left_gui.set_max_health(player.health_component.max_hp)
			player.hud.top_left_gui.update_health(player.health_component.hp)

	if player.hud != null and player.hud.has_method("refresh_items"):
		player.hud.refresh_items()

	GameState.chap4_node11_snowman_reward_claimed = true
	if player.has_method("_apply_snowstone_fire_bonus"):
		player._apply_snowstone_fire_bonus()
	SaveManager.save_game()


func _get_player() -> CharacterBody2D:
	return get_tree().get_first_node_in_group("player") as CharacterBody2D


func _set_talking_animation(is_talking: bool) -> void:
	if animated_sprite == null:
		return

	var animation_name := "talk" if is_talking and animated_sprite.sprite_frames.has_animation("talk") else "idle"
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)


func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		body.interact_with = self
		_refresh_prompt()


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		prompt_label.hide()
		if body.interact_with == self:
			body.interact_with = null


func _refresh_prompt() -> void:
	if _player_in_range and not _is_talking:
		prompt_label.text = "Press F to talk"
		prompt_label.global_position = global_position + Vector2(-54, -42)
		prompt_label.show()
	else:
		prompt_label.hide()


func show_interaction_prompt() -> void:
	_player_in_range = true
	_refresh_prompt()


func hide_interaction_prompt() -> void:
	_player_in_range = false
	prompt_label.hide()
