extends Area2D

@export var lifetime: float = 10.0
@export var windup_time: float = 0.0

var damage: int = 1
var source_element: String = "earth"
var owner_mage: Node = null
var launch_direction: Vector2 = Vector2.RIGHT
@export var base_speed: float = 300.0

var _velocity: Vector2 = Vector2.ZERO
var _is_reflected: bool = false
var _reflected_element: String = ""
var _telegraphing: bool = true

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("enemy_projectile")
	collision_layer = 1
	# Detect player hurtbox and earth reflector bodies.
	collision_mask = 13

	_velocity = launch_direction.normalized() * base_speed
	set_telegraph(true)

	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func set_telegraph(enabled: bool) -> void:
	_telegraphing = enabled
	if _sprite != null:
		_sprite.modulate = Color(1.0, 0.83, 0.62, 0.75) if enabled else Color(1, 1, 1, 1)

func aim_at(target_position: Vector2) -> void:
	if _is_reflected:
		return
	var aim_dir := target_position - global_position
	if aim_dir.length_squared() <= 0.0001:
		return
	launch_direction = aim_dir.normalized()
	_velocity = launch_direction * base_speed

func shoot() -> void:
	set_telegraph(false)

func _physics_process(delta: float) -> void:
	if windup_time > 0.0 and not _is_reflected:
		windup_time = max(0.0, windup_time - delta)
		return
	if _telegraphing and not _is_reflected:
		return

	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	global_position += _velocity * delta

	if _is_reflected and owner_mage != null and is_instance_valid(owner_mage):
		var hit_radius := 14.0
		if _collision != null and _collision.shape is CircleShape2D:
			hit_radius = (_collision.shape as CircleShape2D).radius + 12.0
		if global_position.distance_to(owner_mage.global_position) <= hit_radius:
			if owner_mage.has_method("receive_reflected_hit"):
				owner_mage.call("receive_reflected_hit", 1, _reflected_element)
			queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area == null:
		return
	if area.is_in_group("player_hurtbox") and not _is_reflected:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body == null:
		return
	if _is_reflected:
		return
	if not body.is_in_group("earth_reflector"):
		return

	# Earth mage projectiles are only reflectable by earth power.
	if source_element != "earth":
		return

	_reflect_to_owner("earth")

func _reflect_to_owner(element: String) -> void:
	_is_reflected = true
	_reflected_element = element
	_telegraphing = false
	remove_from_group("enemy_projectile")

	if _sprite != null:
		_sprite.modulate = Color(0.75, 0.6, 0.4, 1.0)

	if owner_mage != null and is_instance_valid(owner_mage):
		_velocity = (owner_mage.global_position - global_position).normalized() * base_speed * 1.25
	else:
		_velocity = -_velocity * 1.2
