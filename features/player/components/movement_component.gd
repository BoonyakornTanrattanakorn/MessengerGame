extends Node
class_name MovementComponent

var velocity: Vector2 = Vector2.ZERO

# Dash params (internal timers/state)
var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _dash_dir: Vector2 = Vector2.ZERO

var _slide_block_timer := 0.0

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
	
	if _slide_block_timer > 0.0:
		_slide_block_timer -= delta
		return

	#print(character.is_sliding)
	if not character.is_sliding:

		if direction != Vector2.ZERO:
			
			if "is_on_ice_tile" in character:
				if character.is_on_ice_tile():
					if abs(direction.x) > abs(direction.y):
						direction = Vector2(sign(direction.x), 0)
					else:
						direction = Vector2(0, sign(direction.y))
					character.is_sliding = true
					character.slide_direction = direction

	print("a")
	if character.is_sliding:

		if "can_move_in_direction" in character:
			
			if not character.can_move_in_direction(character.slide_direction):
				print("aa")
				character.is_sliding = false
				character.velocity = Vector2.ZERO
				_slide_block_timer = 0.1
				return


		velocity = character.slide_direction * character.speed
		character.velocity = velocity
		character.move_and_slide()


		if "is_on_ice_tile" in character:
			if not character.is_on_ice_tile():
				character.is_sliding = false
		return
			
	if "can_move_in_direction" in character:
		character.can_move_in_direction(direction)

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
		
