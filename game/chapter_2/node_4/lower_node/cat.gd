extends Area2D

@export var cat_id: String = "cat_1"
@export var anim_name: String = "idle"

var _player_in_range: bool = false
var _collected: bool = false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Play assigned animation
	if anim.sprite_frames and anim.sprite_frames.has_animation(anim_name):
		anim.play(anim_name)
		
		# Randomize start frame (so cats aren't synced)
		anim.frame = randi() % anim.sprite_frames.get_frame_count(anim_name)
	else:
		anim.play("idle") # fallback

func _process(_delta: float) -> void:
	if _player_in_range and Input.is_action_just_pressed("interact"):
		_collect()

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		_player_in_range = false

func _collect() -> void:
	if _collected:
		return
	
	if not Node4State.cat_quest_started:
		print("Talk to the cat lady first")
		return
	
	if Node4State.register_cat(cat_id):
		_collected = true
		$CollisionShape2D.set_deferred("disabled", true)
		hide()
