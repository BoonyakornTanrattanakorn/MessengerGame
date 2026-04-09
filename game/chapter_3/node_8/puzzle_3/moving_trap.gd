extends CharacterBody2D

signal player_hit(trap: Node2D)

@export var move_direction: Vector2 = Vector2.RIGHT
@export var move_speed: float = 60.0
@export var travel_distance: float = 96.0

var _origin: Vector2
var _traveled: float = 0.0
var _direction_sign: float = 1.0
var _is_blocked := false
var _blocked_timer: float = 0.0

func _ready() -> void:
	_origin = global_position
	add_to_group("moving_trap")

func _physics_process(delta: float) -> void:
	if _is_blocked:
		_blocked_timer -= delta
		if _blocked_timer <= 0.0:
			_is_blocked = false
		return

	velocity = move_direction.normalized() * move_speed * _direction_sign
	var collision := move_and_collide(velocity * delta)

	if collision:
		var collider := collision.get_collider()
		if collider and collider.is_in_group("player"):
			player_hit.emit(self)
		elif collider and collider.is_in_group("rock_pillar"):
			_block_temporarily(5.0)
			return
		else:
			_direction_sign *= -1.0

	_traveled += move_speed * delta
	if _traveled >= travel_distance:
		_traveled = 0.0
		_direction_sign *= -1.0

func _block_temporarily(duration: float) -> void:
	_is_blocked = true
	_blocked_timer = duration
	velocity = Vector2.ZERO
