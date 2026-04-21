extends Area2D

var dialogue := load("res://game/chapter_4/node_11/dialogue/bookcase_clue.dialogue")

var _is_talking := false
var _player_in_range := false

@onready var prompt_labels := {
	"normalbookcase": $NormalBookcaseLabel,
	"normalbookcase2": $NormalBookcase2Label,
	"normalbookcase3": $NormalBookcase3Label,
	"normalbookcase4": $NormalBookcase4Label,
	"normalbookcase5": $NormalBookcase5Label,
	"normalbookcase6": $NormalBookcase6Label,
	"normalbookcase7": $NormalBookcase7Label,
	"cluebookcase": $ClueBookcaseLabel,
}


func _ready() -> void:
	add_to_group("interaction_prompt_target")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	for label in prompt_labels.values():
		label.hide()
		label.z_index = 100

func can_interact() -> int:
	return 0

func activate() -> void:
	if _is_talking:
		return
		
	if not GameState.chap4_node11_tower_master_returned:
		return

	if dialogue == null:
		push_warning("Failed to load dialogue resource for bookcases")
		return

	var nearest_hitbox := _get_nearest_hitbox()
	var tag := _resolve_tag_from_hitbox(nearest_hitbox)
	_is_talking = true
	_hide_all_prompt_labels()
	DialogueManager.show_dialogue_balloon(dialogue, tag)
	await DialogueManager.dialogue_ended
	_is_talking = false
	_refresh_prompt()

	if tag == "clue" and not GameState.clue_4_unlocked:
		GameState.clue_4_unlocked = true
		ObjectiveManager.set_objective("Talk to the boss soldier")
		SaveManager.save_game()

func _get_nearest_hitbox() -> CollisionShape2D:
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not (player is Node2D):
		return null

	var player_pos: Vector2 = (player as Node2D).global_position
	var nearest_hitbox: CollisionShape2D = null
	var nearest_distance := INF

	for child in get_children():
		if child is CollisionShape2D:
			var hitbox := child as CollisionShape2D
			if hitbox.disabled:
				continue

			var distance := player_pos.distance_to(hitbox.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_hitbox = hitbox

	return nearest_hitbox


func _resolve_tag_from_hitbox(hitbox: CollisionShape2D) -> String:
	if hitbox == null:
		return "normal"

	if hitbox.name.to_lower().find("clue") != -1:
		return "clue"

	return "normal"


func _get_prompt_label_for_hitbox(hitbox: CollisionShape2D) -> Label:
	if hitbox == null:
		return null

	return prompt_labels.get(hitbox.name.to_lower()) as Label


func _hide_all_prompt_labels() -> void:
	for label in prompt_labels.values():
		label.hide()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		body.set("interact_with", self)
		_refresh_prompt()


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		_hide_all_prompt_labels()
		if body.get("interact_with") == self:
			body.set("interact_with", null)


func _refresh_prompt() -> void:
	if _player_in_range and not _is_talking and GameState.chap4_node11_tower_master_returned:
		var nearest_hitbox := _get_nearest_hitbox()
		var prompt_label := _get_prompt_label_for_hitbox(nearest_hitbox)
		_hide_all_prompt_labels()
		if prompt_label != null:
			prompt_label.text = "Press F to read"
			prompt_label.show()
	else:
		_hide_all_prompt_labels()


func show_interaction_prompt() -> void:
	_player_in_range = true
	_refresh_prompt()


func hide_interaction_prompt() -> void:
	_player_in_range = false
	_hide_all_prompt_labels()
