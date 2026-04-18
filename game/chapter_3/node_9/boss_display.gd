extends Node2D

@onready var phase1_sprite = $Phase1Sprite
@onready var phase2_sprite = $Phase2Sprite
@onready var phase3_sprite = $Phase3Sprite

const PHASE_POSITIONS = {
	1: Vector2(664, 575),
	2: Vector2(1631, 531),
	3: Vector2(1401, -629),
}

var current_phase: int = 1
var blink_timer: float = 0.0
var is_blinking: bool = false
const BLINK_DURATION: float = 0.8

func _ready():
	show_phase(1)

func _process(delta):
	if is_blinking:
		blink_timer -= delta
		# Flash red rapidly
		var flash = sin(blink_timer * 30.0) > 0
		var current = _get_current_sprite()
		if current:
			current.modulate = Color(1, 0.2, 0.2) if flash else Color(1, 1, 1)
		if blink_timer <= 0:
			is_blinking = false
			if current:
				current.modulate = Color(1, 1, 1)

func show_phase(phase: int):
	current_phase = phase
	phase1_sprite.visible = (phase == 1)
	phase2_sprite.visible = (phase == 2)
	phase3_sprite.visible = (phase == 3)
	# Move boss to correct position
	global_position = PHASE_POSITIONS.get(phase, Vector2.ZERO)
	print("[Boss] Phase ", phase, " at position ", global_position)

func play_hit():
	is_blinking = true
	blink_timer = BLINK_DURATION

func play_defeat():
	phase1_sprite.visible = false
	phase2_sprite.visible = false
	phase3_sprite.visible = false
	print("[Boss] Defeated!")

func _get_current_sprite() -> Sprite2D:
	match current_phase:
		1: return phase1_sprite
		2: return phase2_sprite
		3: return phase3_sprite
	return null
