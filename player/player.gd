extends CharacterBody2D

var speed = 300.0  # speed in pixels/sec
var dash_speed = 800.0
var dash_duration = 0.15
var dash_cooldown = 0.5

var playerAttribute = "wind"

# Dash system
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var last_direction: Vector2 = Vector2.RIGHT  # Track last faced direction

func _physics_process(delta):
	var direction = Input.get_vector("left", "right", "up", "down")
	
	# Update last direction if there's input
	if direction.length() > 0:
		last_direction = direction.normalized()
	
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	
	# Handle dashing
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			# End dash
			is_dashing = false
			dash_cooldown_timer = dash_cooldown
		else:
			# During dash: move in dash direction at dash speed
			velocity = last_direction * dash_speed
			move_and_slide()
			return  # Skip rest of physics processing while dashing
	
	# Handle dash input (only if not on cooldown and not already dashing)
	if Input.is_action_just_pressed("minor magic") and dash_cooldown_timer <= 0 and not is_dashing and playerAttribute == "wind":
		# Start dash in last faced direction
		is_dashing = true
		dash_timer = dash_duration
		velocity = last_direction * dash_speed
	
	# Normal movement
	velocity = direction * speed
	move_and_slide()
