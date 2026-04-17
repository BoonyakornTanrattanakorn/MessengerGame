# PressurePlate.gd
extends Area2D

var plate_id: int = 0
var is_glowing: bool = false
var is_correct: bool = false  # set by TileManager

@onready var glow_sprite = $GlowSprite

signal plate_stepped(id: int)

func _ready():
	body_entered.connect(_on_body_entered)
	glow_sprite.visible = false

func set_correct(correct: bool):
	is_correct = correct

func activate():
	if is_glowing:
		return
	is_glowing = true
	glow_sprite.visible = true
	plate_stepped.emit(plate_id)
	print("[Plate] Plate ", plate_id, " stepped — correct: ", is_correct)

func reset():
	is_glowing = false
	glow_sprite.visible = false

func _on_body_entered(body):
	if body.is_in_group("player"):
		activate()
