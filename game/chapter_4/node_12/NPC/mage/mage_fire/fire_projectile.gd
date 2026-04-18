extends Node12MageBaseProjectile

@export var homing_turn_speed_deg: float = 540.0
@export var homing_acceleration: float = 410.0
@export var max_homing_speed: float = 360.0
@export var homing_drag: float = 28.0
@export var lateral_damping: float = 4.2
@export var distance_kp: float = 0.025
@export var angle_kp: float = 1.35
@export var max_proportional_accel: float = 900.0

var _target_player: Node2D = null

func _ready() -> void:
	if source_element == "":
		source_element = "fire"
	base_speed = 100.0
	_target_player = _find_player()
	super._ready()

func _update_guidance(delta: float) -> void:
	if _target_player == null or not is_instance_valid(_target_player):
		_target_player = _find_player()
	if _target_player == null:
		return
	if _velocity.length_squared() <= 0.0001:
		_velocity = launch_direction.normalized() * base_speed

	var to_target := _target_player.global_position - global_position
	if to_target.length_squared() <= 0.0001:
		return

	var desired := to_target.normalized()
	var current := _velocity.normalized()
	var moving_away := current.dot(desired) < -0.05
	var current_angle := current.angle()
	var desired_angle := desired.angle()
	var angle_error := wrapf(desired_angle - current_angle, -PI, PI)
	var max_step := deg_to_rad(homing_turn_speed_deg) * delta
	var next_angle := rotate_toward(current_angle, desired_angle, max_step)
	var next_dir := Vector2.RIGHT.rotated(next_angle)
	var distance_error := to_target.length()
	var proportional_gain := clampf(distance_error * distance_kp + abs(angle_error) * angle_kp, 0.0, 1.0)

	# Proportional-control acceleration: stronger correction when farther off target.
	var accel_strength = min(max_proportional_accel, homing_acceleration * proportional_gain)
	var accel = desired * accel_strength
	if not moving_away:
		accel += next_dir * accel_strength
	else:
		# Strong correction after overshoot to prevent endless orbiting.
		accel += desired * accel_strength * 0.55
	_velocity += accel * delta

	# Dampen sideways motion relative to the target direction to collapse circular orbits.
	if lateral_damping > 0.0:
		var forward_speed := _velocity.dot(desired)
		var lateral := _velocity - desired * forward_speed
		_velocity -= lateral * min(1.0, lateral_damping * delta)

	if homing_drag > 0.0:
		_velocity = _velocity.move_toward(Vector2.ZERO, homing_drag * delta)
	if moving_away and homing_acceleration > 0.0:
		_velocity = _velocity.move_toward(Vector2.ZERO, homing_acceleration * delta)

	var speed := _velocity.length()
	if speed > max_homing_speed:
		_velocity = _velocity.normalized() * max_homing_speed
	elif speed <= 0.0001:
		_velocity = desired * max(20.0, base_speed * 0.25)

	if _velocity.length_squared() > 0.0001:
		launch_direction = _velocity.normalized()
		rotation = launch_direction.angle()

func _get_telegraph_tint() -> Color:
	return Color(1.0, 0.78, 0.58, 0.78)

func _get_reflected_tint() -> Color:
	return Color(1.0, 0.58, 0.45, 1.0)

func _find_player() -> Node2D:
	var root := get_tree().current_scene
	if root == null:
		return null
	var by_name := root.find_child("Player", true, false)
	if by_name != null and by_name is Node2D:
		return by_name
	var lower_name := root.find_child("player", true, false)
	if lower_name != null and lower_name is Node2D:
		return lower_name
	return null
