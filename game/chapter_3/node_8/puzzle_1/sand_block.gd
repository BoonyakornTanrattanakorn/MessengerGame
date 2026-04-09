extends CharacterBody2D

signal landed_on_plate(block: Node2D, plate: Node2D)
signal left_plate(block: Node2D, plate: Node2D)

const PUSH_SPEED := 80.0
const TILE_SIZE := 16

var _is_moving := false
var _push_direction := Vector2.ZERO
var _target_position := Vector2.ZERO
var _current_plate: Node2D = null

# Area2D child named "PushDetector" - add this in the scene, slightly larger than the block
@onready var _push_detector: Area2D = $PushDetector

func _physics_process(delta: float) -> void:
	if _is_moving:
		_slide_to_target(delta)
		return

	_check_player_push()

func _slide_to_target(delta: float) -> void:
	var remaining := _target_position - global_position
	var step := _push_direction * PUSH_SPEED * delta

	if remaining.length() <= step.length():
		global_position = _target_position
		_is_moving = false
		velocity = Vector2.ZERO
	else:
		velocity = _push_direction * PUSH_SPEED
		move_and_slide()

func _check_player_push() -> void:
	for body in _push_detector.get_overlapping_bodies():
		if body.name != "Player":
			continue
		if body.velocity.length() < 10.0:
			continue
		# Check if player is moving toward the block
		var to_block := (global_position - body.global_position).normalized()
		if body.velocity.normalized().dot(to_block) > 0.5:
			var dir := Vector2(round(to_block.x), round(to_block.y))
			push(dir)
			break

func push(direction: Vector2) -> void:
	if _is_moving:
		return

	_push_direction = direction.normalized()
	_target_position = global_position + _push_direction * TILE_SIZE

	# Check if something is blocking the destination
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		global_position,
		_target_position,
		collision_mask
	)
	query.exclude = [self]
	var result := space.intersect_ray(query)
	if result:
		return

	_is_moving = true

func set_on_plate(plate: Node2D) -> void:
	_current_plate = plate
	landed_on_plate.emit(self, plate)

func clear_plate() -> void:
	if _current_plate:
		left_plate.emit(self, _current_plate)
		_current_plate = null
