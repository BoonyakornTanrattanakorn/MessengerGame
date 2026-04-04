extends Node
class_name MovementComponent

var velocity: Vector2 = Vector2.ZERO

# Dash params (internal timers/state)
var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _dash_dir: Vector2 = Vector2.ZERO

func process_movement(character: CharacterBody2D, direction: Vector2, speed_multiplier: float, delta: float) -> void:
	# update cooldown
	if _dash_cooldown_timer > 0.0:
		_dash_cooldown_timer = max(0.0, _dash_cooldown_timer - delta)

	# sync cooldown back to character for compatibility
	if "dash_cooldown_timer" in character:
		character.dash_cooldown_timer = _dash_cooldown_timer

	# handle active dash
	if _is_dashing:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			_is_dashing = false
			_dash_cooldown_timer = character.dash_cooldown
		else:
			# apply dash movement
			velocity = _dash_dir * character.dash_speed
			character.velocity = velocity
			character.move_and_slide()
			# reflect dash state on character script
			if "is_dashing" in character:
				character.is_dashing = true
			return

	# normal movement
	velocity = direction * character.speed * speed_multiplier
	character.velocity = velocity
	character.move_and_slide()

	# ensure character dash flag is false when not dashing
	if "is_dashing" in character:
		character.is_dashing = false

func request_dash(character: CharacterBody2D, direction: Vector2) -> void:
	if _dash_cooldown_timer > 0.0 or _is_dashing:
		return
	if direction.length() == 0:
		return
	_is_dashing = true
	_dash_dir = direction.normalized()
	# set timer from the character's configured dash duration
	if "dash_duration" in character:
		_dash_timer = float(character.dash_duration)
	else:
		_dash_timer = 0.15
