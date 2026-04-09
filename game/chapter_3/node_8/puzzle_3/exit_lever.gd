extends Area2D

signal lever_pulled

@export var is_pulled := false
@export var texture_off: Texture2D
@export var texture_on: Texture2D

@onready var sprite: Sprite2D = $Sprite2D

var _player_in_range := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if _player_in_range and not is_pulled and Input.is_action_just_pressed("interact"):
		_pull()

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		_player_in_range = false

func _pull() -> void:
	is_pulled = true
	if sprite and texture_on:
		sprite.texture = texture_on
	lever_pulled.emit()
