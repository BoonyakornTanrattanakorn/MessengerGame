extends Node2D

var dialogue = load("res://game/chapter_1/node_1/dialogue/royal_knight.dialogue")
@export var save_id := "royal_knight"
@export var save_scope := "scene"

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var prompt_label: Label = $PromptLabel
@onready var area: Area2D = $Area2D

enum KnightState { ALIVE, DEAD }
var state: KnightState = KnightState.ALIVE
var player_nearby: bool = false
var is_interacting: bool = false

func _ready() -> void:
	add_to_group("savable")
	animated_sprite.play("injured")
	prompt_label.hide()
	
	# Force death animation to not loop so animation_finished fires
	animated_sprite.sprite_frames.set_animation_loop("death", false)
	
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	_apply_state_visuals()

func _process(_delta: float) -> void:
	if player_nearby and not is_interacting:
		if Input.is_action_just_pressed("interact"):
			_handle_interact()

func _handle_interact() -> void:
	match state:
		KnightState.ALIVE:
			_start_dialogue()
		KnightState.DEAD:
			_give_clue()

# --- Dialogue ---

func _start_dialogue() -> void:
	if dialogue == null:
		return
	is_interacting = true
	prompt_label.hide()
	DialogueManager.show_dialogue_balloon(dialogue, "knight_intro")
	await DialogueManager.dialogue_ended
	_play_death()
	ObjectiveManager.set_objective("Escape from this ruined tower")

func _play_death() -> void:
	animated_sprite.play("death")

func _on_animation_finished() -> void:
	if animated_sprite.animation == "death":
		animated_sprite.pause() # pause() freezes on last frame, stop() resets to frame 0
		state = KnightState.DEAD
		GameState.chap1_node1_knight_dead = true
		is_interacting = false
		SaveManager.save_game()
		if player_nearby and not GameState.clue_1_unlocked:
			prompt_label.text = "Press F to search"
			prompt_label.show()
		else:
			prompt_label.hide()

func _give_clue() -> void:
	if not GameState.clue_1_unlocked:
		is_interacting = true
		prompt_label.hide()
		DialogueManager.show_dialogue_balloon(dialogue, "knight_clue")
		await DialogueManager.dialogue_ended
		is_interacting = false
		
		GameState.clue_1_unlocked = true
		SaveManager.save_game()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		if state == KnightState.DEAD and GameState.clue_1_unlocked:
			prompt_label.hide()
			return
		if not is_interacting:
			prompt_label.text = "Press F to talk" if state == KnightState.ALIVE else "Press F to search"
			prompt_label.show()

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		prompt_label.hide()

func save() -> Dictionary:
	return {
		"state": int(state)
	}

func load_data(data: Dictionary) -> void:
	state = KnightState.ALIVE
	if data.has("state"):
		state = data.get("state", KnightState.ALIVE)
	_apply_state_visuals()

func _apply_state_visuals() -> void:
	if state == KnightState.DEAD:
		animated_sprite.play("death")
		var death_frames := animated_sprite.sprite_frames.get_frame_count("death")
		if death_frames > 0:
			animated_sprite.frame = death_frames - 1
		animated_sprite.pause()
		if player_nearby and not is_interacting and not GameState.clue_1_unlocked:
			prompt_label.text = "Press F to search"
			prompt_label.show()
		else:
			prompt_label.hide()
		return

	animated_sprite.play("injured")
	if player_nearby and not is_interacting:
		prompt_label.text = "Press F to talk"
		prompt_label.show()
