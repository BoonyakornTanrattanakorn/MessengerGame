extends Node2D

@export var dialogue_resource: DialogueResource

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var prompt_label: Label = $PromptLabel
@onready var area: Area2D = $Area2D

enum KnightState { ALIVE, DEAD }
var state: KnightState = KnightState.ALIVE
var player_nearby: bool = false
var is_interacting: bool = false

func _ready() -> void:
	animated_sprite.play("injured")
	prompt_label.hide()
	
	# Force death animation to not loop so animation_finished fires
	animated_sprite.sprite_frames.set_animation_loop("death", false)
	
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	animated_sprite.animation_finished.connect(_on_animation_finished)

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
	if dialogue_resource == null:
		return
	is_interacting = true
	prompt_label.hide()
	DialogueManager.show_dialogue_balloon(dialogue_resource, "knight_intro")
	await DialogueManager.dialogue_ended
	_play_death()

func _play_death() -> void:
	animated_sprite.play("death")

func _on_animation_finished() -> void:
	if animated_sprite.animation == "death":
		animated_sprite.pause() # pause() freezes on last frame, stop() resets to frame 0
		state = KnightState.DEAD
		is_interacting = false
		if player_nearby:
			prompt_label.text = "Press F to search"
			prompt_label.show()

func _give_clue() -> void:
	if GameState.clue_1_unlocked:
		return
	GameState.clue_1_unlocked = true
	is_interacting = true
	prompt_label.hide()
	DialogueManager.show_dialogue_balloon(dialogue_resource, "knight_clue")
	await DialogueManager.dialogue_ended
	is_interacting = false

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		if not is_interacting:
			prompt_label.text = "Press F to talk" if state == KnightState.ALIVE else "Press F to search"
			prompt_label.show()

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		prompt_label.hide()
