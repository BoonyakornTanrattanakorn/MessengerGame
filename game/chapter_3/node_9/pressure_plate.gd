extends Area2D

var plate_id: int = 0
var is_glowing: bool = false
var is_correct: bool = false

@onready var glow_sprite = $GlowSprite

signal plate_activated(id: int)
signal plate_deactivated(id: int)

func _ready():
	body_entered.connect(_on_body_entered)
	if glow_sprite == null:
		print("[Plate] ERROR: GlowSprite missing on plate ", name)
		return
	glow_sprite.visible = false

func set_correct(correct: bool):
	is_correct = correct

func reset():
	is_glowing = false
	if glow_sprite:
		glow_sprite.visible = false

# PressurePlate.gd
func _on_body_entered(body):
	# Accept both player and fairy
	var is_player = body.is_in_group("player")
	var is_fairy = body.is_in_group("water_fairy")
	
	if not is_player and not is_fairy:
		return
	
	if glow_sprite == null:
		return

	if is_glowing:
		is_glowing = false
		glow_sprite.visible = false
		plate_deactivated.emit(plate_id)
		print("[Plate] Plate ", plate_id, " deactivated by ", body.name)
	else:
		is_glowing = true
		glow_sprite.visible = true
		plate_activated.emit(plate_id)
		print("[Plate] Plate ", plate_id, " activated by ", body.name, " — correct: ", is_correct)
